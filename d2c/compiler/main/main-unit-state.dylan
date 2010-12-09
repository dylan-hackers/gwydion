module: main
copyright: see below

//======================================================================
//
// Copyright (c) 1995, 1996, 1997  Carnegie Mellon University
// Copyright (c) 1998 - 2003  Gwydion Dylan Maintainers
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

// This should have some reasonable association with cback
// <unit-state> (but it doesn't.)
//

define class <main-unit-state> (<object>)
  constant slot unit-command-line-features :: <list>, 
    required-init-keyword: command-line-features:;
  constant slot unit-log-dependencies :: <boolean>, 
    required-init-keyword: log-dependencies:;
  constant slot unit-log-text-du :: <boolean>,
    required-init-keyword: log-text-du:;
  constant slot unit-target :: <platform>,
    required-init-keyword: target:;
  constant slot unit-no-binaries :: <boolean>,
    required-init-keyword: no-binaries:;
  constant slot unit-no-makefile :: <boolean>,
    required-init-keyword: no-makefile:;
  constant slot unit-link-static :: <boolean>,
    required-init-keyword: link-static:;
  constant slot unit-link-rpath :: false-or(<string>),
    required-init-keyword: link-rpath:;
  // Simplistic flags to control debugging (and someday, optimization).
  // We only have one of these right now.
  slot unit-debug? :: <boolean>, init-keyword: debug?:, init-value: #f;
  slot unit-profile? :: <boolean>, init-keyword: profile?:, init-value: #f;

  slot dump-testworks-spec? :: <boolean>,
    init-value: #f, init-keyword: dump-testworks-spec?:;

  slot unit-header :: <header>;
  constant slot unit-init-functions :: <stretchy-vector>
	= make(<stretchy-vector>);

  // how many threads do we want d2c to try to make use of
  constant slot unit-thread-count :: false-or(<integer>),
    init-keyword: thread-count:, init-value: #f;

  slot progress-indicator :: false-or(<progress-indicator>) = #f;

  slot unit-tlfs :: <stretchy-vector> = make(<stretchy-vector>);
end class <main-unit-state>;

// Find the library object file (archive) using the data-unit search path.
// There might be more than one possible object file suffix, so we try them
// all, but if we find it under more than one suffix, we error.
//
// If the platform supports shared libraries (as indicated by the presence
// of shared-library-filename-suffix in platforms.descr), and if the user
// didn't specify '-static' on the command line, locate shared library
// version first. 

define method find-library-archive
    (unit-name :: <byte-string>, state :: <main-unit-state>)
 => path :: <byte-string>;
  let target = state.unit-target;
  let libname = concatenate(target.library-filename-prefix, unit-name);
  let suffixes = split-at-whitespace(target.library-filename-suffix);

  let found = #();

  let find = method (suffixes)
	       let found = #();
               for (suffix in suffixes)
                 block (done)
                   for (dir :: <directory-locator> in *Data-Unit-Search-Path*)
                     let merged = make(<file-locator>,
                                       directory: dir, base: libname,
                                       extension: strip-dot(suffix));
                     if (file-exists?(merged))
                       found := add-new!(found, merged, test: \=);
                       done();
                     end if;
                   end for;
                 end block;
               end for;
	       found;
	     end method;

  if (target.shared-library-filename-suffix & ~state.unit-link-static)  
    let shared-suffixes
      = split-at-whitespace(target.shared-library-filename-suffix);
    found := find(shared-suffixes);
    if (empty?(found))
      found := find(suffixes);
    end if;
  else
    found := find(suffixes);
  end if;

  if (empty?(found))
    error("Can't find object file for library %s.", unit-name);
  elseif (found.tail ~== #())
    error("Found more than one type of object file for library %s:\n"
	  "  %=",
	  unit-name,
	  found);
  else
    as(<byte-string>, found.first);
  end if;
end method find-library-archive;


// FER conversion
define method compile-1-tlf
    (tlf :: <top-level-form>, state :: <main-unit-state>) 
 => ();
  let component = make(<fer-component>);
  tlf.tlf-component := component;
  let builder = make-builder(component);
  convert-top-level-form(builder, tlf);
  let inits = builder-result(builder);
  let name-obj = make(<anonymous-name>, location: tlf.source-location);
  unless (instance?(inits, <empty-region>))
    let result-type = make-values-ctype(#(), #f);
    let source = tlf.source-location;
    let init-function
      = build-function-body
          (builder, $Default-Policy, source, #f,
	   name-obj,
	   #(), result-type, #t);
    build-region(builder, inits);
    build-return
      (builder, $Default-Policy, source, init-function, #());
    end-body(builder);
    let sig = make(<signature>, specializers: #(), returns: result-type);
    let ctv = make(<ct-function>, name: name-obj, signature: sig);
    make-function-literal(builder, ctv, #"function", #"global",
			  sig, init-function);
    add!(state.unit-init-functions, ctv);
    tlf.tlf-init-function := ctv;
  end;
end method compile-1-tlf;

define method emit-1-tlf
    (tlf :: <top-level-form>, file :: <file-state>, 
     state :: <main-unit-state>) => ();
  emit-tlf-gunk(c: tlf, file);
  emit-component(c: tlf.tlf-component, file);
end method emit-1-tlf;

define constant $max-inits-per-function = 25;

define method emit-init-functions
    (prefix :: <byte-string>, init-functions :: <vector>,
     start :: <integer>, finish :: <integer>, stream :: <stream>)
    => body :: <byte-string>;
  let string-stream = make(<byte-string-stream>, direction: #"output");
  if (finish - start <= $max-inits-per-function)
    for (index from start below finish)
      let init-function = init-functions[index];
      let ep = make(<ct-entry-point>, for: init-function, kind: #"main");
      let name = ep.entry-point-c-name;
      format(stream, "extern void %s(descriptor_t *sp);\n\n", name);
      format(string-stream, "    %s(sp);\n", name);
    end for;
  else
    for (divisions = finish - start
	   then ceiling/(divisions, $max-inits-per-function),
	 while: divisions > $max-inits-per-function)
    finally
      for (divisions from divisions above 0 by -1)
	let count = ceiling/(finish - start, divisions);
	let name = format-to-string("%s_init_%d_%d",
				    prefix, start, start + count - 1);
	let guts = emit-init-functions(prefix, init-functions,
				       start, start + count, stream);
	format(stream, "static void %s(descriptor_t *sp)\n{\n%s}\n\n",
	       name, guts);
	format(string-stream, "    %s(sp);\n", name);
	start := start + count;
      end for;
    end for;
  end if;
  string-stream.stream-contents;
end method emit-init-functions;

define method build-unit-init-function
    (prefix :: <byte-string>, init-functions :: <vector>,
     stream :: <stream>)
    => ();
  let init-func-guts = emit-init-functions(string-to-c-name(prefix), init-functions,
					   0, init-functions.size, stream);
  // The function this generated used to be called simply "%s_init",
  // but that conflicted with the heap object of the same name.  (Of
  // course, on the HP, the linker has separate namespaces for code
  // and data, but most other platforms do not)
  format(stream, "void %s_Library_init(descriptor_t *sp)\n{\n%s}\n",
	 string-to-c-name(prefix), init-func-guts);
end;

define method build-command-line-entry
    (lib :: <library>, entry :: <byte-string>, file :: <file-state>)
    => entry-function :: <ct-function>;
  let (module-name, variable-name) = split-at-colon(entry);
  let module = find-module(lib, as(<symbol>, module-name));
  unless (module)
    compiler-fatal-error("Invalid entry point: %s -- no module %s.",
			 entry, module-name);
  end unless;
  let variable = find-variable(make(<basic-name>,
				    symbol: as(<symbol>, variable-name),
				    module: module));
  unless (variable)
    compiler-fatal-error
      ("Invalid entry point: %s -- no variable %s in module %s.",
       entry, variable-name, module-name);
  end unless;
  let defn = variable.variable-definition;
  unless (defn)
    compiler-fatal-error
      ("Invalid entry point: %s -- it isn't defined.", entry);
  end unless;

  let component = make(<fer-component>);
  let builder = make-builder(component);
  let source = make(<source-location>);
  let policy = $Default-Policy;
  let name = "Command Line Entry";
  let name-obj
    = make(<basic-name>, module: $dylan-module, symbol: #"command-line-entry");

  let int-type = specifier-type(#"<integer>");
  let rawptr-type = specifier-type(#"<raw-pointer>");
  let result-type = make-values-ctype(#(), #f);
  let argc = make-local-var(builder, #"argc", int-type);
  let argv = make-local-var(builder, #"argv", rawptr-type);
  let func
    = build-function-body
        (builder, policy, source, #f,
	 name-obj, list(argc, argv), result-type, #t); 

  let user-func = build-defn-ref(builder, policy, source, defn);
  // ### Should really spread the arguments out, but I'm lazy.
  build-assignment(builder, policy, source, #(),
		   make-unknown-call(builder, user-func, #f,
				     list(argc, argv)));
  build-return(builder, policy, source, func, #());
  end-body(builder);
  let sig = make(<signature>, specializers: list(int-type, rawptr-type),
		 returns: result-type);
  let ctv = make(<ct-function>, name: name-obj, signature: sig);
  make-function-literal(builder, ctv, #"function", #"global", sig, func);
  optimize-component(*current-optimizer*, component);
  emit-component(c: component, file);
  ctv;
end method build-command-line-entry;

define method finalize-library(state :: <main-unit-state>) => ()
  format(*debug-output*, "Finalizing library.\n");
  seed-representations();
  for (tlf in copy-sequence(state.unit-tlfs))
    note-context(tlf);
    finalize-top-level-form(tlf);
    end-of-context();
  end for;
  inherit-slots();
  inherit-overrides();
  begin
    let unique-id-base 
      = element(state.unit-header, #"unique-id-base", default: #f);
    if (unique-id-base)
      assign-unique-ids(string-to-integer(unique-id-base));
    end;
  end;
  layout-instance-slots();
end method finalize-library;

define method run-stage(message :: <string>, func :: <function>, 
                        tlfs :: <collection>) => ()
  format(*debug-output*, "%s\n", message);
  let progress-indicator = make(<n-of-k-progress-indicator>,
                                total: tlfs.size,
                                stream: *debug-output*);
  for (tlf in tlfs)
    block ()
      let name = format-to-string("%s", tlf);
      increment-and-report-progress(progress-indicator);
      note-context(name);
      func(tlf);
    cleanup
      end-of-context();
    exception (<fatal-error-recovery-restart>)
      #f;
    end block;
  end for;
end method run-stage;


define variable *Current-Library* :: false-or(<library>) = #f;
define variable *Current-Module* :: false-or(<module>) = #f;

