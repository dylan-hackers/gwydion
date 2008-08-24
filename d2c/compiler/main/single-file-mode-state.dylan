module: main
copyright: see below

//======================================================================
//
// Copyright (c) 1995, 1996, 1997  Carnegie Mellon University
// Copyright (c) 1998, 1999, 2000, 2001, 2002  Gwydion Dylan Maintainers
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

define class <single-file-mode-state> (<main-unit-state>)
  slot unit-source-locator :: <file-locator>,
    required-init-keyword: source-locator:;
  
  slot unit-name :: <byte-string>; // for single files, name == module == library == executable
  slot unit-lib :: <library>;

  slot unit-mprefix :: <byte-string>;
  slot unit-modules :: <stretchy-vector> = make(<stretchy-vector>);
  slot unit-cback-unit :: <unit-state>;
  slot unit-other-cback-units :: <simple-object-vector>;
  
  slot unit-entry-function :: false-or(<ct-function>), init-value: #f;
  slot unit-unit-info :: <unit-info>;
  slot unit-c-file :: false-or(<file-state>) = #f;
  slot unit-stream = #f;
end class <single-file-mode-state>;

define method parse-and-finalize-library (state :: <single-file-mode-state>) => ();
  let source = make(<source-file>, locator: state.unit-source-locator);
  let (header, start-line, start-posn) = parse-header(source);

  state.unit-header := header;

  do(process-feature,
     state.unit-target.default-features);
  do(process-feature,
     split-at-whitespace(element(state.unit-header, #"features",
                                 default: "")));
  do(process-feature, state.unit-command-line-features);
  
  let lib-name = state.unit-header[#"module"];
  state.unit-name := lib-name;
  format(*debug-output*, "Compiling library %s\n", lib-name);
  state.unit-lib := find-library(as(<symbol>, lib-name), create: #t);

  // Handle a very simple form of "-exports" logic in single-file-mode.
  // To wit:  If the .dylan file contains the entries "use-libraries:" 
  // and "use-modules:", then load these libraries and modules in preference
  // to the hard-coded values in this file.
  //
  // You must have both lines, or neither.  You can't have one without
  // the other.  Entries in each line must be comma-separated.
  //
  // Example:
  //   use-libraries:  common-dylan, io
  //   use-modules:  common-dylan, format-out
  //
  local method build-export-list(list-data :: <byte-string>)
                => result :: <byte-string>;
    let list-head :: <byte-string> = "";
    for (val in split-at(method (x :: <character>) x = ',' end, list-data))
      list-head := concatenate(list-head, format-to-string(" use %s; ", val));
    end for;
    list-head := concatenate(list-head, "end; ");
  end method build-export-list;

  let lib-string = format-to-string("define library %s ", lib-name);
  let mod-string = format-to-string("define module %s ", lib-name);
  let lib-list :: false-or(<byte-string>) =
    element(state.unit-header, #"use-libraries", default: #f);
  let mod-list :: false-or(<byte-string>) =
    element(state.unit-header, #"use-modules", default: #f);

  if (lib-list)
    format(*debug-output*, "Using custom library import list...\n");
    lib-string := concatenate(lib-string, build-export-list(lib-list));
  else
    lib-string := concatenate(lib-string, format-to-string("use common-dylan; use io; end; "));
  end if;

  if (mod-list)
    mod-string := concatenate(mod-string, build-export-list(mod-list));
  else
    mod-string := concatenate(mod-string, format-to-string("use common-dylan; use format-out; end; "));
  end if;
    
  let libmod-declaration
    = format-to-string("%s %s\n\n", lib-string, mod-string);
  let libmod-buffer = make(<buffer>, size: libmod-declaration.size);
  copy-bytes(libmod-buffer, 0, libmod-declaration, 0, libmod-declaration.size);

  // XXX these two look suspicious
  // second one is ok, default is now according to DRM
  *defn-dynamic-default* := boolean-header-element(#"dynamic", #f, state);
  *implicitly-define-next-method*
    := boolean-header-element(#"implicitly-define-next-method", #t, state);

  state.unit-mprefix := as-lowercase(lib-name);

  block ()
    let module = find-module(state.unit-lib, as(<symbol>, "dylan-user"));
    let tokenizer = make(<lexer>,
                         module: module,
                         source: make(<source-buffer>, 
                                      buffer: libmod-buffer),
                         start-line: 0,
                         start-posn: 0);
    *Top-Level-Forms* := state.unit-tlfs;
    parse-source-record(tokenizer);
  exception (<fatal-error-recovery-restart>)
    format(*debug-output*, "skipping rest of built-in init definition\n");
  end block;


  let mod = find-module(state.unit-lib, as(<symbol>, lib-name));

  format(*debug-output*, "Parsing %s\n", state.unit-source-locator);
  block ()
    let tokenizer = make(<lexer>, 
                         module: mod,
                         source: source,
                         start-line: start-line,
                         start-posn: start-posn);
    *Top-Level-Forms* := state.unit-tlfs;
    parse-source-record(tokenizer);
  exception (<fatal-error-recovery-restart>)
    format(*debug-output*, "skipping rest of %s\n", state.unit-source-locator);
  end block;

  finalize-library(state);
end method parse-and-finalize-library;

define method compile-file (state :: <single-file-mode-state>) => ();
  let tlfs = state.unit-tlfs;

  run-stage("Converting top level forms.",
            method(tlf)
                compile-1-tlf(tlf, state);
            end method, tlfs);
  
  run-stage("Optimizing top level forms.",
            method(tlf)
                optimize-component(*current-optimizer*, tlf.tlf-component);
            end method, tlfs);

  let c-name = concatenate(state.unit-name, ".c");
  let body-stream
     = make(<file-stream>, locator: c-name, direction: #"output");
  let file = make(<file-state>, unit: state.unit-cback-unit,
                     body-stream: body-stream, single-file-mode?: #t);
  state.unit-c-file := file;
  state.unit-stream := body-stream;
  emit-prologue(file, state.unit-other-cback-units);

  run-stage("Emitting C code.",
            method(tlf)
                emit-1-tlf(tlf, file, state);
            end method, tlfs);
end method compile-file;


// Build initialization function for this library, generate the corresponding
// .c and .o and update the make file.
// 
define method build-library-inits (state :: <single-file-mode-state>) => ();
  build-unit-init-function(state.unit-mprefix, state.unit-init-functions,
                           state.unit-stream);
end method build-library-inits;

define method build-local-heap-file (state :: <single-file-mode-state>) => ();
  format(*debug-output*, "Emitting Library Heap.\n");
  let prefix = state.unit-cback-unit.unit-prefix;
  let (undumped, extra-labels) = build-local-heap(state.unit-cback-unit, 
                                                  state.unit-c-file);
  let linker-options = element(state.unit-header, #"linker-options", 
                               default: #f);
  state.unit-unit-info := make(<unit-info>, unit-name: state.unit-mprefix,
                               undumped-objects: undumped,
                               extra-labels: extra-labels,
                               linker-options: linker-options);
end method build-local-heap-file;

define method build-da-global-heap (state :: <single-file-mode-state>) => ();
  format(*debug-output*, "Emitting Global Heap.\n");
  build-global-heap(apply(concatenate, map(undumped-objects, *units*)),
                    state.unit-c-file);
end method;


define method build-inits-dot-c (state :: <single-file-mode-state>) => ();
  format(*debug-output*, "Building inits.\n");
  let stream = state.unit-stream;
  format(stream, "#include <stdlib.h>\n\n");
  format(stream,
         "void inits(descriptor_t *sp, int argc, char *argv[])\n{\n");
  for (unit in *units*)
    format(stream, "{ extern void %s_Library_init(descriptor_t*);  %s_Library_init(sp); }\n",
    string-to-c-name(unit.unit-info-name), string-to-c-name(unit.unit-info-name));
  end;
  format(stream, "}\n");
  format(stream, "\nextern void real_main(int argc, char *argv[]);\n\n");
  format(stream, "int main(int argc, char *argv[]) {\n");
  format(stream, "    real_main(argc, argv);\n");
  format(stream, "    exit(0);\n");
  format(stream, "    return(0);\n");
  format(stream, "}\n");
end method;

define method build-executable (state :: <single-file-mode-state>) => ();
  let target = state.unit-target;
  let unit-libs = "";
  let dash-small-ells = "";
  let linker-args = concatenate(" ", target.link-executable-flags);
  if(state.unit-profile? & target.link-profile-flags)
    linker-args := concatenate(linker-args, " ", target.link-profile-flags);
  end if;
  if(state.unit-debug? & target.link-debug-flags)
    linker-args := concatenate(linker-args, " ", target.link-debug-flags);
  end if;

  local method add-archive (name :: <byte-string>) => ();
          let archive = find-library-archive(name, state);
          unit-libs := stringify(' ', archive, unit-libs);
        end method add-archive;

  // Under Unix, the order of the libraries is significant!  First to
  // be added go at the end of the command line...
  add-archive("runtime");

  for (unit in *units*)
    if (unit.unit-linker-options)
      linker-args
        := stringify(' ', unit.unit-linker-options, linker-args);
    end if;
    unless (unit == state.unit-unit-info)
      add-archive(concatenate(unit.unit-info-name, "-dylan"));
    end unless;
  end;

  let cc-flags
    = getenv("CCFLAGS") 
    | format-to-string(if (state.unit-profile?)
                         state.unit-target.default-c-compiler-profile-flags;
                       elseif (state.unit-debug?)
                         state.unit-target.default-c-compiler-debug-flags;
                       else
                         state.unit-target.default-c-compiler-flags;
                       end if,
                       $runtime-include-dir);
  
  let cc-flags = concatenate(cc-flags, getenv("CCOPTS")|"");

  let libtool = getenv("LIBTOOL") | state.unit-target.libtool-command;

  let unit-libs = use-correct-path-separator(unit-libs, state.unit-target);

  let objects = format-to-string("%s%s %s", state.unit-name, state.unit-target.object-filename-suffix, unit-libs);

  let compile-string
    = format-to-string(state.unit-target.compile-c-command,
                       concatenate(state.unit-name, ".c"),
                       concatenate(state.unit-name,
                                   state.unit-target.object-filename-suffix));
  let compile-string
    = substring-replace(compile-string, "$(CCFLAGS)", cc-flags);
  let gc-libs = getenv("GC_LIBS") | $gc-libs;
  let linker-args
    = substring-replace(linker-args, "$(GC_LIBS)", gc-libs);

  close(state.unit-stream);
  state.unit-stream := #f;

  if (system(compile-string) ~== 0)
    cerror("so what", "gcc failed?");
  end if;

  let exec-name = concatenate(state.unit-name, state.unit-target.executable-filename-suffix);

  let link-string-intermediate
    = format-to-string(if(state.unit-link-static)
                         state.unit-target.link-executable-command
                       else
                         state.unit-target.link-shared-executable-command
                       end,
                       exec-name,
                       concatenate(objects, dash-small-ells," "),
                       linker-args);

  let link-string = if(libtool)
                      substring-replace(link-string-intermediate, "$(LIBTOOL)", libtool);
                    else
                      link-string-intermediate;
                    end if;

  if (system(link-string) ~== 0)
    cerror("so what", "gcc failed?");
  end if;

end method build-executable;


define method compile-library (state :: <single-file-mode-state>)
    => worked? :: <boolean>;
  block (give-up)
    // We don't really have to give-up if we don't want to, but it
    // seems kind of pointless to compile a file that doesn't parse,
    // or create a dump file for library with undefined variables.
    // Thus, we stick some calls to give-up where it seems useful..
    parse-and-finalize-library(state);
    if (~ zero?(*errors*)) give-up(); end if;
    state.unit-cback-unit := make(<unit-state>, prefix: state.unit-mprefix);
    state.unit-other-cback-units := map-as(<simple-object-vector>, unit-info-name, 
                                         *units*);
    compile-file(state);
    if (~ zero?(*errors*)) give-up(); end if;
    build-library-inits(state);
    build-local-heap-file(state);
    calculate-type-inclusion-matrix(); // Hmmm... move this to program startup time one day
    build-da-global-heap(state);
    build-inits-dot-c(state);
    state.unit-no-binaries
      | build-executable(state);
  cleanup
    if(state.unit-stream)
      close(state.unit-stream);
    end if;
    fresh-line(*debug-output*);
    *Current-Module* := #f;
  exception (<fatal-error-recovery-restart>)
    format(*debug-output*, "giving up.\n");
  end block;
  
  format(*debug-output*, "Optimize called %d times.\n", *optimize-ncalls*);

  if (state.unit-log-text-du)
    dump-text-du(state.unit-name,
                 concatenate(state.unit-mprefix, ".lib.du.txt"));
  end if;

  let worked? = zero?(*errors*);
  format(*debug-output*,
         "Compilation %s with %d Warning%s and %d Error%s\n",
         if (worked?) "finished" else "failed" end,
         *warnings*, if (*warnings* == 1) "" else "s" end,
         *errors*, if (*errors* == 1) "" else "s" end);

  worked?;
end method compile-library;

