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

// some dummy priority values
define constant $low-priority         = -2;
define constant $background-priority  = -1;
define constant $normal-priority      =  0;
define constant $interactive-priority = +1;
define constant $high-priority        = +2;

define class <thread> (<object>)
  constant slot thread-function :: <function>,
    required-init-keyword: function:;
  constant slot thread-name :: false-or(<string>) = #f,
    init-keyword: name:;
  constant slot thread-priority :: <integer> = $normal-priority,
    init-keyword: priority:;
  slot thread-current-uwp :: false-or(<unwind-protect>) = #f;
  slot thread-current-handler :: false-or(<handler>) = #f;
end;

define variable *thread-created?* :: <boolean> = #f;

define method make(cls == <thread>, #key, #all-keys)
 => (thread :: <thread>);
  if(*thread-created?*)
    error("Cannot create a second thread in a single-threaded dylan.");
  else
    /* Ordering doesn't really matter, this is for style. */
    let thread = next-method();
    *thread-created?* := #t;
    thread;
  end;
end method;

define constant $the-thread
  = make(<thread>,
         name: "The Only Thread",
         function: method ()
                     error("Somebody called the thread dummy function.");
                   end,
         priority: $normal-priority);

define inline function current-thread()
 => (res :: <thread>);
  $the-thread;
end function;

define function join-thread(thread :: <thread>, #rest more-threads)
 => (thread-joined :: <thread>, #rest results);
  error("Cannot join threads in a single-threaded dylan.");
end function;

define function thread-yield() => ();
  signal("thread-yield isn't really implemented");
end function;

define sealed domain make (singleton(<thread>));
define sealed domain initialize (<thread>);
