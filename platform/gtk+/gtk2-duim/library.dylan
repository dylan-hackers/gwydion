Module:       Dylan-User
Synopsis:     GTK2 back-end
Author:       Andreas Bogk, based on gtk2 backend by Scott McKay, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2000 Functional Objects, Inc.
              All rights reserved.
              Changes Copyright (c) 2003 Gwydion Dylan Hackers
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define library gtk2-duim
  use dylan;

  use duim-utilities;  
  use duim-core;

  use gtk-2;

  export gtk2-duim;
end library gtk2-duim;
