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

// This is an implementation of the FD threading interface using
// POSIX threads.
//
// XXX: this doesn't handle priorities.

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

  // XXX: synchronization for this slot using a thread-startup-lock.
  slot thread-pthread :: false-or(<pthread-t>) = #f;

  // should only be read by the joining thread after joining and
  // only be set by the thread itself (in thread-startup-function).
  slot thread-results :: false-or(<sequence>) = #f;
end;

define method initialize(thread :: <thread>, #key, #all-keys)
 => ();
  if(thread.thread-function == thread-dummy-function)
    set-current-thread!(thread);
  else
    // XXX: this is not atomic. see slot thread-pthread.
    thread.thread-pthread := pthread-create(thread-startup-function.callback-entry,
                                            thread.object-address);
  end;
end method;

define function thread-dummy-function ()
 => ();
  error("Somebody called the thread dummy function.");
end function;

define callback-method thread-startup-function (threadptr :: <raw-pointer>)
 => (threadres :: <raw-pointer>);
  let thread = threadptr.heap-object-at;
  set-current-thread!(thread);
  block ()
    let (#rest results) = thread.thread-function();
    thread.thread-results := results;
  cleanup
    // If we are already being joined,
    // pthread-detach wont do anything.
    pthread-detach(thread.thread-pthread);
  end;
  $raw-null-pointer;
end;

define constant $the-initial-thread
  = make(<thread>,
         name: "The Initial Thread",
         function: thread-dummy-function,
         priority: $normal-priority);

c-decl("static __thread void *gd_current_thread;");
// XXX: only exists because there is no nicer way for setting a global C variable.
//      inlining nullifies the overhead.
c-decl("static inline void gd_set_current_thread(void *thread) { gd_current_thread = thread; }");

// XXX: DONT inline this. gd_current_thread is static.
define function current-thread()
 => (res :: <thread>);
  heap-object-at(c-expr(ptr: "gd_current_thread"));
end function;

// XXX: DONT inline this. gd_set_current_thread is static.
define function set-current-thread!(thread :: <thread>)
 => ();
  call-out("gd_set_current_thread", void:, ptr: thread.object-address);
end;

define function join-thread(thread :: <thread>, #rest more-threads)
 => (thread-joined :: <thread>, #rest results);
  unless(empty?(more-threads))
    error("Joining of multiple threads is not supported yet.");
  end;
  pthread-join(thread.thread-pthread);
  apply(values, thread, thread.thread-results);
end function;

define function thread-yield()
 => ();
  call-out("sched_yield", int:);
end function;

define sealed domain make (singleton(<thread>));
define sealed domain initialize (<thread>);
