module: heap
rcs-header: $Header: /home/housel/work/rcs/gd/src/d2c/compiler/cback/heap.dylan,v 1.38 1996/02/16 03:49:30 wlott Exp $
copyright: Copyright (c) 1995, 1996  Carnegie Mellon University
	   All rights reserved.

// Heap Building.
//
// The file is responsible for building the initial heap and the roots
// vectors.  There are two entry points into the heap builder: one for building
// a library specific local heap, and one for building the final global heap.
// We dump as much stuff as possible in local heaps to keep the global heap
// small.  We want to keep the global heap small because the larger the global
// heap, the longer every final program will take to compile.  By moving as
// much of the effort into local heap production that we can, we only pay
// the cost for dumping the stuff when we recompile that particular library.
//
// But some objects must be dumped in the global heap.  Such objects fall
// into two categories: symbols and objects whos initial definitions depend
// on global information about the program (e.g. open classes and generic
// functions).
//
// Symbols must be dumped in the global heap because multiple different
// libraries can all independently introduce the same symbol and we have to
// make sure we only allocate a single heap object for that symbol.  If each
// library dumped their own copy of said symbol, then we couldn't implement
// == on symbols as a simple pointer comparison.
//
// Open classes must be dumped in the global heap because all classes
// contain an enumeration of their (compile-time installed) direct subclasses.
// If the class is open, then other libraries can add additional subclasses.
// If we dumped the class in a local heap, we would have no way of including
// these new subclasses in the direct-subclasses list.
//
// A related issue is slot descriptors for open classes.  Slot descriptors
// contain a ``position table'' mapping (sub)class to slot position.  But slot
// descriptors for primary classes can be eagerly dumped because the position
// table for them won't change with the addition of new subclasses.
//
// Just like there can only be one copy each symbol, there can only be one
// copy of #t, #f, #(), and $not-supplied.  But it turns out that we don't
// actually have to do anything to guarantee that.  They are all referenced
// by the Dylan library, so they will all be dumped in the Dylan library's
// local heap.  And any other library must use the Dylan library, and will
// therefore pick up the labels used for them when the Dylan library's local
// heap was built.



// <state> -- internal.
// 
// A catch-all object to quantify the state of the "heap output" process.
// Almost every routine in this module accepts a "state" argument and
// destructively modifies it as necessary to account for its actions.
//
define abstract class <state> (<object>)
  //
  // The stream we are spewing to.
  slot stream :: <stream>, required-init-keyword: stream:;
  //
  // The prefix we are pre-pending to each symbol to guarantee uniqueness.
  slot id-prefix :: <byte-string>, init-keyword: #"id-prefix", init-value: "L";
  //
  // The id counter used to generate unique names.
  slot next-id :: <integer>, init-value: 0;
  //
  // A queue of objects that we have decided to dump but haven't gotten
  // around to dumping yet.
  slot object-queue :: <deque>, init-function: curry(make, <deque>);
  //
  // Objects that are dumped (or are to be dumped) in other heaps but
  // referenced in this one must be imported.  This table keeps track of those
  // objects we have already imported so that we don't import them multiple
  // times.
  slot object-referenced-table :: <object-table>,
    init-function: curry(make, <object-table>);
end;

// heap-object-referenced? and -setter -- internal.
//
// A more convenient interface to the state's object-referenced-table.
//
define method heap-object-referenced? (object :: <ct-value>, state :: <state>)
    => referenced? :: <boolean>;
  element(state.object-referenced-table, object, default: #f);
end method heap-object-referenced?;
//
define method heap-object-referenced?-setter
    (value :: <boolean>, object :: <ct-value>, state :: <state>)
    => value :: <boolean>;
  element(state.object-referenced-table, object) := value;
end method heap-object-referenced?-setter;

// <global-state> -- internal.
//
// The additional information needed while dumping the final global heap.
// 
define class <global-state> (<state>)
  //
  // When dumping symbols, we chain them together.  This holds the current
  // head of that chain.
  slot symbols :: type-union(<literal-false>, <literal-symbol>),
    init-function: curry(make, <literal-false>);
end class <global-state>;

// <local-state> -- internal.
//
// The additional information needed while dumping a library local heap.
// 
define class <local-state> (<state>)
  //
  // Holds the objects that have been referenced but are not going to be
  // dumped until the global heap is dumped.
  slot undumped-objects :: <stretchy-vector>,
    init-function: curry(make, <stretchy-vector>);
  //
  // Holds the extra labels we've had to allocate for externally defined
  // ctvs.
  slot extra-labels :: <stretchy-vector>,
    init-function: curry(make, <stretchy-vector>);
end class <local-state>;

// <extra-label> -- internal.
//
// Sometimes we will need to reference some ctv defined (w/ load-external: #t)
// in some other library.  We can't just pick a name and add it to the
// <constant-info> for that ctv because when we go to dump the ctv again
// we will just end up dumping a reference to the original external definition.
// Therefore, we instead use an <extra-label> object to record that we need
// an extra label added to that ctv and then dump the <extra-label>.
//
define class <extra-label> (<object>)
  //
  // The ctv this extra label is for.
  slot extra-label-ctv :: <ct-value>, required-init-keyword: ctv:;
  //
  // The extra label itself.
  slot extra-label-label :: <byte-string>, required-init-keyword: label:;
end class <extra-label>;

add-make-dumper
  (#"extra-label", *compiler-dispatcher*, <extra-label>,
   list(extra-label-ctv, ctv:, #f,
	extra-label-label, label:, #f),
   load-side-effect:
     method (extra-label :: <extra-label>) => ();
       let ctv = extra-label.extra-label-ctv;
       let label = extra-label.extra-label-label;
       let info = get-info-for(extra-label.extra-label-ctv, #f);
       unless (member?(label, info.const-info-heap-labels, test: \=))
	 info.const-info-heap-labels
	   := add(info.const-info-heap-labels, label);
       end unless;
     end method);


// The top level heap building entry points.

// build-global-heap -- exported.
// 
// Builds the global heap image.  Called after all the libraries have been
// compiled or loaded.  Dumps all the objects that were defered during the
// dumping of the library specific local heaps.
// 
define method build-global-heap
    (undumped-objects :: <simple-object-vector>, stream :: <stream>)
    => ();
  let state = make(<global-state>, stream: stream);
  format(stream, "\t.data\n\t.align\t8\n");

  for (obj in undumped-objects)
    object-name(obj, state);
  end for;

  spew-objects-in-queue(state);

  format(stream,
	 "\n\n\t.align\t8\n\t.export\tinitial_symbols, DATA\n"
	   "initial_symbols\n");
  spew-reference(state.symbols, *heap-rep*, "Initial Symbols", state);
end;

// build-local-heap -- exported.
//
// Build a library specific local heap and return the set of objects skipped
// and the additional labels this heap depends on.  Starts by building the
// roots vector, and then dumps all the objects refered to by any roots.
// Except, of course, any of the objects that have to wait for the global heap
// for some reason or other.
// 
define method build-local-heap
    (unit :: <unit-state>, stream :: <stream>)
 => (undumped :: <simple-object-vector>,
     extra-labels :: <simple-object-vector>);
  let prefix = unit.unit-prefix;
  let state = make(<local-state>, stream: stream, 
		   id-prefix: concatenate(prefix, "_L"));
  format(stream, "\t.data\n\t.align\t8\n");

  format(stream, "\n\t.export\t%s_roots, DATA\n%s_roots\n", prefix, prefix);
  for (root in unit.unit-init-roots, index from 0)
    let name = root.root-name;
    if (root.root-comment)
      format(stream, "\n; %s\n", root.root-comment);
    else
      write('\n', stream);
    end if;
    if (name)
      format(stream, "\t.export\t%s, DATA\n%s\n", name, name);
    end if;
    spew-reference(root.root-init-value, *general-rep*,
		   stringify(prefix, "_roots[", index, ']'),
		   state);
  end;

  for (obj in unit.unit-eagerly-reference)
    object-name(obj, state);
  end for;

  spew-objects-in-queue(state);

  values(as(<simple-object-vector>, state.undumped-objects),
	 as(<simple-object-vector>, state.extra-labels));
end method build-local-heap;

// spew-objects-in-queue -- internal.
//
// Keep spewing objects until we finally drain the spew queue.
// 
define method spew-objects-in-queue (state :: <state>) => ();
  let stream = state.stream;
  until (state.object-queue.empty?)
    let object = pop(state.object-queue);
    let info = get-info-for(object, #f);

    format(stream, "\n; %s\n\t.align\t8\n", object);
    let labels = info.const-info-heap-labels;
    if (labels.empty?)
      error("Trying to spew %=, but it doesn't have any labels.", object);
    end if;
    for (label in labels)
      format(stream, "\t.export\t%s, DATA\n%s\n", label, label);
    end for;

    spew-object(object, state);
  end;
end method spew-objects-in-queue;

//------------------------------------------------------------------------
//  Spew-reference
//
// This function creates a reference to some object.  In the case of literals,
// the "reference" may be the object's value, but it will usually simply be a
// symbolic name for the object.  As a side effect, this routine will add the
// object to the "to be dumped" queue (via object-name) if it has not already
// been scheduled for dumping. 
//
// The "tag" is a string which typically describes the particular slot being
// defined.  See "../base/rep.dylan" and "../base/c-rep.dylan" for hints
// concerning the meaning of "rep".
//------------------------------------------------------------------------

define generic spew-reference
    (object :: false-or(<ct-value>), rep :: <representation>,
     tag :: <byte-string>, state :: <state>)
    => ();

// spew-reference{<false>,<representation>}
//
// #f takes the place of a ctv when we want to reserve space for an
// uninitialized value.
// 
define method spew-reference
    (object :: <false>, rep :: <representation>,
     tag :: <byte-string>, state :: <state>)
    => ();
  format(state.stream, "\t.blockz\t%d\t; %s\n", rep.representation-size, tag);
end;

// spew-reference{<literal>,<immediate-representation>}
//
// Representing a literal as an immediate is easy.  We just compute the bits
// (using raw-bits) and then tell the assembler how big of a field to reserve.
//
define method spew-reference
    (object :: <literal>, rep :: <immediate-representation>,
     tag :: <byte-string>, state :: <state>)
    => ();
  let bits = raw-bits(object);
  select (rep.representation-size)
    1 => format(state.stream, "\t.byte\t%d\t; %s\n", bits, tag);
    2 => format(state.stream, "\t.half\t%d\t; %s\n", bits, tag);
    4 => format(state.stream, "\t.word\t%d\t; %s\n", bits, tag);
    8 =>
      format(state.stream, "\t.word\t%d, %d\t; %s\n",
	     ash(bits, -32),
	     logand(bits, ash(as(<extended-integer>, 1), 32) - 1),
	     tag)
  end;
end;

// spew-reference{<ct-value>,<general-representation>}
//
// Dump the full dual-word representation of the object.
// 
define method spew-reference
    (object :: <ct-value>, rep :: <general-representation>,
     tag :: <byte-string>, state :: <state>)
    => ();
  let cclass = object.ct-value-cclass;
  let best-rep = pick-representation(cclass, #"speed");
  let (heapptr, dataword)
    = if (instance?(best-rep, <data-word-representation>))
	values(make(<proxy>, for: cclass), raw-bits(object));
      else
	values(object, 0);
      end;
  format(state.stream, "\t.word\t%s, %d\t; %s\n",
	 object-name(heapptr, state),
	 dataword, tag);
end;

// spew-reference{<proxy>,<general-representation>}
//
// Reference the heap proxy object.  This method is needed because cback will
// put proxy objects in the roots vector in order to reference them.
//
define method spew-reference
    (object :: <proxy>, rep :: <general-representation>,
     tag :: <byte-string>, state :: <state>)
    => ();
  format(state.stream, "\t.word\t%s, 0\t; %s\n",
	 object-name(object, state), tag);
end;

// spew-reference{<ct-value>,<heap-representation>}
//
// Dump a heap pointer to the object.
// 
define method spew-reference
    (object :: <ct-value>, rep :: <heap-representation>,
     tag :: <byte-string>, state :: <state>) => ();
  format(state.stream, "\t.word\t%s\t; %s\n", object-name(object, state), tag);
end;

// spew-reference{<ct-entry-point>,<immediate-representation>}
//
// When reference entry points, we are really referencing the C function
// that encodes the entry.  So instead of using raw-bits (as in the
// general <immediate-representation> method above) we just emit the name
// of the C function.
// 
define method spew-reference
    (object :: <ct-entry-point>, rep :: <immediate-representation>,
     tag :: <byte-string>, state :: <state>)
    => ();
  format(state.stream, "\t.word\t%s\t; %s\n", entry-name(object, state), tag);
end;

// spew-reference{<ct-entry-point>,<general-representation>}
//
// Likewise for general rep references.
// 
define method spew-reference
    (object :: <ct-entry-point>, rep :: <general-representation>,
     tag :: <byte-string>, state :: <state>)
    => ();
  format(state.stream, "\t.word\t%s, %s\t; %s\n",
	 object-name(make(<proxy>, for: object.ct-value-cclass), state),
	 entry-name(object, state),
	 tag);
end;

// object-name -- internal.
// 
// Object-name returns a name for an object -- generating it if necessary.  As
// a side effect, it also checks whether the object has been dumped and queues
// it if not.
//
define method object-name (object :: <ct-value>, state :: <state>)
    => name :: <string>;
  let info = get-info-for(object, #f);
  unless (info.const-info-dumped?)
    //
    // The object hasn't been dumped.  So check to see if we should dump it
    // now or not.
    if (defer-for-global-heap?(object, state))
      //
      // Nope, we need to wait for the global heap.  So remember that this
      // object wasn't dumped.
      add-new!(state.undumped-objects, object);
    else
      //
      // Dump-o-rama.  Mark it as dumped, queue it, and flag it as referenced
      // so we don't try to import the name.
      info.const-info-dumped? := #t;
      push-last(state.object-queue, object);
      heap-object-referenced?(object, state) := #t;
    end if;
    //
    // Make sure the object has at least one label.
    if (info.const-info-heap-labels.empty?)
      //
      // Make (and record) a new label.
      let label = stringify(state.id-prefix, state.next-id);
      state.next-id := state.next-id + 1;
      info.const-info-heap-labels := vector(label);
      //
      // If the object is defined externally and we are building a local heap,
      // then we need to record that we want the object to have an extra label.
      if (instance?(state, <local-state>) & object.defined-externally?)
	add!(state.extra-labels,
	     make(<extra-label>, ctv: object, label: label));
      end if;
    end if;
  end unless;
  let name = info.const-info-heap-labels.first;
  unless (heap-object-referenced?(object, state))
    format(state.stream, "\t.import\t%s, data\n", name);
    heap-object-referenced?(object, state) := #t;
  end unless;
  name;
end method object-name;


// entry-name -- internal.
//
// Return the name of the function that corresponds to this entry point.
// The function must have been defined someplace in the C code, because
// there isn't shit we can do about it now.
// 
define method entry-name (object :: <ct-entry-point>, state :: <state>)
    => name :: <string>;
  let name = object.entry-point-c-name;
  unless (heap-object-referenced?(object, state))
    format(state.stream, "\t.import\t%s, code\n", name);
    heap-object-referenced?(object, state) := #t;
  end unless;
  name;
end;
	


//------------------------------------------------------------------------
// Raw-bits
//
// This function converts a "compile-time value" into an integer which should
// be a meaningful value within the low-level C code.  This is an extended
// integer which require several words to store.
//------------------------------------------------------------------------

define generic raw-bits (ctv :: <literal>) => res :: <general-integer>;

define method raw-bits (ctv :: <literal-true>) => res :: <general-integer>;
  1;
end;

define method raw-bits (ctv :: <literal-false>) => res :: <general-integer>;
  0;
end;

define method raw-bits (ctv :: <literal-integer>)
    => res :: <general-integer>;
  ctv.literal-value;
end;

define method raw-bits (ctv :: <literal-single-float>)
    => res :: <general-integer>;
  raw-bits-for-float(ctv, 24, 127, 8);
end;

define method raw-bits (ctv :: <literal-double-float>)
    => res :: <general-integer>;
  raw-bits-for-float(ctv, 53, 1023, 11);
end;

define method raw-bits (ctv :: <literal-extended-float>)
    => res :: <general-integer>;
  // ### gcc doesn't use extended floats for long doubles.
  // raw-bits-for-float(ctv.literal-value, 113, 16383, 15);
  raw-bits-for-float(ctv, 53, 1023, 11);
end;

define method raw-bits (ctv :: <literal-character>)
    => res :: <general-integer>;
  as(<integer>, ctv.literal-value);
end;

define method raw-bits-for-float
    (ctv :: <literal-float>, precision :: <integer>,
     bias :: <integer>, exponent-bits :: <integer>)
    => res :: <general-integer>;
  let num = as(<ratio>, ctv.literal-value);
  if (zero?(num))
    0;
  else
    let (num, neg?)
      = if (negative?(num))
	  values(-num, #t);
	else
	  values(num, #f);
	end;
    let (exponent, fraction)
      = if (num >= 1)
	  for (exponent from 1,
	       fraction = num / 2 then fraction / 2,
	       while: fraction >= 1)
	  finally
	    values(exponent, fraction);
	  end;
	else
	  for (exponent from 0 by -1,
	       fraction = num then fraction * 2,
	       while: fraction < ratio(1,2))
	  finally
	    values(exponent, fraction);
	  end;
	end;
    let biased-exponent = exponent + bias;
    if (biased-exponent >= ash(1, exponent-bits))
      // Overflow.
      error("%s is too big.", ctv);
    end;
    if (biased-exponent <= 0)
      if (-biased-exponent >= precision - 1)
	// Underflow.
	error("%s is too small.", ctv);
      end;
      fraction := fraction / ash(1, -biased-exponent);
      biased-exponent := 0;
    end;
    let shifted-fraction
      = round/(ash(numerator(fraction), precision),
	       denominator(fraction));
    let bits = logior(ash(as(<extended-integer>, biased-exponent),
			  precision - 1),
		      logand(shifted-fraction,
			     ash(as(<extended-integer>, 1), precision - 1)
			       - 1));
    if (neg?)
      logior(bits,
	     ash(as(<extended-integer>, 1),
		 precision + exponent-bits - 1));
    else
      bits;
    end;
  end;
end;



// defer-for-global-heap? -- internal.
//
// Decide if we should be defering the dump of this object, and queue it
// for defered dumping if so.
// 
define generic defer-for-global-heap? (object :: <ct-value>, state :: <state>)
    => defer? :: <boolean>;

// By default, we dump everything now.
// 
define method defer-for-global-heap?
    (object :: <ct-value>, state :: <state>)
    => defer? :: <boolean>;
  #f;
end method defer-for-global-heap?;

// Symbols, on the other hand, must always be defered so we can correctly
// chain them together and guarantee uniqueness.
// 
define method defer-for-global-heap?
    (object :: <literal-symbol>, state :: <local-state>)
    => defer? :: <boolean>;
  #t;
end method defer-for-global-heap?;


// Open generic functions must be defered, because they need to be populated
// with any methods defined elsewhere.
// 
define method defer-for-global-heap?
    (object :: <ct-open-generic>, state :: <local-state>)
    => defer? :: <boolean>;
  #t;
end method defer-for-global-heap?;

// Sealed generics only have to be defered if we arn't dumping them where
// defined.
//
define method defer-for-global-heap?
    (object :: <ct-sealed-generic>, state :: <local-state>)
    => defer? :: <boolean>;
  object.defined-externally?;
end method defer-for-global-heap?;

// Open classes must be defered because they must be populated with any
// subclasses defined elsewhere.  Likewise, classes that were not dumped
// when originally defined must be defered because we *must* not ever dump
// more than one copy.
// 
define method defer-for-global-heap?
    (object :: <cclass>, state :: <local-state>)
    => defer? :: <boolean>;
  ~object.sealed? | object.defined-externally?;
end method defer-for-global-heap?;

// Likewise, slot infos for open classes must be defered because their
// position table must be populated with entries for any subclasses that
// are defined elsewhere.  Except that slots introduced by primary open classes
// can be dumped now, because the position table can't be changed by
// subclasses.
// 
define method defer-for-global-heap?
    (object :: <slot-info>, state :: <local-state>)
    => defer? :: <boolean>;
  let class = object.slot-introduced-by;
  ~(class.sealed? | class.primary?) | object.defined-externally?;
end method defer-for-global-heap?;



//------------------------------------------------------------------------
// Spew-object
//
// This function writes out the code for an object's value (as opposed to a
// simple reference to that value).  This serves primarily as a front end to
// "spew-instance" (described below) -- it computes the class of the object
// and a set of field values, all of which will be passed on to spew-instance.
//------------------------------------------------------------------------

define generic spew-object (object :: <ct-value>, state :: <state>) => ();


define method spew-object
    (object :: <ct-not-supplied-marker>, state :: <state>) => ();
  spew-instance(specifier-type(#"<not-supplied-marker>"), state);
end;

define method spew-object
    (object :: <literal-boolean>, state :: <state>) => ();
  spew-instance(object.ct-value-cclass, state);
end;

define method spew-object
    (object :: <literal-extended-integer>, state :: <state>) => ();
  let digits = make(<stretchy-vector>);
  local
    method repeat (remainder :: <extended-integer>);
      let (remainder :: <extended-integer>, digit :: <general-integer>)
	= floor/(remainder, 256);
      add!(digits,
	   make(<literal-integer>,
		value: as(<extended-integer>, digit)));
      unless (if (logbit?(7, digit))
		remainder = -1;
	      else
		remainder = 0;
	      end)
	repeat(remainder);
      end;
    end;
  repeat(object.literal-value);
  spew-instance(specifier-type(#"<extended-integer>"), state,
		bignum-size: as(<ct-value>, digits.size),
		bignum-digit: digits);
end;

define method spew-object (object :: <literal-ratio>, state :: <state>) => ();
  let num = as(<ratio>, object.literal-value);
  spew-instance(object.ct-value-cclass, state,
		numerator:
		  make(<literal-extended-integer>, num.numerator),
		denominator:
		  make(<literal-extended-integer>, num.denominator));
end;

define method spew-object (object :: <literal-float>, state :: <state>) => ();
  spew-instance(object.ct-value-cclass, state, value: object);
end;

define method spew-object
    (object :: <literal-symbol>, state :: <state>) => ();
  spew-instance(specifier-type(#"<symbol>"), state,
		symbol-string:
		  as(<ct-value>, as(<string>, object.literal-value)),
		symbol-next: state.symbols);
  state.symbols := object;
end;

define method spew-object
    (object :: <literal-pair>, state :: <state>) => ();
  spew-instance(specifier-type(#"<pair>"), state,
		head: object.literal-head,
		tail: object.literal-tail);
end;

define method spew-object
    (object :: <literal-empty-list>, state :: <state>) => ();
  spew-instance(specifier-type(#"<empty-list>"), state,
		head: object, tail: object);
end;

define method spew-object
    (object :: <literal-simple-object-vector>, state :: <state>) => ();
  let contents = object.literal-value;
  spew-instance(specifier-type(#"<simple-object-vector>"), state,
		size: as(<ct-value>, contents.size),
		%element: contents);
end;

define constant $spewed-string-buffer = as(<stretchy-vector>, "\t.string\t\"");
define constant $spewed-string-initial-size :: <integer>
  = $spewed-string-buffer.size;

define method spew-object
    (object :: <literal-string>, state :: <state>) => ();
  let str = object.literal-value;
  let class = specifier-type(#"<byte-string>");
  let fields = get-class-fields(class);
  for (field in fields)
    select (field by instance?)
      <false> => #f;
      <integer> =>
	format(state.stream, "\t.blockz\t%d\n", field);
      <instance-slot-info> =>
	select (field.slot-getter.variable-name)
	  #"%object-class" =>
	    spew-reference(class, field.slot-representation, "%object-class",
			   state);
	  #"size" =>
	    spew-reference(as(<ct-value>, str.size), field.slot-representation,
			   "size", state);
	  #"%element" =>
	    let stream = state.stream;
	    // The following ugly code should be immensely faster than
	    // writing a character at a time to a stream.
	    for (i from 0 below str.size)
	      let char = str[i];
	      select (char)
		'\\' =>
		  add!($spewed-string-buffer, '\\');
		  add!($spewed-string-buffer, '\\');
		'"' =>
		  add!($spewed-string-buffer, '\\');
		  add!($spewed-string-buffer, '"');
		'\0' =>
		  add!($spewed-string-buffer, '\\');
		  add!($spewed-string-buffer, '0');
		'\n' =>
		  add!($spewed-string-buffer, '\\');
		  add!($spewed-string-buffer, 'n');
		'\t' =>
		  add!($spewed-string-buffer, '\\');
		  add!($spewed-string-buffer, 't');
		'\b' =>
		  add!($spewed-string-buffer, '\\');
		  add!($spewed-string-buffer, 'b');
		'\r' =>
		  add!($spewed-string-buffer, '\\');
		  add!($spewed-string-buffer, 'r');
		'\f' =>
		  add!($spewed-string-buffer, '\\');
		  add!($spewed-string-buffer, 'f');
		otherwise =>
		  if (char >= ' ' & char <= '~')
		    add!($spewed-string-buffer, char);
		  else
		    let code = as(<integer>, char);
		    let substr = format-to-string("\\x%x%x", ash(code, -16),
						  logand(code, 15));
		    map(method (c) add!($spewed-string-buffer, c) end, substr);
		  end if;
	      end select;
	    end for;
	    add!($spewed-string-buffer, '"');
	    add!($spewed-string-buffer, '\n');
	    write(as(<byte-string>, $spewed-string-buffer), stream);
	    $spewed-string-buffer.size := $spewed-string-initial-size;
	end select;
    end select;
  end for;
end method spew-object;

define method spew-object
    (object :: <union-ctype>, state :: <state>) => ();
  let mems = #();
  let sings = #();
  for (member in object.members)
    if (instance?(member, <singleton-ctype>))
      sings := pair(member.singleton-value, sings);
    else
      mems := pair(member, mems);
    end;
  end;
  spew-instance(specifier-type(#"<union>"), state,
		union-members: make(<literal-list>,
				    contents: mems,
				    sharable: #t),
		union-singletons: make(<literal-list>,
				       contents: sings,
				       sharable: #t));
end;

define method spew-object
    (object :: <limited-integer-ctype>, state :: <state>) => ();
  local method make-lit (x :: false-or(<general-integer>))
	  if (x == #f)
	    as(<ct-value>, x);
	  elseif (x < runtime-$minimum-integer
		    | x > runtime-$maximum-integer)
	    make(<literal-extended-integer>, value: x);
	  else
	    make(<literal-integer>, value: x);
	  end;
	end;
  spew-instance(specifier-type(#"<limited-integer>"), state,
		limited-integer-base-class: object.base-class,
		limited-integer-minimum: make-lit(object.low-bound),
		limited-integer-maximum: make-lit(object.high-bound));
end;

define method spew-object
    (object :: <singleton-ctype>, state :: <state>) => ();
  spew-instance(specifier-type(#"<singleton>"), state,
		singleton-object: object.singleton-value);
end;

define method spew-object
    (object :: <byte-character-ctype>, state :: <state>) => ();
  spew-instance(specifier-type(#"<byte-character-type>"), state);
end;

define method spew-object
    (object :: <defined-cclass>, state :: <state>) => ();
  let defn = object.class-defn;
  spew-instance(specifier-type(#"<class>"), state,
		class-name:
		  make(<literal-string>,
		       value: as(<byte-string>,
				 object.cclass-name.name-symbol)),
		unique-id:
		  as(<ct-value>, object.unique-id | -1),
		direct-superclasses:
		  make(<literal-simple-object-vector>,
		       contents: object.direct-superclasses,
		       sharable: #t),
		all-superclasses:
		  make(<literal-simple-object-vector>,
		       contents: object.precedence-list,
		       sharable: #t),
		closest-primary-superclass: object.closest-primary-superclass,
		direct-subclasses:
		  make(<literal-list>, contents: object.direct-subclasses),
		class-functional?: as(<ct-value>, object.functional?),
		class-primary?: as(<ct-value>, object.primary?),
		class-abstract?: as(<ct-value>, object.abstract?),
		class-sealed?: as(<ct-value>, object.sealed?),
		class-defered-evaluations:
		  defn.class-defn-defered-evaluations-function
		  | as(<ct-value>, #f),
		class-maker: defn.class-defn-maker-function
		  | as(<ct-value>, #f),
		class-new-slot-descriptors:
		  make(<literal-simple-object-vector>,
		       contents: object.new-slot-infos,
		       sharable: #t),
		class-all-slot-descriptors:
		  make(<literal-simple-object-vector>,
		       contents: object.all-slot-infos,
		       sharable: #t));
end;

define method spew-object
    (object :: <slot-info>, state :: <state>) => ();
  spew-instance(specifier-type(#"<slot-descriptor>"), state,
		slot-allocation:
		  as(<ct-value>,
		     select (object by instance?)
		       <instance-slot-info> => #"instance";
		       <class-slot-info> => #"class";
		       <each-subclass-slot-info> => #"each-subclass";
		       <virtual-slot-info> => #"virtual";
		     end),
		slot-type:
		  unless (instance?(object.slot-type, <unknown-ctype>))
		    object.slot-type;
		  end,
		slot-init-function:
		  if (instance?(object.slot-init-function, <ct-value>))
		    object.slot-init-function;
		  end,
		slot-init-value:
		  if (instance?(object.slot-init-value, <ct-value>))
		    object.slot-init-value;
		  end,
		slot-init-keyword:
		  as(<ct-value>, object.slot-init-keyword),
		slot-init-keyword-required?:
		  as(<ct-value>, object.slot-init-keyword-required?),
		slot-positions:
		  if (instance?(object, <instance-slot-info>))
		    as(<ct-value>, object.slot-positions);
		  end if);
end method spew-object;

define method spew-object (object :: <proxy>, state :: <state>) => ();
  spew-reference(object.proxy-for, *heap-rep*, "%object-class", state);
end;

define method spew-object (object :: <ct-function>, state :: <state>) => ();
  spew-function(object, state,
		general-entry:
		  make(<ct-entry-point>, for: object, kind: #"general"));
end;

define method spew-object
    (object :: <ct-generic-function>, state :: <state>) => ();
  let defn = object.ct-function-definition;
  spew-function(object, state,
		general-entry:
		  begin
		    let discriminator = defn.generic-defn-discriminator;
		    if (discriminator)
		      make(<ct-entry-point>, for: discriminator,
			   kind: #"general");
		    else
		      let dispatch = dylan-defn(#"gf-call");
		      if (dispatch)
			make(<ct-entry-point>,
			     for: dispatch.ct-value,
			     kind: #"main");
		      else
			#f;
		      end;
		    end;
		  end,
		generic-function-methods:
		  make(<literal-list>,
		       contents:
			 remove(map(ct-value, generic-defn-methods(defn)),
				#f), 
		       sharable: #f));
end;

// method-general-entry -- internal.
//
// Utility routine to find the <ct-entry-point> to use for the given method's
// general entry.  Basically, if the method is hidden (i.e. inside a generic)
// we use the main entry for general-call if general-call is defined and we
// leave the entry uninitialized if general-call is not.  If the method
// is not hidden, then it will have a custom built general entry, so we use
// that.
// 
define method method-general-entry (meth :: <ct-method>)
    => entry :: false-or(<ct-entry-point>);
  if (meth.ct-method-hidden?)
    let tramp = dylan-defn(#"general-call");
    if (tramp)
      make(<ct-entry-point>, for: tramp.ct-value, kind: #"main");
    else
      #f;
    end;
  else
    make(<ct-entry-point>, for: meth, kind: #"general");
  end if;
end method method-general-entry;

define method spew-object (object :: <ct-method>, state :: <state>) => ();
  spew-function(object, state,
		general-entry: method-general-entry(object),
		generic-entry:
		  make(<ct-entry-point>, for: object, kind: #"generic"));
end;

define method spew-object (object :: <ct-accessor-method>, state :: <state>)
    => ();
  let standin = object.ct-accessor-standin;
  spew-function(object, state,
		general-entry: method-general-entry(object),
		generic-entry:
		  if (standin)
		    make(<ct-entry-point>, for: standin, kind: #"main");
		  else
		    make(<ct-entry-point>, for: object, kind: #"generic");
		  end,
		accessor-slot: object.ct-accessor-method-slot-info);
end;

// Spew-function is a slightly lower-level front-end to "spew-instance".  It
// automatically fills in the various slots which are common to all function
// objects. 
//
define method spew-function
    (func :: <ct-function>, state :: <state>, #rest slots) => ();
  let sig = func.ct-function-signature;
  let returns = sig.returns;
  let positionals = returns.positional-types;
  let min-values = returns.min-values;
  apply(spew-instance, func.ct-value-cclass, state,
	function-name:
	  make(<literal-string>, value: func.ct-function-name),
	function-specializers:
	  make(<literal-simple-object-vector>,
	       contents: sig.specializers,
	       sharable: #t),
	function-rest?: as(<ct-value>, sig.rest-type & #t),
	function-keywords:
	  if (sig.key-infos)
	    make(<literal-simple-object-vector>,
		 contents: map(compose(curry(as, <ct-value>), key-name),
			       sig.key-infos),
		 sharable: #t);
	  else
	    as(<ct-value>, #f);
	  end,
	function-all-keys?: as(<ct-value>, sig.all-keys?),
	function-values:
	  make(<literal-simple-object-vector>,
	       contents: copy-sequence(positionals, end: min-values),
	       sharable: #t),
	function-rest-value:
	  reduce(ctype-union, returns.rest-value-type,
		 copy-sequence(positionals, start: min-values)),
	slots);
end;



// Spew-instance is the workhorse function which actually writes out the value
// for an object.  Given a class and a sequence of slot values, it spews
// assembly code which creates a new object instance and provides values for
// each slot.  Slot values may be specified explicitly as a keyword/value in
// "slots".  Any slot which is not explicitly specified will be filled in with
// a default value.
//
define method spew-instance
    (class :: <cclass>, state :: <state>, #rest slots) => ();
  for (field in get-class-fields(class))
    select (field by instance?)
      <false> => #f;
      <integer> =>
	format(state.stream, "\t.blockz\t%d\n", field);
      <instance-slot-info> =>
	let init-value = find-init-value(class, field, slots);
	let getter = field.slot-getter;
	let name = if (getter)
		     as(<string>, getter.variable-name);
		   else
		     "???";
		   end;
	if (instance?(field, <vector-slot-info>))
	  let len-ctv = find-init-value(class, field.slot-size-slot, slots);
	  unless (len-ctv)
	    compiler-warning("Length of a variable length instance"
			       " unspecified?");
	    len-ctv := as(<ct-value>, 0);
	  end;
	  unless (instance?(len-ctv, <literal-integer>))
	    error("Bogus length: %=", len-ctv);
	  end;
	  let len = as(<integer>, len-ctv.literal-value);
	  if (instance?(init-value, <sequence>))
	    unless (init-value.size == len)
	      error("Size mismatch.");
	    end;
	    for (element in init-value,
		 index from 0)
	      spew-reference(element, field.slot-representation,
			     stringify(name, '[', index, ']'),
			     state);
	    end;
	  else
	    for (index from 0 below len)
	      spew-reference(init-value, field.slot-representation,
			     stringify(name, '[', index, ']'),
			     state);
	    end;
	  end;
	else
	  spew-reference(init-value, field.slot-representation, name, state);
	end;
    end;
  end;
end;

define method get-class-fields (class :: <cclass>)
    => res :: <simple-object-vector>;
  if (class.class-heap-fields)
    class.class-heap-fields;
  else
    if (class.abstract?)
      error("Spewing an abstract class?");
    end;
    let layout = class.instance-slots-layout;
    let fields = make(<vector>, size: layout.layout-length + 1, fill: #f);
    for (slot in class.all-slot-infos)
      if (instance?(slot, <instance-slot-info>))
	block (return)
	  for (entry in slot.slot-positions)
	    if (csubtype?(class, entry.head))
	      fields[entry.tail] := slot;
	      return();
	    end;
	  end;
	  error("Can't find the position for %= in %=?", slot, class);
	end;
      end;
    end;
    for (hole in layout.layout-holes)
      fields[hole.head] := hole.tail;
    end;
    class.class-heap-fields := fields;
  end if;
end method get-class-fields;

// Returns the value which should be used to initialize the heap for an
// instance slot.  This value may be specified in the "slots" key/value
// sequence, or it may be computed based upon the intial-value specification
// for the slot.
//
define method find-init-value
    (class :: <cclass>, slot :: <instance-slot-info>,
     slots :: <simple-object-vector>)
    => res :: type-union(<ct-value>, <sequence>, <false>);
  block (return)
    let object-type = object-ctype();

    // This is very magical.  If the slot was introduced by <object>,
    // it must be %object-class, and its value must be the class.  We
    // should double-check the validity of this assumption, but this
    // is an extremely expensive special case, so the potential
    // savings are large.
    if (slot.slot-introduced-by == object-type)
      return(class);
    end if;

    // Check to see whether the caller provided an explict value for this
    // slot. 
    let getter = slot.slot-getter;
    let slot-name = getter & getter.variable-name;
    if (getter)
      for (index from 0 below slots.size by 2)
	if (slots[index] == slot-name)
	  let val = slots[index + 1];
	  if (val)
	    return(val);
	  end;
	end;
      end;
    end;

    // Find the default value for this slot in this class.  This involves
    // searching the list of "overrides" to determine whether any "inherited
    // slot" specification provided new default values for this slot in this
    // class.  If not, we use the default value supplied in the initial slot
    // defintion.
    for (override in slot.slot-overrides)
      let intro = override.override-introduced-by;
      if (intro == object-type | csubtype?(class, intro))
	if (override.override-init-value == #t
	      | override.override-init-function)
	  compiler-warning("Init value for %s in %= not set up.",
			   slot-name, class);
	  return(#f);
	end;
	return(override.override-init-value);
      end;
    end;

    if (slot.slot-init-value == #t | slot.slot-init-function)
      compiler-warning("Init value for %s in %= not set up.",
		       slot-name, class);
    end;
    slot.slot-init-value;
  end;
end;
