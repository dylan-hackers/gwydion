Module:       sockets-tests-client
Author:       Jason Trenouth
Synopsis:     UDP Echo Client
Copyright:    Original Code is Copyright (c) 1999-2002 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual License: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


define method UDP-echo-client () => ();
  start-sockets();
  with-socket (client-socket, protocol: #"udp", host: $loopback-address, port: 7)
    test-echo(client-socket)
  end with-socket;
end method;

register-client("UDP Echo", udp-echo-client);

