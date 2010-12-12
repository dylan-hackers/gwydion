copyright: see below
module: dylan-viscera

//======================================================================
//
// Copyright (c) 2004  Gwydion Dylan Maintainers
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

// This is the threading-system-independent part of the
// synchronization protocol implementation.
//


// ABSTRACT SYNCHRONIZATION CLASSES
//

// <synchronization>
//

define open abstract class <synchronization> (<object>)
  constant slot synchronization-name :: false-or(<string>) = #f,
    init-keyword: name:;
end class;

define open generic wait-for(object :: <synchronization>,
                             #key timeout :: false-or(<real>))
 => (success? :: <boolean>);

define open generic release(object :: <synchronization>, #key)
 => ();


// <lock>
//

define open abstract class <lock> (<synchronization>)
end class;

define method make(cls == <lock>, #rest inits, #key, #all-keys)
 => (lock :: <simple-lock>);
  apply(make, <simple-lock>, inits);
end method;


// <exclusive-lock>
//

define open abstract class <exclusive-lock> (<lock>)
end class;

define open generic owned?(lock :: <exclusive-lock>)
 => (owned? :: <boolean>);

define method make(cls == <exclusive-lock>, #rest inits, #key, #all-keys)
 => (lock :: <simple-lock>);
  apply(make, <simple-lock>, inits);
end method;


// SYNCHRONIZATION IMPLEMENTATION UTILITIES
//

// <semaphore>
//

define constant <semaphore-count>
  = limited(<integer>, min: 0, max: $semaphore-maximum-count-limit);


// <read-write-lock>
//

define constant <read-write-lock-mode> = one-of(#"read", #"write");


// SYNCHRONIZATION CONDITIONS
//

// <synchronization-condition>
//

define sealed abstract class <synchronization-condition> (<condition>)
  constant slot condition-synchronization :: <synchronization>,
    required-init-keyword: synchronization:;
end class;


// <count-exceeded-error>
//
// Signaled when a <semaphore> exceeds its maximum count.
//

define sealed class <count-exceeded-error> (<synchronization-condition>, <error>)
end class;

define sealed method default-handler (cond :: <count-exceeded-error>)
 => ();
  invoke-debugger(*debugger*, cond);
end method;

define function count-exceeded-error(sem :: <semaphore>)
 => ();
  error(make(<count-exceeded-error>,
             synchronization: sem));
end function;


// <deadlock-error>
//
// Signaled when a synchronization operation would lead
// to deadlock. This is an extension and meant primarily
// for the single-threaded implementation.
//

define sealed class <deadlock-error> (<synchronization-condition>, <error>)
end class;

define sealed method default-handler (cond :: <deadlock-error>)
 => ();
  invoke-debugger(*debugger*, cond);
end method;

define function deadlock-error(sync :: <synchronization>)
 => ();
  error(make(<deadlock-error>,
             synchronization: sync));
end function;


// <timeout-exceeded>
//

define sealed class <timeout-exceeded> (<synchronization-condition>, <serious-condition>)
end class;

define sealed method default-handler (cond :: <timeout-exceeded>)
 => ();
  invoke-debugger(*debugger*, cond);
end method;

define function timeout-exceeded(sync :: <synchronization>)
 => ();
  error(make(<timeout-exceeded>,
             synchronization: sync));
end function;


// <not-owned-error>
//
// Signaled when the client tries to release an <exclusive-lock>
// on a thread that is not the owner of the lock.
//

define sealed class <not-owned-error> (<synchronization-condition>, <error>)
end class;

define sealed method default-handler (cond :: <not-owned-error>)
 => ();
  invoke-debugger(*debugger*, cond);
end method;

define function not-owned-error(lock :: <exclusive-lock>)
 => ();
  error(make(<deadlock-error>,
             synchronization: lock));
end function;


// MACROS
//

// with-lock
//

define macro with-lock
  { with-lock (?lock:expression, ?keys:*)
      ?body:body
      ?failure
    end }
    => { begin
           let $$the-lock = ?lock;
           if(wait-for($$the-lock, ?keys))
             block ()
                 ?body
             cleanup
                 release($$the-lock);
             end;
           else
             ?failure
           end
         end }

 failure:
  { failure ?body:body }
    => { ?body }
  { }
    => { timeout-exceeded($$the-lock) }
end macro;
