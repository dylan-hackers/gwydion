module: dylan-user

define library threads
  use dylan;
  export threads;
end library threads;

define module threads
  use dylan;
  use runtime-threads,
    import: {<thread>, thread-name, current-thread, join-thread, thread-yield,
             $low-priority, $background-priority, $normal-priority, $interactive-priority, $high-priority,
             <synchronization>, wait-for, release,
             <lock>, <exclusive-lock>, owned?,
             <semaphore>, <simple-lock>, <recursive-lock>, <read-write-lock>,
             <notification>, release-all,
             <count-exceeded-error>, <not-owned-error>},
    export: all;
  
  export
    dynamic-bind,
    with-lock,
    atomic-increment!;
end module threads;
