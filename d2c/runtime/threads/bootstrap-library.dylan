module: dylan-user

define library threads
  use dylan;
  export threads;
end library threads;

define module threads
  use dylan;
  export
    <thread>, current-thread, thread-name, join-thread,
    <synchronization>, <lock>, <semaphore>, <exclusive-lock>,
    <recursive-lock>, <simple-lock>, <read-write-lock>,
    <notification>, wait-for, release-all,
    dynamic-bind,
    with-lock,
    atomic-increment!;
end module threads;
