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

// <debugger> -- exported from Extensions
//
// Abstract superclass of all the different kinds of debuggers.
//
define primary abstract open class <debugger> (<object>)
end class <debugger>;

// invoke-debugger -- exported from Extensions
//
// Called by the condition system on *debugger* and the condition when it
// wants to invoke the debugger.  And values returned are passed back on out
// to the original caller of signal when appropriate.
// 
define open generic invoke-debugger
    (debugger :: <debugger>, condition :: <condition>)
    => (#rest values);

// debugger-message -- exported from Extensions
//
// Called to print a message via *debugger*.
// 
define open generic debugger-message
    (debugger :: <debugger>, fmt :: <byte-string>, #rest args) => ();

// *debugger* -- exported from Extensions
//
// Value passed in to invoke-debugger when the condition system needs to
// invoke the debugger.
// 
define variable *debugger* :: <debugger> = make(<null-debugger>);


// The null debugger.

// <null-debugger> -- internal.
//
define class <null-debugger> (<debugger>)
end class <null-debugger>;

define sealed domain make (singleton(<null-debugger>));
define sealed domain initialize (<null-debugger>);

// *warning-output* -- exported from Extensions
//
// The ``stream'' to which warnings report when signaled (and not handled).
//
define variable *warning-output* :: <object> = #"Cheap-Err";

// invoke-debugger(<null-debugger>) -- exported gf method
//
// The null debugger doesn't do much: it just prints the condition and then
// aborts.
// 
define sealed method invoke-debugger
    (debugger :: <null-debugger>, condition :: <serious-condition>)
 => (res :: <never-returns>);
  condition-format(*warning-output*, "%s\n", condition);
  condition-force-output(*warning-output*);
  c-system-include("stdlib.h");
  call-out("abort", void:);
end;

define sealed method invoke-debugger
    (debugger :: <null-debugger>, condition :: <warning>)
 => (res :: <false>);
  condition-format(*warning-output*, "%s\n", condition);
  condition-force-output(*warning-output*);
  #f;
end;

// debugger-message(<null-debugger>) -- exported gf method
//
define sealed method debugger-message
    (debugger :: <null-debugger>, fmt :: <byte-string>, #rest args) => ();
  apply(condition-format, *warning-output*, fmt, args);
  condition-format(*warning-output*, "\n");
  condition-force-output(*warning-output*);
end method;



// debug-message -- exported from Extensions
//
define function debug-message(fmt :: <byte-string>, #rest args) => ();
  block (return)
    apply(debugger-message, *debugger*, fmt, args);
  exception (error :: <error>)
    return();                   // ignore all errors
  end;
end function;
