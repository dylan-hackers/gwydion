Module:       Dylan-User
Synopsis:     DUIM core
Author:       Scott McKay, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// The top-level DUIM library, exports all core functionality
define library duim-core
  use dylan;

  use duim-utilities,         export: all;
  use duim-geometry,          export: all;
  use duim-DCs,               export: all;
  use duim-sheets,            export: all;
  use duim-graphics,          export: all;
  use duim-extended-geometry, export: all;
  use duim-layouts,           export: all;
  use duim-gadgets,           export: all;
  use duim-frames,            export: all;

  export duim;
  export duim-internals;
end library duim-core;
