Module:       Dylan-User
Synopsis:     DUIM extended geometry
Author:       Scott McKay, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library duim-extended-geometry
  use dylan;

  use duim-utilities;
  use duim-geometry;
  use duim-DCs;
  use duim-sheets;
  use duim-graphics;  

  export duim-extended-geometry;
  export duim-extended-geometry-internals;
end library duim-extended-geometry;
