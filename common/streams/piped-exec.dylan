module: piped-exec
author: Nick Kramer
rcs-header: $header$
copyright: Copyright (c) 1996  Carnegie Mellon University
	   All rights reserved.

// Implements piped-exec, aka fd-exec

#if (mindy)

define function piped-exec (command-line :: <string>) 
 => writeable-pipe :: <stream>, readable-pipe :: <stream>;
  let (writable-pipe, readable-pipe) = fd-exec(command-line);
  let writeable-pipe = make(<fd-stream>, direction: #"output", fd: to-fd);
  let readable-pipe = make(<fd-stream>, direction: #"input", fd: from-fd);
  values(writeable-pipe, readable-pipe);
end function piped-exec;

#else

define functional class <int-ptr> (<statically-typed-pointer>) end;

define method pointer-value
    (ptr :: <int-ptr>, #key index = 0)
 => (result :: <integer>);
  signed-long-at(ptr, offset: index * 4);
end method pointer-value;

define method pointer-value-setter
    (value :: <integer>, ptr :: <int-ptr>, #key index = 0)
 => (result :: <integer>);
  signed-long-at(ptr, offset: index * 4) := value;
  value;
end method pointer-value-setter;

define method content-size (value :: subclass(<int-ptr>)) 
 => (result :: <integer>);
  4;
end method content-size;

define function piped-exec (command-line :: <string>) 
 => (writeable-pipe :: <stream>, readable-pipe :: <stream>);
  let writeable-fd-ptr = make(<int-ptr>);
  let readable-fd-ptr = make(<int-ptr>);
  call-out("fd_exec", void:, 
	   ptr: (export-value(<c-string>, command-line)).raw-value, 
	   ptr: writeable-fd-ptr.raw-value, 
	   ptr: readable-fd-ptr.raw-value);

  let writeable-fd = pointer-value(writeable-fd-ptr);
  destroy(writeable-fd-ptr);
  let readable-fd = pointer-value(readable-fd-ptr);
  destroy(readable-fd-ptr);

  let writeable-pipe = make(<fd-stream>, direction: #"output", 
			    fd: writeable-fd);
  let readable-pipe = make(<fd-stream>, direction: #"input", fd: readable-fd);
  values(writeable-pipe, readable-pipe);
end function piped-exec;

#endif