Module:       Dylan-User
Synopsis:     DUIM layouts
Author:       Scott McKay, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library duim-layouts
  use dylan;

  use duim-utilities;
  use duim-geometry;
  use duim-DCs;
  use duim-sheets;
  use duim-graphics;  

  export duim-layouts;
  export duim-layouts-internals;
end library duim-layouts;
