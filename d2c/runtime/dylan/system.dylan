author: Nick Kramer
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

// Some of the functions that go in the System module.  Much of the
// code was moved from the d2c Main module.

c-system-include("stdlib.h");

define function import-string (ptr :: <raw-pointer>)
 => string :: <byte-string>;
  for (len :: <integer> from 0,
       until: zero?(pointer-deref(#"char", ptr, len)))
  finally
    let res = make(<byte-string>, size: len);
    for (index :: <integer> from 0 below len)
      res[index] := as(<character>, pointer-deref(#"char", ptr, index));
    end for;
    res;
  end for;
end function import-string;

define function export-string (string :: <byte-string>)
 => ptr :: <raw-pointer>;
  let len = string.size;
  let buffer = make(<buffer>, size: len + 1);
  copy-bytes(buffer, 0, string, 0, len);
  buffer[len] := 0;
  buffer-address(buffer);
end function export-string;

define function getenv (name :: <byte-string>)
 => res :: false-or(<byte-string>);
  let ptr = call-out("getenv", #"ptr", #"ptr", export-string(name));
  if (zero?(as(<integer>, ptr)))
    #f;
  else
    import-string(ptr);
  end if;
end function getenv;

define inline function system (command :: <byte-string>)
 => res :: <integer>;
  call-out("system", #"int", #"ptr", export-string(command));
end function system;

define inline function exit (#key exit-code :: <integer> = 0)
 => res :: <never-returns>;
  call-out("exit", void:, int:, exit-code);
end function exit;

define variable *on-exit-functions* :: <list> = #();

define constant on-exit-handler
  = callback-method() => ();
      for(func in *on-exit-functions*)
        func();
      end;
    end;

define function on-exit(function :: <function>)
  if(empty?(*on-exit-functions*))
    call-out("atexit", int:, ptr: callback-entry(on-exit-handler));
  end if;
  *on-exit-functions* := add(*on-exit-functions*, function);
end function;

// no-core-dumps
//
// Sets the current limit for core dumps to 0.  Keeps us from dumping 32+ meg
// core files when we hit an error.
//
// On Windows machines, this does nothing because windows machines
// don't dump core.
//
define function no-core-dumps () => ();
  #if (~ compiled-for-win32)
   call-out("no_core_dumps", #"void");
  #endif
end function no-core-dumps;

define inline function get-time-of-day () => res :: <integer>;
  call-out("time", int:, int: 0);
end;
