module: dylan-viscera

/* Copyright 2004 Gwydion Dylan Maintainers */
/* insert GD license goop here */

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

// <synchronization-error>
//

define sealed abstract class <synchronization-error> (<error>)
  constant slot condition-synchronization :: <synchronization>,
    required-init-keyword: synchronization:;
end class;


// <count-exceeded-error>
//
// Signalled when a <semaphore> exceeds its maximum count.
//

define sealed class <count-exceeded-error> (<synchronization-error>)
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
// Signalled when a synchronization operation would lead
// to deadlock. This is an extension and meant primarily
// for the single-threaded implementation.
//

define sealed class <deadlock-error> (<synchronization-error>)
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


// <not-owned-error>
//
// Signalled when the client tries to release an <exclusive-lock>
// on a thread that is not the owner of the lock.
//

define sealed class <not-owned-error> (<synchronization-error>)
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
