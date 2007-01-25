module: dylan-user
copyright: see below

//======================================================================
//
// Copyright (c) 1995, 1996, 1997  Carnegie Mellon University
// Copyright (c) 1998, 1999, 2000  Gwydion Dylan Maintainers
// All rights reserved.
// 
// Use and copying of this software and preparation of derivative
// works based on this software are permitted, including commercial
// use, provided that the following conditions are observed:
// 
// 1. This copyright notice must be retained in full on any copies
//    and on appropriate parts of any derivative works.
// 2. Documentation (paper or online) accompanying any system that
//    incorporates this software, or any part of it, must acknowledge
//    the contribution of the Gwydion Project at Carnegie Mellon
//    University, and the Gwydion Dylan Maintainers.
// 
// This software is made available "as is".  Neither the authors nor
// Carnegie Mellon University make any warranty about the software,
// its performance, or its conformity to any specification.
// 
// Bug reports should be sent to <gd-bugs@gwydiondylan.org>; questions,
// comments and suggestions are welcome at <gd-hackers@gwydiondylan.org>.
// Also, see http://www.gwydiondylan.org/ for updates and documentation. 
//
//======================================================================

define library compiler-main-du
  use dylan;
  use common-dylan, import: { common-extensions };
  use compiler-base, import: { od-format, compile-time-values };
  export main-constants, main-unit-info;
end;

define module main-constants
  use dylan;
  export  $version,
          $bootstrap-counter,
          $default-dylan-dir,
          $default-dylan-user-dir,
          $gc-libs,
          $default-target-name
end;

define module main-unit-info
  use dylan;
  use common-extensions, import: { false-or };
  use od-format, import: { add-make-dumper };
  use compile-time-values, import: { *compiler-dispatcher* };
  export  <unit-info>,
          *units*,
          unit-info-name,
          unit-info-name-setter,
          undumped-objects,
          extra-labels,
          unit-linker-options,
          undumped-objects-setter,
          extra-labels-setter,
          unit-linker-options-setter;
end;
