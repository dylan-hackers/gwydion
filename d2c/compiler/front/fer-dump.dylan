module: front
copyright: see below


//======================================================================
//
// Copyright (c) 1995, 1996, 1997  Carnegie Mellon University
// Copyright (c) 1998, 1999, 2000  Gwydion Dylan Maintainers
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

// Id stuff.

define variable *id-table* :: <object-table> = make(<table>);
define constant $id-vector = make(<stretchy-vector>);

define method reset-ids () => ();
  *id-table* := make(<table>);
  $id-vector.size := 0;
end;

define constant <id-able>
  = type-union(<region>, <expression>, <abstract-assignment>);

define method id (thing :: <id-able>) => res :: <integer>;
  let id = element(*id-table*, thing, default: #f);
  if (id)
    id;
  else
    let id = $id-vector.size;
    add!($id-vector, thing);
    element(*id-table*, thing) := id;
    id;
  end;
end;

define method id (id :: <integer>) => res :: <id-able>;
  unless (id < $id-vector.size)
    error("Nothing with id %d", id);
  end;
  $id-vector[id];
end;


define method print-object (thing :: <id-able>, stream :: <stream>) => ();
  write-element(stream, '{');
  write-class-name(thing, stream);
  write(stream, " [");
  print(thing.id, stream);
  write(stream, "]}");
end;




// Dump-fer itself.

define function dump-fer (thing, dump-table :: <boolean>,
                        #key stream = *debug-output*)
 => ();
  pprint-logical-block(stream, body: curry(dump, thing));
  new-line(stream);

  if (dump-table)
    new-line(stream);
    write(stream, "Dumping ID table");
    new-line(stream);
    for (thing keyed-by i in $id-vector)
      print(i, stream);
      write(stream, ": ");
      describe-and-dump-chains(thing, stream);
      new-line(stream);
    end for;
  end if;
end;


// prints a short description of the thing, possibly followed
// by a dependents and/or dependencies chain

define generic describe-and-dump-chains (thing, stream) => ();

define method describe-and-dump-chains (thing, stream) => ();
  new-line(stream);
  describe(thing, stream);
end;


define method describe-and-dump-chains (expression :: <expression>, stream)
 => ();
  next-method();
  describe-dependency-chain("Dependents", expression.dependents, stream);
end;

define method describe-and-dump-chains (depends :: <dependent-mixin>, stream)
 => ();
  next-method();
  describe-dependency-chain("Depends on", depends.depends-on, stream);
end;


define function describe-dependency-chain
    (label, chain :: false-or(<dependency>), stream)
 => ();
  new-line(stream);
  format(stream, " %s: ", label);
  for (dep = chain then dep.dependent-next,
       first? = #t then #f,
       while: dep)
    unless (first?)
      write(stream, ", ");
    end;
    format(stream, "(src-exp: %d, dependent: %d)",
           dep.source-exp.id,
           dep.dependent.id);
  end;
end describe-dependency-chain;


// This is a version of dump, but intended to print just one or at
// most several lines of information.
// It defaults to the same as dump, but has a
// specialized method for things that normally print
// arbitrarily more, e.g. IF statements or blocks

define generic describe (thing, stream) => ();

define method describe (thing, stream) => ();
  dump(thing, stream);
end;


define generic dump (thing, stream) => ();

define method dump (thing :: <object>, stream :: <stream>) => ();
  write(stream, "{a ");
  write-class-name(thing, stream);
  write-element(stream, '}');
end;

define method dump (component :: <component>, stream :: <stream>) => ();
  for (func in component.all-function-regions,
       first? = #t then #f)
    unless (first?)
      new-line(stream);
    end;
    dump(func, stream);
  end;
end;

define method describe (component :: <component>, stream :: <stream>) => ();
  write(stream, "component containing: ");
  for (func in component.all-function-regions,
       first? = #t then #f)
    unless (first?)
      write(stream, ",");
    end;
    print(func.id, stream);
  end;
end;

define method dump (region :: <simple-region>, stream :: <stream>) => ();
  for (assign = region.first-assign then assign.next-op,
       first? = #t then #f,
       while: assign)
    unless (first?)
      new-line(stream);
    end;
    dump(assign, stream);
  end;
end;

define method describe (region :: <simple-region>, stream :: <stream>) => ();
  write(stream, "region containing assignments: ");
  for (assign = region.first-assign then assign.next-op,
       first? = #t then #f,
       while: assign)
    unless (first?)
      write(stream, ",");
    end;
    print(assign.id, stream);
  end;
end;

define method dump (region :: <compound-region>, stream :: <stream>) => ();
  for (subregion in region.regions,
       first? = #t then #f)
    unless (first?)
      new-line(stream);
    end;
    dump(subregion, stream);
  end;
end;

define method describe (region :: <compound-region>, stream :: <stream>) => ();
  write(stream, "compound region containing regions: ");
  for (subregion in region.regions,
       first? = #t then #f)
    unless (first?)
      write(stream, ",");
    end;
    print(subregion.id, stream);
  end;
end;

define method dump (region :: <if-region>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     format(stream, "IF[%d] (", region.id);
	     dump(region.depends-on.source-exp, stream);
	     write-element(stream, ')');
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"mandatory", stream);
	     dump(region.then-region, stream);
	     pprint-indent(#"block", 0, stream);
	     pprint-newline(#"mandatory", stream);
	     write(stream, "ELSE");
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"mandatory", stream);
	     dump(region.else-region, stream);
	     pprint-indent(#"block", 0, stream);
	     pprint-newline(#"mandatory", stream);
	     write(stream, "END");
	   end);
end;

define method describe (region :: <if-region>, stream :: <stream>) => ();
  format(stream, "IF (%d) %d ELSE %d END",
         region.depends-on.source-exp.id,
         region.then-region.id,
         region.else-region.id);
end;

define method dump
    (region :: <unwind-protect-region>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     format(stream, "UWP[%d] (", region.id);
	     dump(region.uwp-region-cleanup-function, stream);
	     write-element(stream, ')');
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"mandatory", stream);
	     dump(region.body, stream);
	     pprint-indent(#"block", 0, stream);
	     pprint-newline(#"mandatory", stream);
	     write(stream, "END");
	   end);
end;

define method describe
    (region :: <unwind-protect-region>, stream :: <stream>) => ();
  format(stream, "UWP cleanup: %d, body: %d",
	     region.uwp-region-cleanup-function.id,
	     region.body.id);
end;

define method dump (region :: <block-region>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     format(stream, "BLOCK[%d]", region.id);
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"mandatory", stream);
	     dump(region.body, stream);
	     pprint-indent(#"block", 0, stream);
	     pprint-newline(#"mandatory", stream);
	     write(stream, "END");
	   end);
end;

define method describe (region :: <block-region>, stream :: <stream>) => ();
  format(stream, "BLOCK body: %d", region.body.id);
end;

define method dump (region :: <loop-region>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     format(stream, "LOOP[%d]", region.id);
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"mandatory", stream);
	     dump(region.body, stream);
	     pprint-indent(#"block", 0, stream);
	     pprint-newline(#"mandatory", stream);
	     write(stream, "END");
	   end);
end;

define method describe (region :: <loop-region>, stream :: <stream>) => ();
  format(stream, "LOOP body: %d", region.body.id);
end;

define method dump (region :: <exit>, stream :: <stream>) => ();
  let target = region.block-of;
  format(stream, "EXIT[%d] to %s[%d]",
	 region.id,
	 if (instance?(target, <component>)) "COMPONENT" else "BLOCK" end,
	 target.id);
end;

define method dump (region :: <return>, stream :: <stream>) => ();
  format(stream, "RETURN[%d]", region.id);
  dump-operands(region.depends-on, stream);
end;

define method dump
    (func :: <fer-function-region>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body:
       method (stream)
	 pprint-logical-block
	   (stream,
	    body:
	      method (stream)
		format(stream, "%= [%d]", func.name, func.id);
		write-element(stream, ' ');
		pprint-indent(#"block", 4, stream);
		pprint-newline(#"fill", stream);
		pprint-logical-block
		  (stream,
		   prefix: "(",
		   body:
		     method (stream)
		       let prologue-assign-dep = func.prologue.dependents;
		       for (arg-type in func.argument-types,
			    var = (prologue-assign-dep
				     & prologue-assign-dep.dependent.defines)
			      then var & var.definer-next,
			    first? = #t then #f)
			 unless (first?)
			   write(stream, ", ");
			   pprint-newline(#"fill", stream);
			 end;
			 if (var)
			   dump(var, stream);
			 else
			   write(stream, "???");
			 end;
		       end;
		     end,
		   suffix: ")");
	      end);
	 pprint-indent(#"block", 2, stream);
	 pprint-newline(#"mandatory", stream);
	 dump(func.body, stream);
	 pprint-indent(#"block", 0, stream);
	 pprint-newline(#"mandatory", stream);
	 write(stream, "END");
       end);
end;

define method describe
    (func :: <fer-function-region>, stream :: <stream>) => ();
  format(stream, "function region %= (", func.name);

  let prologue-assign-dep = func.prologue.dependents;
  for (arg-type in func.argument-types,
       var = (prologue-assign-dep
                & prologue-assign-dep.dependent.defines)
         then var & var.definer-next,
       first? = #t then #f)
    unless (first?)
      write(stream, ", ");
    end;
    if (var)
      describe(var, stream);
    else
      write(stream, "???");
    end;
  end;
  
  format(stream, "), body: %d", func.body.id);
end;

define method dump (assignment :: <assignment>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     format(stream, "[%d]: ", assignment.id);
	     if (instance?(assignment, <let-assignment>))
	       format(stream, "let ");
	     end;
	     dump-defines(assignment.defines, stream);
	     write-element(stream, ' ');
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"fill", stream);
	     write(stream, ":= ");
	     dump(assignment.depends-on.source-exp, stream);
	     write-element(stream, ';');
	   end);
end;

define method describe (assignment :: <assignment>, stream :: <stream>) => ();
  if (instance?(assignment, <let-assignment>))
    format(stream, "let ");
  end;
  dump-defines(assignment.defines, stream);
  write-element(stream, ' ');
  write(stream, ":= ");
  describe(assignment.depends-on.source-exp, stream);
end;

define method dump (assignment :: <join-assignment>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     format(stream, "[%d]: ", assignment.id);
	     dump-defines(assignment.defines, stream);
	     write-element(stream, ' ');
	     pprint-indent(#"block", 2, stream);
	     pprint-newline(#"fill", stream);
	     write(stream, "JOIN ");
	     dump(assignment.depends-on.source-exp, stream);
	     write-element(stream, ';');
	   end);
end;

define method describe (assignment :: <join-assignment>, stream :: <stream>) => ();
  dump-defines(assignment.defines, stream);
  write(stream, " JOIN ");
  describe(assignment.depends-on.source-exp, stream);
end;

define method dump-defines (defines :: false-or(<definition-site-variable>),
			    stream :: <stream>)
    => ();
  if (~defines)
    write(stream, "()");
  elseif (~defines.definer-next)
    dump-variable-and-type(defines, stream);
  else
    pprint-logical-block
      (stream,
       prefix: "(",
       body: method (stream)
	       for (def = defines then def.definer-next,
		    first? = #t then #f,
		    while: def)
		 unless (first?)
		   write(stream, ", ");
		   pprint-newline(#"fill", stream);
		 end;
		 dump-variable-and-type(def, stream);
	       end;
	     end,
       suffix: ")");
  end;
end;

define method dump-variable-and-type
    (variable :: <definition-site-variable>, stream :: <stream>)  => ()
  dump(variable, stream);
  if (variable.needs-type-check?)
    write-element(stream, '*');
  end if;
  write(stream, " :: ");
  print-message(variable.derived-type, stream);
end;

define method dump (op :: <operation>, stream :: <stream>) => ();
  format(stream, "%s[%d]", op.kind, op.id);
  dump-operands(op.depends-on, stream);
  new-line(stream);
  write(stream, " => ");
  print-message(op.derived-type, stream);
end;

define method kind (op :: <operation>) => res :: <string>;
  let stream = make(<byte-string-stream>, direction: #"output");
  write-class-name(op, stream);
  stream.stream-contents;
end;

define method kind (op :: <known-call>) => res :: <string>;
  "KNOWN-CALL";
end;

define method kind (op :: <unknown-call>) => res :: <string>;
  if (op.use-generic-entry?)
    "UNKNOWN-CALL-W/-NEXT";
  else
    "UNKNOWN-CALL";
  end;
end;

define method kind (op :: <error-call>) => res :: <string>;
  "ERROR-CALL";
end;

define method kind (op :: <delayed-optimization-call>) => res :: <string>;
  if (op.use-generic-entry?)
    "DELAYED-OPT-CALL-W/-NEXT";
  else
    "DELAYED-OPT-CALL";
  end;
end;

define method kind (op :: <mv-call>) => res :: <string>;
  if (op.use-generic-entry?)
    "MV-CALL-W/-NEXT";
  else
    "MV-CALL";
  end;
end;

define method kind (op :: <prologue>) => res :: <string>;
  "PROLOGUE";
end;

define method dump (op :: <primitive>, stream :: <stream>) => ();
  format(stream, "primitive %s[%d]", op.primitive-name, op.id);
  dump-operands(op.depends-on, stream);
end;

define method dump (op :: <module-var-ref>, stream :: <stream>) => ();
  write(stream, "ref ");
  dump(op.variable.defn-name, stream);
  format(stream, "[%d]", op.id);
  dump-operands(op.depends-on, stream);
end;

define method dump (op :: <module-var-set>, stream :: <stream>) => ();
  write(stream, "set ");
  dump(op.variable.defn-name, stream);
  format(stream, "[%d]", op.id);
  dump-operands(op.depends-on, stream);
end;

define method dump (op :: <slot-ref>, stream :: <stream>) => ();
  write(stream, "SLOT-REF ");
  let slot = op.slot-info;
  if (slot.slot-getter)
    write(stream, as(<string>, slot.slot-getter.variable-name));
  else
    write(stream, "???");
  end;
  format(stream, "[%d]", op.id);
  dump-operands(op.depends-on, stream);
end;

define method dump (op :: <heap-slot-set>, stream :: <stream>) => ();
  write(stream, "SLOT-SET ");
  let slot = op.slot-info;
  if (slot.slot-getter)
    write(stream, as(<string>, slot.slot-getter.variable-name));
  else
    write(stream, "???");
  end;
  format(stream, "[%d]", op.id);
  dump-operands(op.depends-on, stream);
end;

define method dump-operands(dep :: false-or(<dependency>), stream :: <stream>)
    => ();
  pprint-logical-block
    (stream,
     prefix: "(",
     body: method (stream)
	     for (dep = dep then dep.dependent-next,
		  first? = #t then #f,
		  while: dep)
	       unless (first?)
		 write(stream, ", ");
		 pprint-newline(#"fill", stream);
	       end;
	       dump(dep.source-exp, stream);
	     end;
	   end,
     suffix: ")");
end;

define method dump (var :: <abstract-variable>, stream :: <stream>) => ();
  dump(var.var-info, stream);
  format(stream, "[%d]", var.id);
end;

define method dump (var :: <initial-definition>, stream :: <stream>) => ();
  dump(var.var-info, stream);
  format(stream, "'[%d]", var.definition-of.id);
end;

define method dump (info :: <debug-named-info>, stream :: <stream>) => ();
  write(stream, as(<string>, info.debug-name));
end;

define method dump (name :: <basic-name>, stream :: <stream>) => ();
  write(stream, as(<string>, name.name-symbol));
end;

define method dump (name :: <method-name>, stream :: <stream>) => ();
  pprint-logical-block
    (stream,
     body: method (stream)
	     dump(name.method-name-generic-function, stream);
	     pprint-logical-block
	       (stream,
		prefix: "{",
		body: method (stream)
			for (spec in name.method-name-specializers,
			     first? = #t then #f)
			  unless (first?)
			    write(stream, ", ");
			    pprint-newline(#"fill", stream);
			  end;
			  dump(spec, stream);
			end;
		      end,
		suffix: "}");
	   end);
end;

define method dump (leaf :: <literal-constant>, stream :: <stream>) => ();
  dump(leaf.value, stream);
  format(stream, "[%d]", leaf.id);
end;

define method dump (ct-value :: <ct-value>, stream :: <stream>) => ();
  print-message(ct-value, stream);
end;

define method dump (type :: <ctype>, stream :: <stream>) => ();
  print-message(type, stream);
end;

define method dump (leaf :: <definition-constant-leaf>, stream :: <stream>)
    => ();
  dump(leaf.const-defn.defn-name, stream);
  format(stream, "[%d]", leaf.id);
end;

define method dump
    (expr :: <function-literal>, stream :: <stream>) => ();
  format(stream, "FUNCTION %= [%d]", expr.main-entry.name, expr.id);
end;

define method dump
    (expr :: <method-literal>, stream :: <stream>) => ();
  format(stream, "METHOD %= [%d]", expr.main-entry.name, expr.id);
end;

define method dump
    (exit-function :: <exit-function>, stream :: <stream>) => ();
  format(stream, "EXIT-FUN[%d]", exit-function.id);
end;
