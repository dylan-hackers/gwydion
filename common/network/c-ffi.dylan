Module:       C-FFI
Author:       Peter S. Housel
Synopsis:     C-FFI emulation
Copyright:    Original Code is Copyright 2003-2004 Gwydion Dylan Maintainers
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-License: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define constant <C-char*> = <c-string>;

define functional class <C-int*> (<statically-typed-pointer>) end;
define sealed domain make (singleton(<C-int*>));

define method content-size
    (value :: subclass(<C-int*>)) => (result :: <integer>);
  c-expr(int:, "sizeof(int)");
end method content-size;

define functional class <C-raw-unsigned-long*> (<statically-typed-pointer>)
end;
define sealed domain make (singleton(<C-raw-unsigned-long*>));

define method content-size
    (value :: subclass(<C-raw-unsigned-long*>)) => (result :: <integer>);
  c-expr(int:, "sizeof(unsigned long)");
end method content-size;

define constant <C-raw-unsigned-long>
  = referenced-type(<C-raw-unsigned-long*>);



define method null-pointer
    (pointer-designator-class :: subclass(<statically-typed-pointer>))
 => (null :: <statically-typed-pointer>);
  as(pointer-designator-class, 0)
end method;

define method null-pointer?
    (null :: <statically-typed-pointer>)
 => (null? :: <boolean>);
  as(<integer>, null) == 0;
end method;

define method pointer-address
    (c-pointer :: <statically-typed-pointer>)
 => (address :: <integer>)
  as(<integer>, c-pointer.raw-value);
end method;

define method pointer-cast
    (pointer-designator-class :: subclass(<statically-typed-pointer>),
     c-pointer :: <statically-typed-pointer>)
 => (new-c-pointer :: <statically-typed-pointer>);
  make(pointer-designator-class, pointer: c-pointer.raw-value);
end method;

define functional class <fake-designator> (<object>)
  constant slot pointer-class :: subclass(<statically-typed-pointer>),
    required-init-keyword: pointer-class:;
end class;

define sealed domain make(singleton(<fake-designator>));
define sealed domain initialize(<fake-designator>);

define inline function referenced-type
    (pointer-designator-class :: subclass(<statically-typed-pointer>))
 => (fake :: <fake-designator>);
  make(<fake-designator>, pointer-class: pointer-designator-class)
end function;

define inline function size-of
    (fake :: <fake-designator>)
 => (size :: <integer>)
  fake.pointer-class.content-size
end function;



define macro with-c-string
  { with-c-string ( ?:name = ?:expression ) ?:body end }
    => { let ?name = as(<c-string>, ?expression);
         ?body; }
end macro;

define macro with-stack-structure
  { with-stack-structure (?:name :: ?type:name,
			  #key ?element-count:expression = 1,
                               ?extra-bytes:expression = 0)
      ?:body
    end }
    => { let ?name = make(?type,
			  element-count: ?element-count,
			  extra-bytes: ?extra-bytes);
	 block ()
	   ?body
	 cleanup
	   destroy(?name);
	 end }
end macro;

define inline function clear-memory!
    (c-pointer :: <statically-typed-pointer>, bytes :: <integer>)
 => ();
  c-system-include("string.h");
  call-out("memset", ptr:, ptr: c-pointer.raw-value, int: 0, int: bytes);
end function;
