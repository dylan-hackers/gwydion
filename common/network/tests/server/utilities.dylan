Module:       sockets-tests-server
Synopsis:     Utilities for Sockets Tests Server
Author:       Jason Trenouth
Copyright:    Original Code is Copyright (c) 1999-2002 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual License: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define class <server> (<object>)
  constant slot server-name :: <string>, required-init-keyword: name:;
  constant slot server-function :: <function>, required-init-keyword: function:;
  slot server-thread :: <thread>;
end class;

define sealed domain make (singleton(<server>));
define sealed domain initialize (<server>);

define constant $servers :: <table> = make(<table>);

define method register-server (name :: <string>, function :: <function>)
  element($servers, as(<symbol>, name)) := make(<server>, name: name, function: function);
end method;

define method unregister-server (name :: <string>);
  remove-key!($servers, as(<symbol>, name))
end method;

define method run-servers ()
  for (server :: <server> in $servers)
    server-thread(server) :=
      make(<thread>,
           name: server-name(server),
           function: server-function(server));
  end for;
end method;

define method wait-for-servers ()
  for (server :: <server> in $servers)
    join-thread(server-thread(server))
  end for;
end method;

