module: dylan-user

define library debugger
  use dylan;
  use common-dylan;
  use io;
  use melange-support;
  use command-processor;
  use string-extensions;

  export debugger;
end library debugger;

define module debugger
  use dylan;
  use extensions, exclude: { \without-bounds-checks};
  use common-dylan, exclude: { \without-bounds-checks};
  use format-out;
  use standard-io;
  use streams;
  use magic;
  use introspection;
  use system, exclude: { <buffer>, <buffer-index>,
                        buffer-next, buffer-next-setter,
                        buffer-end, buffer-end-setter};
  use melange-support;
  use command-processor;
  use string-hacking;

  export find-address;
end module debugger;
