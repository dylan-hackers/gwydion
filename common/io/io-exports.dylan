module: dylan-user

define library io
  use dylan;

  use streams, export: {streams};
  use print, export: {print, pprint};
  use format, export: {format};
  use standard-io, export: {standard-io};
  use format-out, export: {format-out};
end library;

// We need to redirect *warning-output* so that the runtime can use
// the real 'format' implementation when printing conditions.

define module redirect-io
  use dylan;

#if (~mindy)
  use standard-io;
  use extensions,
     import: {*warning-output*};
#endif
end module;
