module: dylan-viscera
author: ram+@cs.cmu.edu
synopsis: <buffer> and <byte-vector>
copyright: see below

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

// Byte-vectors and buffers
//
// Seals for most collection operations on the built-in collections can be
// found in seals.dylan.  Some exceptions apply, such as "make" and "as".
// See seals.dylan for more info.
//

c-include("string.h");

define /* exported */ constant <byte> =
  limited(<integer>, min: 0, max: 255);
define /* exported */ constant <buffer-index> = <integer>;
define /* exported */ constant $maximum-buffer-size = $maximum-integer;


define /* exported */ class <byte-vector> (<simple-vector>)
  sealed slot %element :: <byte>,
    init-value: 0, init-keyword: fill:,
    sizer: size, size-init-value: 0, size-init-keyword: size:;
end;

define sealed domain make (singleton(<byte-vector>));

define /* exported */ class <buffer> (<simple-vector>)
  slot buffer-next :: <buffer-index>, init-value: 0, init-keyword: next:;
  slot buffer-end :: <buffer-index>, init-value: 0, init-keyword: end:;
  sealed slot %element :: <byte>,
    init-value: 0, init-keyword: fill:,
    sizer: size, size-init-value: 0, size-init-keyword: size:;
end class;

define sealed domain make (singleton(<buffer>));

define sealed inline method element
    (vec :: <byte-vector>, index :: <integer>,
     #key default = $not-supplied)
    => element :: <object>; // because of default:
  if (index >= 0 & index < vec.size)
    %element(vec, index);
  elseif (default == $not-supplied)
    element-error(vec, index);
  else
    default;
  end;
end;

define sealed inline method element-setter
    (new-value :: <byte>, vec :: <byte-vector>, index :: <integer>)
    => new-value :: <byte>;
  if (index >= 0 & index < vec.size)
    %element(vec, index) := new-value;
  else
    element-error(vec, index);
  end;
end;

define sealed inline method element
    (buf :: <buffer>, index :: <buffer-index>,
     #key default = $not-supplied)
 => element :: <object>; // because of default:
  if (index >= 0 & index < buf.size)
    %element(buf, index);
  elseif (default == $not-supplied)
    element-error(buf, index);
  else
    default;
  end;
end;

define sealed inline method element-setter
    (new-value :: <byte>, buf :: <buffer>, index :: <buffer-index>)
 => new-value :: <byte>;
  if (index >= 0 & index < buf.size)
    %element(buf, index) := new-value;
  else
    element-error(buf, index);
  end;
end;


define constant <byte-vector-like> = type-union(<byte-vector>,
                                           <buffer>,
                                           <byte-string>,
                                           <unicode-string>);

// Copy bytes from src to dest (which may overlap.)  
define /* exported */ generic copy-bytes 
  (dest :: <byte-vector-like>, dest-start :: <integer>, 
   src :: <byte-vector-like>, src-start :: <integer>,
   count :: <integer>)
 => ();

// These methods are all the same modulo specializers, but are replicated so
// that the vector-elements works.  Also, the mixed type operations can use
// memcpy, since the source and destination can't overlap.

define method copy-bytes 
    (dest :: <byte-vector>, dstart :: <integer>,
     src :: <byte-vector>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memmove", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <byte-string>, dstart :: <integer>,
     src :: <byte-vector>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memcpy", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <byte-vector>, dstart :: <integer>,
     src :: <byte-string>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memcpy", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <byte-string>, dstart :: <integer>,
     src :: <byte-string>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memmove", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <buffer>, dstart :: <integer>,
     src :: <buffer>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memmove", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <byte-string>, dstart :: <integer>,
     src :: <buffer>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memcpy", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <buffer>, dstart :: <integer>,
     src :: <byte-string>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memcpy", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <byte-vector>, dstart :: <integer>,
     src :: <buffer>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memcpy", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <buffer>, dstart :: <integer>,
     src :: <byte-vector>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memcpy", void:,
	   ptr: %%primitive(vector-elements, dest) + dstart,
	   ptr: %%primitive(vector-elements, src) + sstart,
	   int: count);
end method;

define method copy-bytes 
    (dest :: <unicode-string>, dstart :: <integer>,
     src :: <unicode-string>, sstart :: <integer>, count :: <integer>)
 => ();
  call-out("memmove", void:,
	   ptr: %%primitive(vector-elements, dest) + (2 * dstart),
	   ptr: %%primitive(vector-elements, src) + (2 * sstart),
	   int: (2 * count));
end method;

define /* exported */ method buffer-address (x :: <buffer>)
 => res :: <raw-pointer>;
  %%primitive(vector-elements, x);
end method;
