module: top-level-forms
copyright: see below

//======================================================================
//
// Copyright (c) 1995, 1996, 1997  Carnegie Mellon University
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

define variable *Top-Level-Forms* = make(<stretchy-vector>);

define sealed class <tlf-dependency>(<general-dependency>)
  slot source-tlf :: <top-level-form>, required-init-keyword: source:;
end;


define function add-tlf-dependency (from :: <top-level-form>, to :: <top-level-form>) => ()
  block (return)
    return(); // XXX
    for (dep = to.depends-on then dep.dependent-next, while: dep)
      dep.source-tlf == from
      	& return();
    end for;
    to.depends-on
      := make(<tlf-dependency>, source: from, dependent: to,
      	      dependent-next: to.depends-on, source-next: from.tlf-dependents);
    from.tlf-dependents := to.depends-on;
  end block;
end;


define open primary abstract class <top-level-form> (<source-location-mixin>, <dependent-mixin>)
  slot tlf-component :: false-or(<component>) = #f, init-keyword: component:;
  slot tlf-init-function :: false-or(<ct-function>) = #f,
    init-keyword: init-function:;
  //
  // Threaded list of the dependencies connecting this tlf to the
  // dependent that use this expression.
  slot tlf-dependents :: false-or(<tlf-dependency>),
    init-value: #f, init-keyword: dependents:;
end;

define open primary abstract class <define-tlf> (<top-level-form>)
end;

define open primary abstract class <simple-define-tlf> (<define-tlf>)
  slot tlf-defn :: <definition>, init-keyword: defn:;
end;

define method print-object (tlf :: <simple-define-tlf>, stream :: <stream>)
    => ();
  if (slot-initialized?(tlf, tlf-defn))
    pprint-fields(tlf, stream, name: tlf.tlf-defn.defn-name);
  else
    pprint-fields(tlf, stream);
  end;
end;

// finalize-top-level-form -- exported.
//
// Called by the main driver on each top level form in *Top-Level-Forms*
// after everything has been parsed.
//
define open generic finalize-top-level-form (tlf :: <top-level-form>) => ();

// convert-top-level-form
//
define open generic convert-top-level-form
    (builder :: <fer-builder>, tlf :: <top-level-form>)
    => ();


// Specific top level forms.

define open abstract class <define-generic-tlf> (<simple-define-tlf>)
  //
  // Make the definition required.
  required keyword defn:;
end class <define-generic-tlf>;


define open abstract class <define-method-tlf> (<simple-define-tlf>)
end class <define-method-tlf>;

define method print-message
    (tlf :: <define-method-tlf>, stream :: <stream>) => ();
  if (slot-initialized?(tlf, tlf-defn))
    format(stream, "Define Method %s", tlf.tlf-defn.defn-name);
  else
    format(stream, "Define Method ???");
  end;
end;


define open abstract class <define-bindings-tlf> (<define-tlf>)
  constant slot tlf-required-defns :: <simple-object-vector>,
    required-init-keyword: required-defns:;
  constant slot tlf-rest-defn :: false-or(<bindings-definition>),
    required-init-keyword: rest-defn:;
end class <define-bindings-tlf>;


define class <define-class-tlf> (<simple-define-tlf>)
  //
  // Make the definition required.
  required keyword defn:;
  //
  // Stretchy vector of <init-function-definition>s.
  constant slot tlf-init-function-defns :: <stretchy-vector>
    = make(<stretchy-vector>);
end;

define method print-message
    (tlf :: <define-class-tlf>, stream :: <stream>) => ();
  format(stream, "Define Class %s", tlf.tlf-defn.defn-name);
end;



define class <magic-internal-primitives-placeholder> (<top-level-form>)
end;

define method print-message
    (tlf :: <magic-internal-primitives-placeholder>, stream :: <stream>) => ();
  write(stream, "Magic internal primitives.");
end;



// Dump stuff.

/* In the interest of incremental compilation, we dump everything these
   days

define method dump-od
    (tlf :: <top-level-form>, state :: <dump-state>) => ();
  let start = state.current-pos;
  dump-definition-header(#"top-level-form", state, subobjects: #t);
  dump-od(tlf.tlf-component, state);
  dump-od(tlf.tlf-init-function, state);
  dump-end-entry(start, state);
end method dump-od;

add-od-loader(*compiler-dispatcher*, #"top-level-form",
              method (state :: <load-state>) => res :: <definition>;
                let component = load-object-dispatch(state);
                let init-function = load-object-dispatch(state);
                let tlf = make(<top-level-form>,
                               component: component,
                               init-function: init-function);
                assert-end-object(state);
              end method
);
*/


// Convert a depends-on thread back into a list of tlf objects, as used by the
// builder.
//
define function tlf-depends-list (x :: <dependent-mixin>)
 => res :: type-union(<top-level-form>, <list>);
  let dep-on = x.depends-on;
  if (~dep-on)
    #();
  elseif (~dep-on.dependent-next)
    dep-on.source-tlf
  else
    for (cur = dep-on then cur.dependent-next,
	 res = #() then pair(cur.source-tlf, res),
	 while: cur)
    finally reverse!(res)
    end for;
  end if;
end function;


define class <loaded-define-tlf> (<define-tlf>)
end;

define generic loaded-tlf (defn :: <definition>) => tlf :: <top-level-form>;

// define method loaded-tlf (defn :: type-union(/* <function-definition>, */ <macro-definition>, <class-definition>)) => tlf :: <loaded-define-tlf>;
//   let tlf = make(<loaded-define-tlf>,
//                  source-location: defn.source-location);
//   find-variable(defn.defn-name).variable-tlf := tlf;
// end;

define method loaded-tlf (defn :: <definition>) => tlf :: <loaded-define-tlf>;
  let tlf = make(<loaded-define-tlf>,
                 source-location: defn.source-location);
  find-variable(defn.defn-name).variable-tlf := tlf;
//  compiler-warning("strange definition: %=", defn);
end;


// If name's var isn't visible outside this library, don't bother dumping the
// definition.
//
define method dump-od
    (tlf :: <simple-define-tlf>, state :: <dump-state>) => ();
  let defn = tlf.tlf-defn;
  if (name-inherited-or-exported?(defn.defn-name))
    dump-simple-object(#"define-binding-tlf", state, defn, tlf.tlf-depends-list);
  end if;
end;

add-od-loader(*compiler-dispatcher*, #"define-binding-tlf",
              method (state :: <load-state>) => res :: <loaded-define-tlf>;
                let defn = load-object-dispatch(state);
                let deps = load-object-dispatch(state);
                assert-end-object(state);
                note-variable-definition(defn);
                defn.loaded-tlf;
              end);

// Seals for file tlf.dylan

// <define-class-tlf> -- subclass of <simple-define-tlf>
define sealed domain make(singleton(<define-class-tlf>));
define sealed domain initialize(<define-class-tlf>);
// <magic-internal-primitives-placeholder> -- subclass of <top-level-form>
define sealed domain make(singleton(<magic-internal-primitives-placeholder>));
define sealed domain initialize(<magic-internal-primitives-placeholder>);
// <tlf-dependency> -- subclass of <general-dependency>
define sealed domain make(singleton(<tlf-dependency>));
define sealed domain initialize(<tlf-dependency>);
