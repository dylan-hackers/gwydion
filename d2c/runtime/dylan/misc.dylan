copyright: see below
module: dylan-viscera

//======================================================================
//
// Copyright (c) 1995 - 1997  Carnegie Mellon University
// Copyright (c) 1998 - 2004  Gwydion Dylan Maintainers
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

// assert -- exported from Extensions.  Users of assert() should not
// have side-effects in the expression that is passed to assert(),
// because if we ever turn assertions off, that would mean the program
// runs differently in debug mode than it does in release mode.

define macro assert
    { assert( ?clauses ) }
     => { ?clauses }
clauses:
  { ?ok:expression }
    => { if( ~ ?ok ) error( "An assertion failed" ) end if; }
  { ?ok:expression, ?message:expression }
    => { if( ~ ?ok ) error( ?message ) end if; }
  { ?ok:expression, ?message:expression, ?args:* }
    => { if( ~ ?ok ) error(?message, ?args) end if; }
end macro assert;

define macro debug-assert
  { debug-assert(?value:expression, ?format-string:expression, ?format-args:*)}
    =>{ assert(?value, ?format-string, ?format-args) }
    { debug-assert(?value:expression, ?message:expression) }
    =>{ assert(?value, ?message) }
    { debug-assert(?value:expression) }
    =>{ assert(?value) }
end macro debug-assert;

// <not-supplied-marker> -- internal.
//
// The class of $not-supplied.
// 
define class <not-supplied-marker> (<object>)
end;

define sealed domain make (singleton(<not-supplied-marker>));
define sealed domain initialize (<not-supplied-marker>);

// $not-supplied -- exported from Extensions.
//
// a magic marker used to flag unsupplied keywords.
// 
define constant $not-supplied :: <not-supplied-marker>
    = make(<not-supplied-marker>);


// <never-returns> -- exported from Extensions.
//
// The empty type.  When used as a function result type, it means the function
// never returns.
//
define constant <never-returns> :: <type> = <empty-type>;

define flushable generic values-sequence (sequence :: <sequence>);

define inline method values-sequence (sequence :: <sequence>)
  values-sequence(as(<simple-object-vector>, sequence));
end;

define sealed inline method values-sequence
    (vector :: <simple-object-vector>)
  %%primitive(values-sequence, vector);
end;


define movable inline function values (#rest values)
  %%primitive(values-sequence, values);
end;


define inline function object-address (object :: <object>)
    => res :: <raw-pointer>;
  %%primitive(object-address, object);
end function object-address;

define inline function heap-object-at (pointer :: <raw-pointer>)
 => (object :: <object>);
  %%primitive(heap-object-at, pointer);
end function heap-object-at;

define inline function general-object-at (pointer :: <raw-pointer>)
 => (object :: <object>);
  %%primitive(general-object-at, pointer);
end function general-object-at;

define inline function ignore (#rest noise) => ();
end function ignore;

%%primitive(magic-internal-primitives-placeholder);
