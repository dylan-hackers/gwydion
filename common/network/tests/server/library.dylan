Module:       dylan-user
Synopsis:     Sockets Tests Server
Author:       Jason Trenouth
Copyright:    Original Code is Copyright (c) 1999-2002 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual License: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library sockets-tests-server
  use functional-dylan;
  use network;
  use io;
  use system;

  // Add any more module exports here.
  export sockets-tests-server;
end library sockets-tests-server;
