module: dylan-viscera

/* Copyright 2004 Gwydion Dylan Maintainers */
/* insert GD license goop here */

// This is an implementation of the FD synchronization
// protocol for single-threaded systems.
//
// It can also be used as a template for real implementations.
//

// <semaphore>
//
// This behaves like a multithreaded implementation,
// but catches deadlocks, signaling a <deadlock-error>.
//

// A random limit for the semaphore count.
// This is specified to be at least 10000.
define constant $semaphore-maximum-count-limit = 60000;

define open primary class <semaphore> (<lock>)
  constant slot semaphore-maximum-count :: <semaphore-count>
    = $semaphore-maximum-count-limit,
    init-keyword: maximum-count:;
  slot semaphore-count :: <semaphore-count> = 0,
    init-keyword: initial-count:;
end class;

define sealed method wait-for(sem :: <semaphore>,
                              #key timeout :: false-or(<real>) = #f)
 => (success? :: <boolean>);
  if(sem.semaphore-count > 0)
    sem.semaphore-count := sem.semaphore-count - 1;
  else
    deadlock-error(sem);
  end;
  #t;
end method;

define sealed method release(sem :: <semaphore>, #key, #all-keys)
 => ();
  if(sem.semaphore-count < sem.semaphore-maximum-count)
    sem.semaphore-count := sem.semaphore-count + 1;
  else
    count-exceeded-error(sem);
  end;
end method;


// <recursive-lock>
//
// This implementation of <read-write-lock> should behave
// exactly as specified by FD.
//

define open primary class <recursive-lock> (<exclusive-lock>)
  slot recursive-lock-count :: <integer> = 0;
end class;

define sealed method wait-for(lock :: <recursive-lock>,
                              #key timeout :: false-or(<real>) = #f)
 => (success? :: <boolean>);
  lock.recursive-lock-count := lock.recursive-lock-count + 1;
  #t;
end method;

define sealed method release(lock :: <recursive-lock>, #key, #all-keys)
 => ();
  if(lock.owned?)
    lock.recursive-lock-count := lock.recursive-lock-count - 1;
  else
    not-owned-error(lock);
  end;
end method;

define sealed method owned?(lock :: <recursive-lock>)
 => (owned? :: <boolean>);
  lock.recursive-lock-count > 0;
end method;


// <simple-lock>
//
// This behaves like a multithreaded implementation,
// but catches deadlocks, signaling a <deadlock-error>.
//

define open primary class <simple-lock> (<exclusive-lock>)
  sealed slot owned? :: <boolean> = #f;
end class;

define sealed method wait-for(lock :: <simple-lock>,
                       #key timeout :: false-or(<real>) = #f)
 => (success? :: <boolean>);
  if(lock.owned?)
    deadlock-error(lock);
  else
    lock.owned? := #t;
  end;
  #t;
end method;

define sealed method release(lock :: <simple-lock>, #key, #all-keys)
 => ();
  if(lock.owned?)
    lock.owned? := #f;
  else
    not-owned-error(lock);
  end;
end method;


// <read-write-lock>
//
// This behaves like a multithreaded implementation,
// but catches deadlocks, signaling a <deadlock-error>.
//

define open primary class <read-write-lock> (<exclusive-lock>)
  sealed slot owned? :: <boolean> = #f;
  slot lock-read-locks :: <integer> = 0;
end class;

define sealed method wait-for(lock :: <read-write-lock>,
                              #key timeout :: false-or(<real>) = #f,
                                   mode :: <read-write-lock-mode> = read:)
 => (success? :: <boolean>);
  if(lock.owned?)
    deadlock-error(lock);
  else
    select(mode)
      read: =>
        lock.lock-read-locks := lock.lock-read-locks + 1;
      write: =>
        if(lock.lock-read-locks > 0)
          deadlock-error(lock);
        else
          lock.owned? := #t;
        end;
    end;
  end;
  #t;
end method;

define sealed method release(lock :: <read-write-lock>, #key, #all-keys)
 => ();
  case
    lock.owned? =>
      lock.owned? := #f;
    lock.lock-read-locks > 0 =>
      lock.lock-read-locks := lock.lock-read-locks - 1;
    otherwise =>
      not-owned-error(lock);
  end;
end method;


// <notification>
// XXX: implement dummies
//

define sealed class <notification> (<synchronization>)
  constant slot associated-lock :: <simple-lock>,
    required-init-keyword: lock:;
end class;

define sealed method wait-for(not :: <notification>,
                       #key timeout :: false-or(<real>) = #f)
 => (success? :: <boolean>);
  error("wait-for(<notification>) -> BAD!");
end method;

define sealed method release(not :: <notification>, #key, #all-keys)
 => ();
  error("release(<notification>) -> BAD!");
end method;

define function release-all(not :: <notification>)
 => ();
  error("release-all(<notification>) -> BAD!");
end function;
