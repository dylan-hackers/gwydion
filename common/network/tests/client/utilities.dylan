Module:       sockets-tests-client
Author:       Jason Trenouth
Copyright:    Original Code is Copyright (c) 1999-2002 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual License: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define macro with-input-from-string
  { with-input-from-string (?stream:name = ?string:expression, #rest ?options:*)
      ?body:body
    end }
 => { let ?stream :: <string-stream>
        = make(<string-stream>, contents: ?string, direction: #"input", ?options);
      ?body;
    }
  { with-input-from-string (?stream:name :: ?class:name = ?string:expression, #rest ?options:*)
      ?body:body
    end }
 => { let ?stream :: ?class = make(?class, contents: ?string, direction: #"output", ?options);
      ?body;
    }
end macro with-input-from-string;

define class <client> (<object>)
  constant slot client-name :: <string>, required-init-keyword: name:;
  constant slot client-function :: <function>, required-init-keyword: function:;
end class;

define sealed domain make (singleton(<client>));
define sealed domain initialize (<client>);

define constant $clients :: <table> = make(<table>);

define method register-client (name :: <string>, function :: <function>)
  element($clients, as(<symbol>, name)) := make(<client>, name: name, function: function);
end method;

define method unregister-client (name :: <string>);
  remove-key!($clients, as(<symbol>, name))
end method;

define method run-clients ()
  for (client :: <client> in $clients)
    client-function(client)()
  end for;
end method;

ignore(unregister-client);
ignore(client-name);

