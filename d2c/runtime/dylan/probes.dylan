module: dylan-viscera
copyright: see below


//======================================================================
//
// Copyright (c) 2010  Gwydion Dylan Maintainers
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

#if (use-dtrace-probes)

define inline-only method probe-gf-call-lookup-entry(generic-name :: <byte-string>)
  c-include("dylan-provider.h");
  if (probe-gf-call-lookup-entry-enabled?())
    call-out("dylan_fault_in", int:, ptr:, vector-elements-address(generic-name), int: generic-name.size);
    call-out("DYLAN_GF_CALL_LOOKUP_ENTRY", void:,
             ptr:, vector-elements-address(generic-name));
  end;
end;

define inline-only method probe-gf-call-lookup-entry-enabled?() => (result :: <boolean>);
  c-include("dylan-provider.h");
  ~ zero?(call-out("DYLAN_GF_CALL_LOOKUP_ENTRY_ENABLED", int:));
end;

define inline-only method probe-gf-call-lookup-return(generic-name :: <byte-string>, method-name :: <byte-string>)
  c-include("dylan-provider.h");
  if (probe-gf-call-lookup-return-enabled?())
    call-out("dylan_fault_in", int:, ptr:, vector-elements-address(generic-name), int: generic-name.size);
    call-out("dylan_fault_in", int:, ptr:, vector-elements-address(method-name), int: method-name.size);
    call-out("DYLAN_GF_CALL_LOOKUP_RETURN", void:,
             ptr:, vector-elements-address(generic-name),
             ptr:, vector-elements-address(method-name));
  end;
end;

define inline-only method probe-gf-call-lookup-return-enabled?() => (result :: <boolean>);
  c-include("dylan-provider.h");
  ~ zero?(call-out("DYLAN_GF_CALL_LOOKUP_RETURN_ENABLED", int:));
end;

define inline-only method probe-gf-call-lookup-error(generic-name :: <byte-string>, error :: <byte-string>)
  c-include("dylan-provider.h");
  if (probe-gf-call-lookup-error-enabled?())
    call-out("dylan_fault_in", int:, ptr:, vector-elements-address(generic-name), int: generic-name.size);
    call-out("DYLAN_GF_CALL_LOOKUP_ERROR", void:,
             ptr:, vector-elements-address(generic-name),
             ptr:, vector-elements-address(error));
  end;
end;

define inline-only method probe-gf-call-lookup-error-enabled?() => (result :: <boolean>);
  c-include("dylan-provider.h");
  ~ zero?(call-out("DYLAN_GF_CALL_LOOKUP_ERROR_ENABLED", int:));
end;

#else

/* no probes! */

define inline-only method probe-gf-call-lookup-entry(generic-name :: <byte-string>)
end;

define inline-only method probe-gf-call-lookup-entry-enabled?() => (result :: <boolean>);
  #f;
end;

define inline-only method probe-gf-call-lookup-return(generic-name :: <byte-string>, method-name :: <byte-string>)
end;

define inline-only method probe-gf-call-lookup-return-enabled?() => (result :: <boolean>);
  #f;
end;

define inline-only method probe-gf-call-lookup-error(generic-name :: <byte-string>, error :: <byte-string>)
end;

define inline-only method probe-gf-call-lookup-error-enabled?() => (result :: <boolean>);
  #f;
end;

#endif

