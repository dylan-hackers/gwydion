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

// Vectors
//
// Seals for most collection operations on the built-in collections can be
// found in seals.dylan.  Some exceptions apply, such as "make" and "as".
// See seals.dylan for more info.
//

// Abstract vector stuff.

define open abstract class <vector> (<array>)
end;

define sealed inline method make (class == <vector>, #key size = 0, fill)
    => res :: <simple-object-vector>;
  make(<simple-object-vector>, size: size, fill: fill);
end;

define sealed inline method as
    (class == <vector>, collection :: <collection>)
    => res :: <vector>;
  as(<simple-object-vector>, collection);
end;

define sealed inline method as
    (class == <vector>, vector :: <vector>)
    => res :: <vector>;
  vector;
end;


// out of line error functions, to minimize calling code size
// element-error is actually used throughout the runtime library

define function element-error (coll :: <collection>, index :: <integer>)
 => res :: <never-returns>;
  error("No element %d in %=", index, coll);
end function;

define function row-major-index-error (index :: <integer>)
 => res :: <never-returns>;
  error("Vector index out of bounds: %=", index);
end function;

define function vector-rank-error (indices)
 => res :: <never-returns>;
  error("Number of indices not equal to rank. Got %=, wanted one index",
	indices);
end function;




define inline method dimensions (vec :: <vector>) => res :: <simple-object-vector>;
  vector(vec.size);
end;

define inline method rank (vec :: <vector>) => res :: <integer>;
  1;
end;

define inline method row-major-index (vec :: <vector>, #rest indices)
    => index :: <integer>;
  if (indices.size ~== 1)
    vector-rank-error(indices);
  end if;
  let index :: <integer> = indices[0];
  if (index < 0 | index >= vec.size)
    row-major-index-error(index);
  end;
  index;
end;


// <simple-vector>s

define sealed abstract class <simple-vector> (<vector>)
end;

define sealed inline method make
    (class == <simple-vector>, #key size = 0, fill)
    => res :: <simple-object-vector>;
  make(<simple-object-vector>, size: size, fill: fill);
end;

define sealed inline method as
    (class == <simple-vector>, collection :: <collection>)
    => res :: <simple-vector>;
  as(<simple-object-vector>, collection);
end;

define sealed inline method as
    (class == <simple-vector>, vector :: <simple-vector>)
    => res :: <simple-vector>;
  vector;
end;


// <simple-object-vector>s

define inline function immutable-vector
    (#rest args)
 => (res :: <simple-object-vector>);
  args;
end;

define inline function vector (#rest args) => res :: <simple-object-vector>;
  %%primitive(ensure-mutable, args);
end;

define class <simple-object-vector> (<simple-vector>)
  sealed slot %element,
    init-value: #f, init-keyword: fill:,
    sizer: size, size-init-value: 0, size-init-keyword: size:;
end;

define sealed domain make (singleton(<simple-object-vector>));

define sealed inline method element
    (vec :: <simple-object-vector>, index :: <integer>,
     #key default = $not-supplied)
    => elt :: <object>;
  if (index >= 0 & index < vec.size)
    %element(vec, index);
  elseif (default == $not-supplied)
    element-error(vec, index);
  else
    default;
  end;
end;

define sealed inline method element-setter
    (new-value :: <object>, vec :: <simple-object-vector>,
     index :: <integer>)
    => new-value :: <object>;
  if (index >= 0 & index < vec.size)
    %element(vec, index) := new-value;
  else
    element-error(vec, index);
  end;
end;

define sealed inline outlined-forward-iteration-protocol <simple-object-vector>;

define sealed inline method fill!
    (vec :: <simple-vector>, value :: <object>,
     #key start :: <integer> = 0, end: end-index :: <integer> = vec.size)
 => (vec :: <simple-vector>);
  for (index :: <integer> from start below end-index)
    vec[index] := value;
  end for;
  vec;
end method fill!;

define sealed inline method as
    (class == <simple-object-vector>, vec :: <simple-object-vector>)
    => res :: <simple-object-vector>;
  vec;
end;

// Perhaps this should be inlined eventually, but at present it
// tickles a bug in stack analysis
//
define sealed method as
    (class == <simple-object-vector>, collection :: <collection>)
    => res :: <simple-object-vector>;
  let res = make(<simple-object-vector>, size: collection.size);
  for (index :: <integer> from 0, elt in collection)
    res[index] := elt;
  end;
  res;
end method as;

// This method looks to be unduly specific, but the compiler will
// generate this case whenever you "apply" a function to a list
//
define sealed inline method as
    (class == <simple-object-vector>, collection :: <list>)
    => res :: <simple-object-vector>;
  let res = make(<simple-object-vector>, size: collection.size);
  for (index :: <integer> from 0, elt in collection)
    res[index] := elt;
  end;
  res;
end method as;

// This method looks to be unduly specific, but the compiler will
// generate this case whenever you "apply" a function to a stretchy vector
// Perhaps this should be inlined eventually, but at present it
// tickles a bug in stack analysis
//
define sealed method as
    (class == <simple-object-vector>, collection :: <stretchy-object-vector>)
 => (res :: <simple-object-vector>);
  let sz = collection.size;
  let res = make(<simple-object-vector>, size: sz);
  for (index :: <integer> from 0 below sz)
    res[index] := collection[index];
  end;
  res;
end;

define inline method shallow-copy
    (collection :: <simple-object-vector>)
 => (result :: <simple-object-vector>);
  c-system-include("string.h");
  let result = make(<simple-object-vector>, size: collection.size);
  call-out("memcpy", void:,
           ptr: %%primitive(vector-elements, result),
           ptr: %%primitive(vector-elements, collection),
           int: %%primitive(vector-element-size, collection) * collection.size);
  result;
end method shallow-copy;


define open generic %elem (vec :: <vector>, index :: <integer>) 
 => (result :: <object>);
define open generic %elem-setter
    (value :: <object>, vec :: <vector>, index :: <integer>) 
 => (result :: <object>);

define macro limited-vector-class
  { limited-vector-class(?:name, ?element-type:expression, ?fill:expression) }
    => { begin
	   define sealed class ?name (<vector>)
	     sealed slot %elem :: ?element-type,
	       init-value: ?fill, init-keyword: fill:, sizer: size,
	       size-init-value: 0, size-init-keyword: size:;
	   end class;
           define sealed domain make (singleton(?name));
           define sealed domain initialize (?name);
	   define sealed inline method element-type
	       (class :: subclass(?name))
	    => (type :: <type>, indefinite? :: <false>);
	     values(?element-type, #f);
	   end method element-type;
           define sealed inline method element
	       (vec :: ?name, index :: <integer>,
		#key default = $not-supplied)
	    => element :: <object>; // because of default:
	     if (index >= 0 & index < vec.size)
	       %elem(vec, index);
	     elseif (default == $not-supplied)
	       element-error(vec, index);
	     else
	       default;
	     end;
	   end;
           define sealed inline method element-setter
	       (new-value :: ?element-type, vec :: ?name,
		index :: <integer>)
	    => new-value :: ?element-type;
	     if (index >= 0 & index < vec.size)
	       %elem(vec, index) := new-value;
	     else
	       element-error(vec, index);
	     end;
	   end;
           define sealed inline outlined-forward-iteration-protocol ?name;
         end; }
end macro;

