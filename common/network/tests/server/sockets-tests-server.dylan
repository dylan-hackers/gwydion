Module:       sockets-tests-server
Synopsis:     Sockets Tests Server
Author:       Jason Trenouth
Copyright:    Original Code is Copyright (c) 1999-2002 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual License: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define method main () => ()
  run-servers();
  wait-for-servers()
end method main;

begin
  main();
end;

ignore(unregister-server);

