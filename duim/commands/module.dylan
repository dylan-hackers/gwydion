Module:       Dylan-User
Synopsis:     Commands module
Author:       Scott McKay, Hugh Greene
Copyright:    Original Code is Copyright (c) 1998-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// Export module for Commands clients
define module commands
  create <basic-command>,
	 <command>,
	 command-client,
	 command-server,
	 command-invoker,
	 command-results-to;

  create <command-results>,
	 command-results,
	 command-results-available?,
	 wait-for-command-results;

  create make-command,
	 execute-command-type,
	 execute-command,
	 do-execute-command;

  create <basic-undoable-command>,
	 command-undoable?,
	 undo-command,
	 redo-command;

  create <functional-command>,
	 command-function,
	 command-arguments;

  create <basic-string-command>,
	 <string-command>,
	 string-for-command,
	 string-for-argument,
	 object-to-string,
	 \string-command-definer,
	 \string-command-class-definer,
	 \string-command-slots-definer;
end module commands;

// Implementation module
define module commands-internals
  use common-dylan;
  use commands, export: all;

  export command-pattern-string,
	 command-argument-names;
end module commands-internals;
