copyright: see below
module: dylan-viscera

//======================================================================
//
// Copyright (c) 1995 - 1997  Carnegie Mellon University
// Copyright (c) 1998 - 2004  Gwydion Dylan Maintainers
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

/*

define open primary abstract class <value-cell> (<object>)
end;

define class <limited-value-cell-info> (<object>)
  slot lvci-type :: <type>, required-init-keyword: type:;
  slot lvci-class :: <class>, required-init-keyword: class:;
  slot lvci-next :: false-or(<limited-value-cell-info>),
    required-init-keyword: next:;
end;

define variable *limited-value-cells*
  :: false-or(<limited-value-cell-info>)
  = #f;

define method limited (class == <value-cell>, #key type :: <type>)
  block (return)
    for (entry = *limited-value-cells* then entry.lvci-next,
	 while: entry)
      if (subtype?(type, entry.lvci-type) & subtype?(entry.lvci-type, type))
	return(entry.lvci-class);
      end;
    end;
    let new = make(<class>, superclasses: <value-cell>,
		   slots: vector(vector(getter: value, setter: value-setter,
					type: type,
					required-init-keyword: value:)));
    *limited-value-cells*
      := make(<limited-value-cell-info>, type: type, class: new,
	      next: *limited-value-cells*);
    new;
  end;
end;

*/

define class <value-cell> (<object>)
  slot value, required-init-keyword: value:
end;

define sealed domain make (singleton(<value-cell>));
define sealed domain initialize (<value-cell>);

