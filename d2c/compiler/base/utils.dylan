module: utils
copyright: see below


//======================================================================
//
// Copyright (c) 1995 - 1997  Carnegie Mellon University
// Copyright (c) 1998 - 2000  Gwydion Dylan Maintainers
// All rights reserved.
// 
// Use and copying of this software and preparation of derivative
// works based on this software are permitted, including commercial
// use, provided that the following conditions are observed:
// 
// 1. This copyright notice must be retained in full on any copies
//    and on appropriate parts of any derivative works.
// 2. Documentation (paper or online) accompanying any system that
//    incorporates this software, or any part of it, must acknowledge
//    the contribution of the Gwydion Project at Carnegie Mellon
//    University, and the Gwydion Dylan Maintainers.
// 
// This software is made available "as is".  Neither the authors nor
// Carnegie Mellon University make any warranty about the software,
// its performance, or its conformity to any specification.
// 
// Bug reports should be sent to <gd-bugs@gwydiondylan.org>; questions,
// comments and suggestions are welcome at <gd-hackers@gwydiondylan.org>.
// Also, see http://www.gwydiondylan.org/ for updates and documentation. 
//
//======================================================================

// Turn on pretty printing.
//
*print-pretty?* := #t;


// Pretty format.

// pretty format
//
// User for error message printing.  Turns each space in the control string
// into a conditional newline, and turns literal newlines into a mandatory
// newline and 2 space indent.
//
define method pretty-format
    (stream :: <stream>, string :: <byte-string>, #rest args)
    => ();
  let length = string.size;
  local
    method scan-for-newline (start, posn, arg-index)
      if (posn == length)
	maybe-logical-block(start, posn, arg-index);
      else
	let char = string[posn];
	if (char == '%')
	  scan-for-newline(start, posn + 2, arg-index);
	elseif (char == '\n')
	  let arg-index = maybe-logical-block(start, posn, arg-index);
	  scan-for-end-of-indent(posn, posn + 1, arg-index);
	else
	  scan-for-newline(start, posn + 1, arg-index);
	end if;
      end if;
    end method scan-for-newline,
    method scan-for-end-of-indent (start, posn, arg-index)
      if (posn == length | string[posn] ~== ' ')
	write(stream, string, start: start, end: posn);
	scan-for-newline(posn, posn, arg-index);
      else
	scan-for-end-of-indent(start, posn + 1, arg-index);
      end if;
    end method scan-for-end-of-indent,
    method maybe-logical-block (start, stop, arg-index)
      if (start == stop)
	arg-index;
      else
	let result = arg-index;
	pprint-logical-block
	  (stream,
	   body: method (stream)
		   result := scan-for-space(stream, start, start, stop,
					    arg-index);
		 end);
	result;
      end if;
    end method maybe-logical-block,
    method scan-for-space (stream, start, posn, stop, arg-index)
      if (posn == stop)
	maybe-spew(stream, start, posn);
	arg-index;
      else
	let char = string[posn];
	if (char == ' ')
	  scan-for-end-of-spaces(#"fill", stream, start, posn + 1, stop,
				 arg-index);
	elseif (char == '%')
	  maybe-spew(stream, start, posn);
	  let directive = string[posn + 1];
	  if (directive == '%')
	    scan-for-space(stream, posn + 1, posn + 2, stop, arg-index);
	  elseif (directive == '\n')
	    maybe-spew(stream, start, posn);
	    scan-for-end-of-spaces(#"mandatory", stream, posn + 2, posn + 2,
				   stop, arg-index);
	  else
	    format(stream, copy-sequence(string, start: posn, end: posn + 2),
		   args[arg-index]);
	    scan-for-space(stream, posn + 2, posn + 2, stop, arg-index + 1);
	  end;
	else
	  scan-for-space(stream, start, posn + 1, stop, arg-index);
	end;
      end;
    end,
    method scan-for-end-of-spaces(kind, stream, start, posn, stop, arg-index)
      if (posn < length & string[posn] == ' ')
	scan-for-end-of-spaces(kind, stream, start, posn + 1, stop, arg-index);
      else
	maybe-spew(stream, start, posn);
	pprint-newline(kind, stream);
	scan-for-space(stream, posn, posn, stop, arg-index);
      end;
    end,
    method maybe-spew (stream, start, stop)
      unless (start == stop)
	write(stream, string, start: start, end: stop);
      end;
    end;
  scan-for-newline(0, 0, 0);
end;

// condition-format{<stream>,<byte-string>} -- method on imported GF.
//
// Shadow the <stream>,<string> method with one that uses pretty-format.
// This is kinda sleezy, but, hey, it works.
// 
define method condition-format
    (stream :: <stream>, control-string :: <byte-string>, #rest args)
    => ();
  apply(pretty-format, stream, control-string, args);
end method condition-format;


// printing utilities.

define method write-class-name (thing, stream) => ();
  let name = thing.object-class.class-name;
  if (name)
    write(stream, as(<string>, name));
  else
    print(thing.object-class, stream);
  end;
end;

define method write-address (thing, stream) => ();
  write(stream, "#x");
  write(stream, integer-to-string(as(<integer>, thing.object-address),
                                  base: 16));
end;

define method pprint-fields (thing, stream, #rest fields) => ();
  pprint-logical-block
    (stream,
     prefix: "{",
     body: method (stream)
	     write-class-name(thing, stream);
	     write-element(stream, ' ');
	     write-address(thing, stream);
	     for (i from 0 below fields.size by 2)
	       if (fields[i])
		 write(stream, ", ");
		 pprint-indent(#"block", 2, stream);
		 pprint-newline(#"linear", stream);
		 write(stream, as(<string>, fields[i]));
		 write(stream, ": ");
		 pprint-indent(#"block", 4, stream);
		 pprint-newline(#"fill", stream);
		 print(fields[i + 1], stream);
	       end;
	     end;
	   end,
     suffix: "}");
end;


define constant $thousand-cardinals
  = #[#f, "thousand", "million", "billion"];
define constant $ten-cardinals
  = #[#f, "ten", "twenty", "thirty", "forty",
      "fifty", "sixty", "seventy", "eighty", "ninety"];
define constant $unit-cardinals
  = #["zero", "one", "two", "three", "four", "five", "six", "seven",
      "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen",
      "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"];

define constant $thousand-ordinals
  = #[#f, "thousandth", "millionth", "billionth"];
define constant $ten-ordinals
  = #[#f, "tenth", "twentieth", "thirtieth", "fortieth",
      "fiftieth", "sixtieth", "seventieth", "eightieth", "ninetieth"];
define constant $unit-ordinals
  = #["zeroth", "first", "second", "third", "fourth", "fifth", "sixth",
      "seventh", "eighth", "ninth", "tenth", "eleventh", "twelfth",
      "thirteenth", "fourteenth", "fifteenth", "sixteenth", "seventeenth",
      "eighteenth", "nineteenth"];

define method integer-to-english
    (int :: <integer>,
     #key as :: one-of(#"cardinal", #"ordinal") = #"cardinal")
    => res :: <byte-string>;
  let pieces = make(<stretchy-vector>);
  let length = 0;
  local
    method add (piece :: <byte-string>) => ();
      add!(pieces, piece);
      length := length + piece.size;
    end method add,
    method ten-powers (int :: <integer>, cardinal? :: <boolean>) => ();
      // Handle 0 <= x < 100.
      if (int < 20)
	add(if (cardinal?) $unit-cardinals else $unit-ordinals end[int]);
      else
	let (tens, units) = truncate/(int, 10);
	if (units.zero?)
	  add(if (cardinal?) $ten-cardinals else $ten-ordinals end[tens]);
	else
	  add($ten-cardinals[tens]);
	  add(if (cardinal?) $unit-cardinals else $unit-ordinals end[units]);
	end if;
      end if;
    end method ten-powers,
    method hundred-powers (int :: <integer>, cardinal? :: <boolean>) => ();
      // Handle 0 <= x < 10000.
      let (hundreds, units) = truncate/(int, 100);
      if (hundreds.zero?)
	ten-powers(units, cardinal?);
      else
	ten-powers(hundreds, #t);
	if (units.zero?)
	  add(if (cardinal?) "hundred" else "hundredth" end);
	else
	  add("hundred");
	  ten-powers(units, cardinal?);
	end if;
      end if;
    end method hundred-powers,
    method thousand-powers
	(int :: <integer>, thousand-index :: <integer>, cardinal? :: <boolean>)
	=> ();
      let (millions, mod-million) = truncate/(int, 1000000);
      let (hundreds, units) = truncate/(mod-million, 100);
      if (hundreds < 100 & ~zero?(remainder(hundreds, 10)))
	//
	// mod-millions is < 10000, so we want to generate something like
	// fifty six hundred instead of five thousand six hundred.  The
	// ~zero? test keeps us from generated fifty hundred over five
	// thousand.  It also guarantees that mod-millions isn't zero, so
	// we don't have to deal with that case.
	unless (millions.zero?)
	  thousand-powers(millions, thousand-index + 2, #t);
	end;
	if (thousand-index.zero?)
	  hundred-powers(mod-million, cardinal?);
	else
	  hundred-powers(mod-million, #t);
	  if (cardinal?)
	    add($thousand-cardinals[thousand-index]);
	  else
	    add($thousand-ordinals[thousand-index]);
	  end;
	end if;
      else
	//
	// either mod-millions is >= 10000 or there is a zero in the hundreds
	// column.
	let (thousands, units) = truncate/(int, 1000);
	if (thousands.zero?)
	  if (thousand-index.zero?)
	    hundred-powers(units, cardinal?);
	  elseif (~units.zero?)
	    hundred-powers(units, #t);
	    if (cardinal?)
	      add($thousand-cardinals[thousand-index]);
	    else
	      add($thousand-ordinals[thousand-index]);
	    end;
	  end if;
	else
	  if (units.zero?)
	    thousand-powers(thousands, thousand-index + 1, cardinal?);
	  else
	    thousand-powers(thousands, thousand-index + 1, #t);
	    if (thousand-index.zero?)
	      hundred-powers(units, cardinal?);
	    else
	      hundred-powers(units, #t);
	      if (cardinal?)
		add($thousand-cardinals[thousand-index]);
	      else
		add($thousand-ordinals[thousand-index]);
	      end;
	    end if;
	  end if;
	end if;
      end if;
    end method thousand-powers;
  if (int < 0)
    add("negative");
    thousand-powers(-int, 0, as == #"cardinal");
  else
    thousand-powers(int, 0, as == #"cardinal");
  end if;
  let result = make(<byte-string>, size: length + pieces.size - 1, fill: ' ');
  for (piece :: <byte-string> in pieces,
       index = 0 then index + piece.size + 1)
    copy-bytes(result, index, piece, 0, piece.size);
  end for;
  result;
end method integer-to-english;

define method ordinal-suffix (int :: <integer>) => res :: <byte-string>;
  let last-two-digits = remainder(int, 100);
  let (penultimate-digit, last-digit) = truncate/(last-two-digits, 10);
  if (penultimate-digit == 1 | last-digit == 0 | last-digit >= 4)
    "th";
  elseif (last-digit == 1)
    "st";
  elseif (last-digit == 2)
    "nd";
  else
    "rd";
  end if;
end method ordinal-suffix;
  

define open generic current-column (stream :: <stream>)
    => res :: false-or(<integer>);

define method current-column (stream :: <stream>)
    => res :: false-or(<integer>);
  #f;
end method current-column;


define method fresh-line (stream :: <stream>) => ();
  let column = stream.current-column;
  unless (column == 0)
    new-line(stream);
  end unless;
end method fresh-line;



// Flush-happy stream

define class <flush-happy-stream> (<wrapper-stream>)
  sealed slot current-column :: <integer>, init-value: 0;
end;

define method write-element
    (stream :: <flush-happy-stream>, elt :: <object>) => ()
  write-element(stream.inner-stream, elt);
  if(elt == '\r' | elt == '\n')
    stream.current-column := 0;
    force-output(stream.inner-stream, synchronize?: #t);
  else
    stream.current-column := stream.current-column + 1;
  end;
end method write-element;

define method write
    (stream :: <flush-happy-stream>, elements :: <sequence>,
     #rest keys, #key start: _start = 0, end: _end = elements.size) => ()
  write(stream.inner-stream, elements, start: _start, end: _end);
  block (return)
    for (i from _end - 1 to _start by -1)
      let elt :: <character> = elements[i];
      if (elt == '\r' | elt == '\n')
        stream.current-column := i - _start;
        force-output(stream.inner-stream, synchronize?: #t);
        return();
      end if;
    end for;
    stream.current-column := stream.current-column + _end - _start;
  end block;
end method write;

define method force-output
    (stream :: <flush-happy-stream>, #key synchronize?) => ()
  force-output(stream.inner-stream, synchronize?: #t);
end method force-output;

define method synchronize-output
    (stream :: <flush-happy-stream>) => ()
  synchronize-output(stream.inner-stream)
end method synchronize-output;

define method write-line
    (stream :: <flush-happy-stream>, string :: <string>,
     #rest keys, #key start: _start, end: _end) => ()
  ignore(_start, _end);
  apply(write-line, stream.inner-stream, string, keys);
  stream.current-column := 0;
  force-output(stream.inner-stream, synchronize?: #t);
end method write-line;

define method new-line (stream :: <flush-happy-stream>) => ()
  new-line(stream.inner-stream);
  stream.current-column := 0;
  force-output(stream.inner-stream, synchronize?: #t);
end method new-line;

define method pprint-logical-block
    (stream :: <flush-happy-stream>,
     #next next-method,
     #key column: ignore :: <integer> = 0,
          prefix :: false-or(<byte-string>),
          per-line-prefix :: false-or(<byte-string>),
          body :: <function>,
          suffix :: false-or(<byte-string>))
    => ();
  next-method(stream, column: current-column(stream), prefix: prefix,
	      per-line-prefix: per-line-prefix, body: body,
	      suffix: suffix);
end;

define variable *error-output* :: <stream>
  = make(<flush-happy-stream>, inner-stream: *standard-error*);

define variable *debug-output* :: <stream>
  = make(<flush-happy-stream>, inner-stream: *standard-output*);


// Debugger hooks

define class <pretty-debugger> (<debugger>)
end class <pretty-debugger>;

define method invoke-debugger
    (debugger :: <pretty-debugger>, condition :: <condition>)
    => res :: <never-returns>;
  fresh-line(*debug-output*);
  format(*debug-output*, "%s\n", condition);
  force-output(*debug-output*);
  call-out("abort", void:);
end;
  
method ()
  *warning-output* := *debug-output*;
  *debugger* := make(<pretty-debugger>);
end method();


// Defines the Info slot used for back-end annotation.
//
define abstract open class <annotatable> (<object>)
  slot info, init-value: #f, init-keyword: info:;
end class;


// foo-IN collection-like functions for threaded lists.


define method find-in
    (next :: <function>, elt, coll, #key key :: <function> = identity,
     test :: false-or(<function>), test-not :: false-or(<function>))
  if (test & test-not)
    error("Both test: and test-not:");
  end;
  block (done)
    if (test-not)
      for (cur = coll then cur.next, while: cur)
        unless (test-not(cur.key, elt)) done(cur) end;
      end for;
    else
      let test = test | \==;
      for (cur = coll then cur.next, while: cur)
        if (test(cur.key, elt)) done(cur) end;
      end for;
    end if;
  end block;
end method;


define method size-in (next :: <function>, coll) => res :: <integer>;
  for (cur = coll then coll.next, len from 0, while: cur)
    finally len;
  end;
end method;


// Simple utility functions.

define method dformat(#rest args) => ();
  fresh-line(*debug-output*);
  apply(pretty-format, *debug-output*, args);
end;


define generic key-of
  (value, collection :: <collection>, #key test :: <function>, default)
 => res :: <object>;

define method key-of
    (value, coll :: <collection>,
     #key test :: <function> = \==, default = #f)
 => res :: <object>;
  find-key(coll,
	   method (x) test(value, x) end,
	   failure: default)
end method;

define method key-of
    (value, coll :: <list>,
     #key  test :: <function> = \==, default = #f)
 => res :: <object>;
  block (done)
    for (els = coll then els.tail,
         pos :: <integer> from 0,
         until: els == #())
      if (test(value, els.head))
        done(pos);
      end;
      finally default;
    end for;
  end;
end method;


define method list?(obj);
  instance?(obj, <list>);
end;

define method pair?(obj);
  instance?(obj, <pair>);
end;


define method symcat (#rest things) => res :: <symbol>;
  as(<symbol>, apply(concatenate, "", map(curry(as, <string>), things)));
end;


define method stringify (#rest things) => res :: <byte-string>;
  let res = for (thing in things,
		 len = 0 then len + string-length(thing))
	    finally
	      make(<byte-string>, size: len);
	    end for;
  for (thing in things,
       offset = 0 then append(res, offset, thing))
  end for;
  res;
end method stringify;

define method string-length (char :: <byte-character>)
    => res :: <integer>;
  1;
end method string-length;

define method string-length (str :: <byte-string>) => res :: <integer>;
  str.size;
end method string-length;

define method string-length (int :: <integer>) => res :: <integer>;
  case
    int < 0 =>
      if (int == $minimum-integer)
	2 + string-length(- truncate/(int, 10));
      else
	1 + string-length(-int);
      end if;
    int < 10 => 1;
    int < 100 => 2;
    int < 1000 => 3;
    int < 10000 => 4;
    otherwise
      for (digits from 5,
	   num = floor/(int, 100000) then floor/(num, 10),
	   until: zero?(num))
      finally
	digits;
      end for;
  end case;
end method string-length;

define method append
    (res :: <byte-string>, offset :: <integer>, what :: <byte-character>)
    => new-offset :: <integer>;
  res[offset] := what;
  offset + 1;
end method append;

define method append
    (res :: <byte-string>, offset :: <integer>, what :: <byte-string>)
    => new-offset :: <integer>;
  let len = what.size;
  copy-bytes(res, offset, what, 0, len);
  offset + len;
end method append;

define method append
    (res :: <byte-string>, offset :: <integer>, what :: <integer>)
    => new-offset :: <integer>;
  if (what < 0)
    res[offset] := '-';
    if (what == $minimum-integer)
      let (rest, low) = truncate/(what, 10);
      let new-offset = append(res, offset + 1, -rest);
      res[new-offset] := as(<character>, low + 48);
      new-offset + 1;
    else
      append(res, offset + 1, -what);
    end if;
  elseif (what < 10)
    res[offset] := as(<character>, what + 48);
    offset + 1;
  elseif (what < 100)
    let (high, low) = floor/(what, 10);
    res[offset] := as(<character>, high + 48);
    res[offset + 1] := as(<character>, low + 48);
    offset + 2;
  elseif (what < 1000)
    let (temp, low) = floor/(what, 10);
    let (high, mid) = floor/(temp, 10);
    res[offset] := as(<character>, high + 48);
    res[offset + 1] := as(<character>, mid + 48);
    res[offset + 2] := as(<character>, low + 48);
    offset + 3;
  elseif (what < 10000)
    let (temp, low) = floor/(what, 10);
    let (temp, mid-low) = floor/(temp, 10);
    let (high, mid-high) = floor/(temp, 10);
    res[offset] := as(<character>, high + 48);
    res[offset + 1] := as(<character>, mid-high + 48);
    res[offset + 2] := as(<character>, mid-low + 48);
    res[offset + 3] := as(<character>, low + 48);
    offset + 4;
  else
    local method repeat (num :: <integer>)
	      => new-offset :: <integer>;
	    if (num < 10)
	      res[offset] := as(<character>, num + 48);
	      offset + 1;
	    else
	      let (num, digit) = floor/(num, 10);
	      let new-offset = repeat(num);
	      res[new-offset] := as(<character>, digit + 48);
	      new-offset + 1;
	    end if;
	  end method repeat;
    repeat(what);
  end if;
end method append;


// Dependency logging.

define constant $targets = make(<stretchy-vector>);
define constant $dependencies = make(<stretchy-vector>);

define method log-target (target :: <byte-string>) => ();
  add!($targets, target);
end method log-target;

define method log-dependency (dependency :: <byte-string>) => ();
  add!($dependencies, dependency);
end method log-dependency;

define method log-dependency (dependency :: <physical-locator>) => ();
  add!($dependencies, as(<byte-string>, dependency));
end method log-dependency;

define method spew-dependency-log (file :: <byte-string>) => ();
  if ($targets.empty?)
    error("No targets in spew-dependencies.");
  end if;
  let stream = make(<file-stream>, locator: file, direction: #"output");
  for (target in $targets, first? = #t then #f)
    unless (first?)
      write-element(stream, ' ');
    end unless;
    write(stream, target);
  end for;
  write-element(stream, ':');
  for (dep in $dependencies)
    format(stream, " \\\n\t%s", dep);
  end for;
  new-line(stream);
  close(stream);
end method spew-dependency-log;

