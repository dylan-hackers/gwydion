module: dylan-viscera

define constant <pthread-t> = <integer>;

define function pthread-create(function :: <raw-pointer>,
                               argument :: <raw-pointer>)
 => (thread :: <pthread-t>);
  c-local-decl("pthread_t pth;");
  let result = call-out("pthread_create", int:,
                        ptr: c-expr(ptr: "&pth"),
                        ptr: $raw-null-pointer,
                        ptr: function,
                        ptr: argument);
  if(result ~= 0)
    error("pthread_create failed for some reason.");
  end;
  c-expr(int: "pth");
end function;

define function pthread-join(thread :: <pthread-t>)
 => (result :: <raw-pointer>);
  c-local-decl("void *res;");
  let result = call-out("pthread_join", int:,
                        int: thread, ptr: c-expr(ptr: "&res"));
  if(result ~= 0)
    error("pthread_join failed for some reason.");
  end;
  c-expr(ptr: "res");
end function;

define function pthread-detach(thread :: <pthread-t>)
 => ();
  let result = call-out("pthread_detach", int:, int: thread);
  if(result ~= 0)
    error("pthread_detach failed for some reason.");
  end;
end function;

define function pthread-self()
 => (thread :: <pthread-t>);
  call-out("pthread_self", int:);
end function;
