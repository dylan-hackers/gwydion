Module:       unix-sockets
Author:       Peter S. Housel
Copyright:    Original Code is Copyright 2003 Gwydion Dylan Maintainers
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define interface
  #include { "config.h", "unix-portability.h" },
    define: { "_XOPEN_SOURCE" => "600" }, // SUSv3 (Issue 6)
    import: { "size_t" => <size-t>,
              "socklen_t" => <socklen-t>,
              "socklen_t *" => <socklen-t*>,
              "sa_family_t" => <sa-family-t>,
              "sa_family_t *" => <sa-family-t*>,
              // "struct sockaddr" => <sockaddr>,
              "struct sockaddr *" => <sockaddr*>,
              // "struct linger" => <linger>,
              "struct linger *" => <linger*>,
              // "struct msghdr" => <msghdr>,
              "struct msghdr *" => <msghdr*>,
              // "struct cmsghdr" => <cmsghdr>,
              "struct cmsghdr *" => <cmsghdr*>,
             
              "SOCK_STREAM" => $SOCK-STREAM,
              "SOCK_DGRAM" => $SOCK-DGRAM,
              "SOCK_SEQPACKET" => $SOCK-SEQPACKET,

              "AF_UNIX" => $AF-UNIX,
              "AF_INET" => $AF-INET,
              "AF_UNSPEC" => $AF-UNSPEC,

              "SHUT_RD" => $SHUT-RD,
              "SHUT_WR" => $SHUT-WR,
              "SHUT_RDWR" => $SHUT-RDWR,

              "SOL_SOCKET" => $SOL-SOCKET,

              "SO_ACCEPTCONN" => $SO-ACCEPTCONN,
              "SO_BROADCAST" => $SO-BROADCAST,
              "SO_DEBUG" => $SO-DEBUG,
              "SO_DONTROUTE" => $SO-DONTROUTE,
              "SO_ERROR" => $SO-ERROR,
              "SO_KEEPALIVE" => $SO-KEEPALIVE,
              "SO_LINGER" => $SO-LINGER,
              "SO_OOBINLINE" => $SO-OOBINLINE,
              "SO_RCVBUF" => $SO-RCVBUF,
              "SO_RCVLOWAT" => $SO-RCVLOWAT,
              "SO_RCVTIMEO" => $SO-RCVTIMEO,
              "SO_REUSEADDR" => $SO-REUSEADDR,
              "SO_SNDBUF" => $SO-SNDBUF,
              "SO_SNDLOWAT" => $SO-SNDLOWAT,
              "SO_SNDTIMEO" => $SO-SNDTIMEO,
              "SO_TYPE" => $SO-TYPE,

              "in_port_t" => <in-port-t>,
              "in_port_t *" => <in-port-t*>,
              "in_addr_t" => <in-addr-t>,
              "in_addr_t *" => <in-addr-t*>,
              "in_addr_t **" => <in-addr-t**>,

              //"struct in_addr" => <in-addr>,
              "struct in_addr *" => <in-addr*>,
             
              //"struct sockaddr_in" => <sockaddr-in>,
              "struct sockaddr_in *" => <sockaddr-in*>,
              "ntohl" => %ntohl,
              "ntohs",
              "htonl" => %htonl,
              "htons",

              // "struct hostent" => <hostent>,
              "struct hostent *" => <hostent*>,
              // "struct netent" => <netent>,
              "struct netent *" => <netent*>,
              // "struct servent" => <servent>,
              "struct servent *" => <servent*>,
              // "struct protoent" => <protoent>,
              "struct protoent *" => <protoent*>,

              "accept",
              "bind",
              "close",
              "connect",
              "getpeername",
              "getsockname",
              "getsockopt",
              "listen",
              "recv",
              "recvfrom",
              "recvmsg",
              "send",
              "sendmsg",
              "sendto",
              "setsockopt",
              "shutdown",
              "socket",
              "socketpair",

              "endhostent",
              "gethostbyaddr",
              "gethostbyname",
              "gethostent",
              "sethostent",
              "endnetent",
              "getnetbyaddr",
              "getnetbyname",
              "getnetent",
              "setnetent",
              "endservent",
              "getservbyname",
              "getservbyport",
              "getservent",
              "setservent",
              "endprotoent",
              "getprotobyname",
              "getprotobyname",
              "getprotobynumber",
              "getprotoent",
              "setprotoent",
              "inet_addr",
              // "inet_lnaof",
              // "inet_makeaddr",
              // "inet_netof",
              // "inet_network",
              "inet_ntoa",

              "gethostname"
             },
    equate: { "char *" => <c-string>,
              "int *" => <C-int*>,
              "char **" => <C-char**>,
              "struct in_addr **" => <in-addr**> },
    name-mapper: minimal-name-mapping;

  struct "struct hostent",
    rename: {"h_name" => h-name-value,
             "h_aliases" => h-aliases-value,
             "h_addrtype" => h-addrtype-value,
             "h_length" => h-length-value,
             "h_addr_list" => h-addr-list-value};
  struct "struct netent",
    rename: {"n_name" => n-name-value,
             "n_aliases" => n-aliases-value,
             "n_addrtype" => n-addrtype-value,
             "n_net" => n-net-value };
  struct "struct protoent",
    rename: {"p_name" => p-name-value,
             "p_aliases" => p-aliases-value,
             "p_proto" => p-proto-value};
  struct "struct servent",
    rename: {"s_name" => s-name-value,
             "s_aliases" => s-aliases-value,
             "s_port" => s-port-value,
             "s_proto" => s-proto-value};

  struct "struct cmsghdr",
    rename: { "cmsg_len" => cmsg-len-value,
              "cmsg_level" => cmsg-level-value,
              "cmsg_type" => cmsg-type-value };
  struct "struct sockaddr_in",
    rename: { "sin_family" => sin-family-value,
              "sin_port" => sin-port-value,
              "sin_addr" => %sin-addr-value };
  
  struct "struct linger",
    rename: { "l_onoff" => l-onoff-value, "l_linger" => l-linger-value };
  struct "struct sockaddr",
    rename: {"sa_family" => sa-family-value,
             "sa_data" => sa-data-array};
  struct "struct msghdr",
    rename: { "msg_name" => msg-name-value,
              "msg_namelen" => msg-namelen-value,
              "msg_iov" => msg-iov-value,
              "msg_iovlen" => msg-iovlen-value,
              "msg_control" => msg-control-value,
              "msg_controllen" => msg-controllen-value,
              "msg_flags" => msg-flags-value };
end interface;



define constant <sockaddr-in> = referenced-type(<sockaddr-in*>);
define constant <linger> = referenced-type(<linger*>);

define constant <in-addr> = <in-addr-t>;
// define constant <in-addr*> = <in-addr-t*>;
// define constant <in-addr**> = <in-addr-t**>;

define constant $INADDR-ANY = as(<machine-word>, 0);
define constant $INADDR-BROADCAST = as(<machine-word>, #xffffffff);
define constant $INADDR-NONE = as(<machine-word>, #xffffffff);

define inline method sin-addr-value
    (sin :: <sockaddr-in*>)
 => (addr-value :: <machine-word>);
  as(<machine-word>, unsigned-long-at(sin.%sin-addr-value))
end method;

define inline method sin-addr-value-setter
    (addr-value :: <machine-word>, sin :: <sockaddr-in*>)
 => (addr-value :: <machine-word>);
  unsigned-long-at(sin.%sin-addr-value) := as(<integer>, addr-value);
  addr-value;
end method;



define method unix-recv-buffer
    (arg1 :: <integer>, arg2 :: <machine-word>, arg3 :: <size-t>,
     arg4 :: <integer>)
 => (result :: <ssize-t>);
  recv(arg1, as(<machine-pointer>, arg2), arg3, arg4)
end method;

define method unix-send-buffer
    (arg1 :: <integer>, arg2 :: <machine-word>, arg3 :: <size-t>,
     arg4 :: <integer>)
 => (result :: <ssize-t>);
  send(arg1, as(<machine-pointer>, arg2), arg3, arg4)
end method;

define method unix-recv-buffer-from
    (arg1 :: <integer>, arg2 :: <machine-word>, arg3 :: <size-t>,
     arg4 :: <integer>, arg5 :: <sockaddr*>, arg6 :: <socklen-t*>)
 => (result :: <ssize-t>);
  recvfrom(arg1, as(<machine-pointer>, arg2), arg3, arg4, arg5, arg6);
end method;

define method unix-send-buffer-to
    (arg1 :: <integer>, arg2 :: <machine-word>, arg3 :: <size-t>,
     arg4 :: <integer>, arg5 :: <sockaddr*>, arg6 :: <socklen-t>)
 => (result :: <ssize-t>);
  sendto(arg1, as(<machine-pointer>, arg2), arg3, arg4, arg5, arg6)
end method;

define inline method htonl
    (arg1 :: <machine-word>)
 => (result :: <machine-word>);
  as(<machine-word>, %htonl(as(<integer>, arg1)))
end method;

define inline method ntohl
    (arg1 :: <machine-word>)
 => (result :: <machine-word>);
  as(<machine-word>, %ntohl(as(<integer>, arg1)))
end method;



define open primary functional class <indexable-statically-typed-pointer>
    (<statically-typed-pointer>, <mutable-collection>)
end class;

define sealed method element
    (pointer :: <indexable-statically-typed-pointer>, index :: <integer>,
     #key default)
 => (object :: <object>);
  pointer-value(pointer, index: index);
end method;

define sealed method element-setter
    (object :: <object>, pointer :: <indexable-statically-typed-pointer>,
     index :: <integer>)
 => (object :: <object>);
  pointer-value(pointer, index: index) := object;
end method;

define functional class <C-char**> (<indexable-statically-typed-pointer>) end;
define sealed domain make (singleton(<C-char**>));

define method content-size
    (value :: subclass(<C-char**>)) => (result :: <integer>);
  c-expr(int:, "sizeof(char*)");
end method content-size;

define functional class <in-addr**> (<indexable-statically-typed-pointer>) end;
define sealed domain make (singleton(<in-addr**>));

define method content-size
    (value :: subclass(<in-addr**>))
 => (result :: <integer>);
  c-expr(int:, "sizeof(struct in_addr *)");
end method content-size;
