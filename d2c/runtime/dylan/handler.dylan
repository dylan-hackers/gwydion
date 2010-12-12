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

// <handler> -- internal.
//
// The <handler> class encapsulates condition handlers.  Each thread has a
// chain of active condition handlers (threaded though handler-prev).  When
// a condition is signaled, the signaling thread's handlers are searched for
// a handler that wants to handle it.
// 
define class <handler> (<object>)

  // The type of condition this is a handler for.
  constant slot handler-type :: <type>,
    required-init-keyword: type:;

  // The handler function.
  constant slot handler-function :: <function>,
    required-init-keyword: function:;

  // The guard function, or #f if it isn't guarded.
  constant slot handler-test :: false-or(<function>),
    required-init-keyword: test:;

  // The init-arguments to pass make when interactively invoking this handler.
  constant slot handler-init-arguments :: <sequence>,
    required-init-keyword: init-arguments:;

  // The previous handler in the chain of handers.
  constant slot handler-prev :: false-or(<handler>),
    required-init-keyword: prev:;
end;

define sealed domain make (singleton(<handler>));
define sealed domain initialize (<handler>);


// push-handler -- internal.
//
// Push a new handler onto the current thread's chain of active handlers.  The
// compiler inserts calls to this function at ``let handler'' local
// declarations.
//
define function push-handler
    (type :: <type>, function :: <function>,
     #key test :: false-or(<function>), init-arguments :: <sequence> = #())
    => ();
  let thread = current-thread();
  thread.thread-current-handler := make(<handler>,
			     type: type,
			     function: function,
			     test: test,
			     init-arguments: init-arguments,
			     prev: thread.thread-current-handler);
end;

// pop-handler -- internal.
//
// Pop the most recent handler from the current thread's chain of active
// handlers.  The compiler inserts calls to this function at the end of the
// block for each ``let handler'' local declaration.
//
define function pop-handler () => ();
  let thread = current-thread();
  thread.thread-current-handler := thread.thread-current-handler.handler-prev;
end;


// do-handlers -- exported from Dylan.
//
// Iterate through the handlers calling the supplied function with the
// details of each one.
//
define function do-handlers (function :: <function>)
  for (h :: false-or(<handler>) = current-thread().thread-current-handler
	 then h.handler-prev,
       while: h)
    function(h.handler-type,
	     h.handler-test | method (x) #t end,
	     h.handler-function,
	     h.handler-init-arguments);
  end for;
end function do-handlers;
