module: dylan-user

define library threads
  use dylan;
  export threads;
end library threads;

define module threads
  use dylan;
  use runtime-threads,
    import: {<thread>, thread-name, current-thread, join-thread, thread-yield,
             $low-priority, $background-priority,
             $normal-priority, $interactive-priority, $high-priority},
    export: all;
  
  export dynamic-bind,
    <synchronization>, <exclusive-lock>,
    <semaphore>, <recursive-lock>,
    <read-write-lock>,
    <lock>, <simple-lock>, with-lock,
    atomic-increment!,
    <notification>, wait-for, release-all;
end module threads;
