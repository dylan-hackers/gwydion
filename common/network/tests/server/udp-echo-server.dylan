Module:       sockets-tests-server
Author:       Jason Trenouth
Synopsis:     UDP echo server
Copyright:    Original Code is Copyright (c) 1999-2002 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual License: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define constant $udp-echo-port = 7;

define method udp-echo-server () => ();
  start-sockets();
  with-server-socket (the-server, protocol: #"udp", port: $udp-echo-port)
    start-server(the-server, reply-socket)
      serve-echo(reply-socket)
    end start-server;
  end with-server-socket;
end method;

register-server("UDP Echo", udp-echo-server);

