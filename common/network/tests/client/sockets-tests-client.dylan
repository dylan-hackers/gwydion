Module:       sockets-tests-client
Synopsis:     A brief description of the project.
Author:       Jason Trenouth
Copyright:    Original Code is Copyright (c) 1999-2002 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual License: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define suite sockets-test-suite ()
  test sockets-tests;
end suite;

define test sockets-tests ()
  run-clients();
end test;

define method main () => ()
  run-test-application(sockets-test-suite);
end method main;

begin
  main();
end;
