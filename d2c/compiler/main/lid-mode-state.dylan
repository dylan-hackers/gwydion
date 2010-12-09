module: main
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

define class <lid-mode-state> (<main-unit-state>)
  slot unit-lid-locator :: <file-locator>, required-init-keyword: lid-locator:;
  
  // A facility for hacking around C compiler bugs by using a different
  // command for particular C compilations.  cc-override is a format string
  // used instead of the normal platform compile-c-command.  It is used
  // whenever compiling one of the files in the override-files list.
  slot unit-cc-override :: false-or(<string>),
    required-init-keyword: cc-override:;
  slot unit-override-files :: <list>,
    required-init-keyword: override-files:;
  
  slot unit-files :: <stretchy-vector>;
  slot unit-lib-name :: <byte-string>;
  slot unit-lib :: <library>;
  // unit-prefix already a <unit-state> accessor
  slot unit-mprefix :: <byte-string>;
  slot unit-cback-unit :: <unit-state>;
  slot unit-other-cback-units :: <simple-object-vector>;
  

  slot unit-shared? :: <boolean>, init-keyword: shared?:, init-value: #f;
  
  // Makefile generation streams, etc.
  slot unit-all-generated-files :: <list>, init-value: #();
  slot unit-makefile-name :: <byte-string>;
  slot unit-temp-makefile-name :: <byte-string>;
  slot unit-makefile :: <file-stream>;
  slot unit-objects-stream :: <byte-string-stream>;
  slot unit-clean-stream :: <byte-string-stream>;
  slot unit-real-clean-stream :: <byte-string-stream>;
  
  slot unit-entry-function :: false-or(<ct-function>), init-value: #f;
  slot unit-unit-info :: <unit-info>;
  
  // All names of the .o files we generated in a string.
  slot unit-objects :: <byte-string>;
  
  // The name of the .ar file we generated.
  slot unit-ar-name :: <byte-string>;

  // should this library be a complete embeddable Dylan application
  slot unit-embedded? :: <boolean> = #f;

  // The name of the executable file we generate.
  slot unit-executable :: false-or(<byte-string>);
end class <lid-mode-state>;

// Internal.  escape-pounds returns the string with any '#' characters
// converted to an escaped '\#' character combination for use in Makefiles.
define function escape-pounds (orig :: <string>) => result :: <string>;
  let result = make(<stretchy-vector>, size: orig.size);

  for (from-index :: <integer> from 0 below orig.size,
       to-index from 0)
    if (orig[from-index] == '#')
       result[to-index] := '\\';
       to-index := to-index + 1;
    end if;
    result[to-index] := orig[from-index];
  end for;
  as(<string>, result);
end function escape-pounds;

define method parse-lid (state :: <lid-mode-state>) => ();
  let source = make(<source-file>, locator: state.unit-lid-locator);
  let (header, start-line, start-posn) = parse-header(source);

  // We support two types of lid files: old "Gwydion LID" and new
  // "official LID". The Gwydion format had a series of file names after
  // the header; the new format has a 'Files:' keyword in the header. We
  // grab the keyword value, transform the filenames in a vaguely appropriate
  // fashion, and then grab anything in the body "as is". This handles both
  // formats. See translate-abstract-filename for details of the new format.
  let contents = source.contents;
  let end-posn = contents.size;

  // Common-Dylan header-file style
  let files = map-as(<stretchy-vector>,
                     translate-abstract-filename,
                     split-at-whitespace(element(header, #"files",
                                                 default: "")));

  let ofiles = split-at-whitespace(element(header, #"c-object-files",
                                           default: ""));

  local
    method repeat (posn :: <integer>)
      if (posn < end-posn)
        let char = as(<character>, contents[posn]);
        if (char.whitespace?)
          repeat(posn + 1);
        elseif (char == '/' & (posn + 1 < contents.size) 
                  & as(<character>, contents[posn + 1]) == '/')
          repeat(find-newline(contents, posn + 1));
        else
          let name-end = find-end-of-word(posn);
          let len = name-end - posn;
          let name = make(<byte-string>, size: len);
          copy-bytes(name, 0, contents, posn, len);
          add!(files, name);
          repeat(name-end);
        end;
      end;
    end,

    // find-end-of-word returns the position of the first character
    // after the word, where "end of word" is defined as whitespace.
    method find-end-of-word (posn :: <integer>)
     => end-of-word :: <integer>;
      if (posn < end-posn)
        let char = as(<character>, contents[posn]);
        if (char.whitespace?)
          posn;
        else
          find-end-of-word(posn + 1);
        end;
      else
        posn;
      end;
    end method;
 
  repeat(start-posn);

  state.unit-header := header;
  state.unit-files := map(curry(as, <file-locator>),
                          concatenate(files, ofiles));
  state.unit-executable := element(header, #"executable", default: #f);
  state.unit-embedded? := element(header, #"embedded?", default: #f) & #t;
end method parse-lid;

// save-c-file is #t when we don't want the .c file added to the
// real-clean target.  Used when the C file is actually source code,
// rather than the result of Dylan->C.
//
define method output-c-file-rule
    (state :: <lid-mode-state>, raw-c-name :: <string>, raw-o-name :: <string>,
     #key save-c-file = #f)
 => ();
  let c-name = escape-pounds(raw-c-name);
  let o-name = escape-pounds(raw-o-name);

  let cc-command
      = if (member?(c-name, state.unit-override-files, test: \=))
          state.unit-cc-override;
        elseif(state.unit-shared?
                 & state.unit-target.compile-c-for-shared-command)
          state.unit-target.compile-c-for-shared-command;
        else
          state.unit-target.compile-c-command;
        end if;


  format(state.unit-makefile, "%s : %s\n", o-name, c-name);
  format(state.unit-makefile, "\t%s\n",
         format-to-string(cc-command, c-name, o-name));
  format(state.unit-objects-stream, " %s", o-name);
  format(state.unit-clean-stream, " %s", o-name);
  format(state.unit-real-clean-stream, " %s", o-name);
  if (~save-c-file)
    format(state.unit-real-clean-stream, " %s", c-name);
  end if;
end method output-c-file-rule;

define method parse-and-finalize-library (state :: <lid-mode-state>) => ();
  parse-lid(state);
  do(process-feature,
     state.unit-target.default-features);
  do(process-feature,
     split-at-whitespace(element(state.unit-header, #"features",
                                 default: "")));
  do(process-feature, state.unit-command-line-features);
  
  let lib-name = state.unit-header[#"library"];
  state.unit-lib-name := lib-name;
  format(*debug-output*, "Compiling library %s\n", lib-name);
  let lib = find-library(as(<symbol>, lib-name), create: #t);
  state.unit-lib := lib;
  state.unit-mprefix := as-lowercase(lib-name);
  if(element(state.unit-header, #"unit-prefix", default: #f))
    format(*debug-output*, "Warning: unit-prefix header is deprecated, ignoring it.\n");
  end if;

  state.unit-shared?
    := ~state.unit-link-static
       & ~state.unit-executable
       & boolean-header-element(#"shared-library", #t, state)
       & state.unit-target.shared-library-filename-suffix
       & state.unit-target.shared-object-filename-suffix
       & state.unit-target.link-shared-library-command
       & #t;

  // XXX these two look suspicious
  // second one is ok, default is now according to DRM
  *defn-dynamic-default* := boolean-header-element(#"dynamic", #f, state);
  *implicitly-define-next-method*
    := boolean-header-element(#"implicitly-define-next-method", #t, state);

  let float-precision
    = element(state.unit-header, #"float-precision", default: #f);
  if (float-precision)
    select (as-uppercase(float-precision) by \=)
      "AUTO" => *float-precision* := #"auto";
      "SINGLE" => *float-precision* := #"single";
      "DOUBLE" => *float-precision* := #"double";
      "EXTENDED" => *float-precision* := #"extended";
      otherwise =>
        compiler-error("float-precision: header option is %s, not "
                         "\"auto\", \"single\", \"double\" or \"extended\".",
                       float-precision);
    end select;
  end if;

  *Top-Level-Forms* := state.unit-tlfs;

  for (file in state.unit-files)
    let extension = file.locator-extension;
    if (extension = strip-dot(state.unit-target.object-filename-suffix))
      unless (state.unit-no-makefile)
        let object-file
          = if (state.unit-shared?)
              make(<file-locator>,
                   directory: file.locator-directory,
                   base: file.locator-base,
                   extension: strip-dot(state.unit-target.shared-object-filename-suffix));
            else
              file
            end;
        let prefixed-filename
          = find-file(object-file,
                      vector($this-dir,
                             state.unit-lid-locator.locator-directory));
        log-dependency(prefixed-filename);
      end unless;
    else  // assumed a Dylan file, with or without a ".dylan" extension
      block ()
        format(*debug-output*, "Parsing %s\n", file);
        // ### prefixed-filename is now an absolute filename.  Previously we
        // used $this-dir, but that meant .du files contained library-relative
        // filenames, which didn't work when loaded elsewhere (i.e. always)
        let prefixed-filename
          = find-file(file,
                      vector(working-directory(),
                             state.unit-lid-locator.locator-directory));
        if (prefixed-filename == #f)
          compiler-fatal-error("Can't find source file %s.", file);
        end if;
        log-dependency(prefixed-filename);
        let (tokenizer, mod) = file-tokenizer(state.unit-lib, 
                                              prefixed-filename);
        parse-source-record(tokenizer);
      exception (<fatal-error-recovery-restart>)
        format(*debug-output*, "skipping rest of %s\n", file);
      end block;
    end if;
  end for;
  finalize-library(state);
end method parse-and-finalize-library;


// Open various streams used to build the makefiles that we generate to compile
// the C output code.
define method emit-make-prologue (state :: <lid-mode-state>) => ();
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

  cc-flags := concatenate(cc-flags, " ", getenv("CCOPTS")|"");

  state.unit-cback-unit := make(<unit-state>, prefix: state.unit-mprefix);
  state.unit-other-cback-units := map-as(<simple-object-vector>, unit-info-name, 
                                         *units*);

  let makefile-name = format-to-string("cc-%s-files.mak", state.unit-mprefix);
  let temp-makefile-name = concatenate(makefile-name, "-temp");
  state.unit-makefile-name := makefile-name;
  state.unit-temp-makefile-name := temp-makefile-name;

   unless (state.unit-no-makefile)
     format(*debug-output*, "Creating %s\n", makefile-name);
     let makefile = make(<file-stream>, locator: temp-makefile-name,
                         direction: #"output", if-exists: #"overwrite");
     state.unit-makefile := makefile;
     format(makefile, "# Makefile for compiling the .c and .s files\n");
     format(makefile, "# If you want to compile .dylan files, don't use "
              "this makefile.\n\n");
     format(makefile, "CCFLAGS = %s\n", cc-flags);
     let libtool = getenv("LIBTOOL") | state.unit-target.libtool-command;
     if (libtool)
       format(makefile, "LIBTOOL = %s\n", libtool);
     end;
     let gc-libs = getenv("GC_LIBS") | $gc-libs;
     format(makefile, "GC_LIBS = %s\n", gc-libs);   
     
     format(makefile, "# We only know the ultimate target when we've finished"
              " building the rest\n");
     format(makefile, "# of this makefile.  So we use this fake "
              "target...\n#\n");
     format(makefile, "all : all-at-end-of-file\n\n");
     
     // These next three streams gather filenames.  Objects-stream is
     // simply *.o.  clean-stream is the list of files we will delete
     // with the "clean" target--all objects plus the library archive
     // (.a), the library summary (.du), and the executable.
     // real-clean-stream is everything in clean plus *.c, *.s, and
     // cc-lib-files.mak.
     //
     state.unit-objects-stream
       := make(<byte-string-stream>, direction: #"output");
     state.unit-clean-stream
       := make(<byte-string-stream>, direction: #"output");
     state.unit-real-clean-stream
       := make(<byte-string-stream>, direction: #"output");
     format(state.unit-real-clean-stream, " %s", makefile-name);
   end;
 end method emit-make-prologue;

// Establish various condition handlers while iterating over all of the source
// files and compiling each of them to an output file.
//
define method compile-all-files (state :: <lid-mode-state>) => ();
  for (file in state.unit-files)
    let extension = file.locator-extension;
    if (extension = strip-dot(state.unit-target.object-filename-suffix))
      unless (state.unit-no-makefile)
        if (state.unit-shared?)
          let shared-file
            = make(<file-locator>,
                   directory: file.locator-directory,
                   name: file.locator-base,
                   extension: strip-dot(state.unit-target.shared-object-filename-suffix));
          format(*debug-output*, "Adding %s\n", shared-file);
          format(state.unit-objects-stream, " %s", shared-file);
        else
          format(*debug-output*, "Adding %s\n", file);
          format(state.unit-objects-stream, " %s", file);
        end;
      end unless;
    end if;
  end for;
  block ()
    let tlfs = state.unit-tlfs;

    run-stage("Converting top level forms.",
              method(tlf)
                  compile-1-tlf(tlf, state);
              end method, tlfs);
                  
    run-stage("Optimizing top level forms.",
              method(tlf)
                  optimize-component(*current-optimizer*, tlf.tlf-component);
              end method, tlfs);
    
    do-with-c-file(state, concatenate(state.unit-mprefix, "-guts"), 
                   method(body-stream)
                       let file = make(<file-state>, 
                                       unit: state.unit-cback-unit,
                                       body-stream: body-stream);
                       emit-prologue(file, state.unit-other-cback-units);

                       run-stage("Emitting C code.",
                                 method(tlf)
                                     emit-1-tlf(tlf, file, state);
                                 end method, tlfs);
                   end method);

  exception (<fatal-error-recovery-restart>)
    format(*debug-output*, "skipping rest of library.\n");
  exception (<simple-restart>,
               init-arguments:
               vector(format-string: "Blow off compiling this file."))
    #f;
  end block;
end method compile-all-files;


// Build initialization function for this library, generate the corresponding
// .c and .o and update the make file.
// 
define method build-library-inits (state :: <lid-mode-state>) => ();
    let executable
     = if (state.unit-executable)
         concatenate(state.unit-executable, state.unit-target.executable-filename-suffix);
       else 
         #f;
       end if;
    state.unit-executable := executable;
    let entry-point = element(state.unit-header, #"entry-point", default: #f);
    if (entry-point & ~executable)
      compiler-fatal-error("Can only specify an entry-point when producing an "
                             "executable.");
    end if;

  do-with-c-file(state, concatenate(state.unit-mprefix, "-init"),
                 method(body-stream)
                     let file = make(<file-state>, unit: state.unit-cback-unit,
                                     body-stream: body-stream);
                     emit-prologue(file, state.unit-other-cback-units);
                     if (entry-point)
                       state.unit-entry-function
                         := build-command-line-entry
                         (state.unit-lib, entry-point, file);
                     end if;
                     build-unit-init-function
                     (state.unit-mprefix, state.unit-init-functions,
                      body-stream);
                 end);
end method build-library-inits;

define method do-with-c-file(state :: <lid-mode-state>,
                             base-name :: <string>,
                             emitter :: <function>) => ();
  let c-name = concatenate(base-name, ".c");
  let temp-c-name = concatenate(c-name, "-temp");
  let body-stream = make(<file-stream>, 
                         locator: temp-c-name, direction: #"output");

  block()
    emitter(body-stream);
  cleanup
    close(body-stream);
  end block;

  pick-which-file(c-name, temp-c-name, state.unit-target);
  let o-name
    = concatenate(base-name, 
                  if (state.unit-shared?)
                    state.unit-target.shared-object-filename-suffix
                  else
                    state.unit-target.object-filename-suffix
                  end if);
  unless (state.unit-no-makefile)
    output-c-file-rule(state, c-name, o-name);
  end;
  state.unit-all-generated-files 
    := add!(state.unit-all-generated-files, c-name);
end;

                

define method build-local-heap-file (state :: <lid-mode-state>) => ();
  format(*debug-output*, "Emitting Library Heap.\n");
  do-with-c-file(state, concatenate(state.unit-mprefix, "-heap"),
                 method(body-stream)
                     let prefix = state.unit-cback-unit.unit-prefix;
                     let heap-state = make(<local-heap-file-state>, 
                                           unit: state.unit-cback-unit,
                                           body-stream: body-stream, 
                                           // target: state.unit-target,
                                           id-prefix: stringify(prefix, "_L"));

                     let (undumped, extra-labels) 
                       = build-local-heap(state.unit-cback-unit, 
                                          heap-state);
                     let linker-options 
                       = element(state.unit-header, #"linker-options", 
                                 default: #f);
                     state.unit-unit-info 
                       := make(<unit-info>, unit-name: state.unit-mprefix,
                               undumped-objects: undumped,
                               extra-labels: extra-labels,
                               linker-options: linker-options);
                 end method);
end method build-local-heap-file;


define method build-ar-file (state :: <lid-mode-state>) => ();
  let objects = stream-contents(state.unit-objects-stream);
  let target = state.unit-target;
  let suffix = split-at-whitespace(if (state.unit-shared?) 
                                     target.shared-library-filename-suffix;
                                   else
                                     target.library-filename-suffix;
                                   end if).first;
  let ar-name = concatenate(target.library-filename-prefix,
                            state.unit-mprefix,
                            "-dylan",
                            suffix);

  state.unit-objects := objects;
  state.unit-ar-name := ar-name;
  format(state.unit-makefile, "\n%s : %s\n", ar-name, objects);
  format(state.unit-makefile, "\t%s %s\n",
         target.delete-file-command, ar-name);
  
  let objects = use-correct-path-separator(objects, target);

  let link-string = if (state.unit-shared?)
                      format-to-string(target.link-shared-library-command,
                                       ar-name, objects,
                                       state.unit-link-rpath);
                    else
                      format-to-string(target.link-library-command,
                                       ar-name, objects);
                    end;

  if (state.unit-embedded?)
    if (state.unit-shared?)
      link-string := concatenate(link-string, link-arguments(state));
    else
      let link-string-file = make(<file-stream>,
                                  locator: 
                                    concatenate(target.library-filename-prefix,
                                                state.unit-mprefix,
                                                "-dylan.lnk"),
                                  direction: #"output");
      format(link-string-file, "%s", link-arguments(state));
      close(link-string-file);
    end if;
  elseif (state.unit-shared?)
    if(state.unit-profile? & target.link-profile-flags)
      link-string := concatenate(link-string, " ", target.link-profile-flags);
    end if;
    if(state.unit-debug? & target.link-debug-flags)
      link-string := concatenate(link-string, " ", target.link-debug-flags);
    end if;
  end if;

  format(state.unit-makefile, "\t%s\n", link-string);
  
  if (target.randomize-library-command & ~state.unit-shared?)
    let randomize-string = format-to-string(target.randomize-library-command,
                                            ar-name);
    format(state.unit-makefile, "\t%s\n", randomize-string);
  end if;

  format(state.unit-clean-stream, " %s", state.unit-ar-name);
  format(state.unit-real-clean-stream, " %s", state.unit-ar-name);
  format(state.unit-makefile, "\nall-at-end-of-file : %s\n", 
         state.unit-ar-name);
end method build-ar-file;


define method build-da-global-heap (state :: <lid-mode-state>) => ();
  format(*debug-output*, "Emitting Global Heap.\n");
  do-with-c-file(state, concatenate(state.unit-mprefix, "-global-heap"),
                 method(heap-stream)
                     let heap-state = make(<global-heap-file-state>, 
                                           unit: state.unit-cback-unit,
                                           body-stream: heap-stream); 
                     //, target: state.unit-target);
                     build-global-heap(apply(concatenate, 
                                             map(undumped-objects, *units*)),
                                       heap-state);
                 end method);
end method;


define method build-inits-dot-c (state :: <lid-mode-state>) => ();
  format(*debug-output*, "Building inits.c.\n");
  do-with-c-file(state, concatenate(state.unit-mprefix, "-global-inits"),
                 method(stream)
                     format(stream, "#include \"runtime.h\"\n");
                     format(stream, "#include <stdlib.h>\n\n");
                     format(stream, 
                            "/* This file is machine generated.  Do not edit. */\n\n");
                     let entry-function-name
                     = (state.unit-entry-function
                          & (make(<ct-entry-point>, 
                                  for: state.unit-entry-function,
                                  kind: #"main")
                               .entry-point-c-name));
                     if (entry-function-name)
                       format(stream,
                              "extern void %s(descriptor_t *sp, int argc, void *argv);\n\n",
                              entry-function-name);
                     end if;
                     format(stream,
                            "void inits(descriptor_t *sp, int argc, char *argv[])\n{\n");
                     for (unit in *units*)
                       format(stream, 
                              "{ extern void %s_Library_init(descriptor_t*);  %s_Library_init(sp); }\n", 
                              string-to-c-name(unit.unit-info-name), string-to-c-name(unit.unit-info-name));
                     end;
                     if (entry-function-name)
                       format(stream, 
                              "    %s(sp, argc, argv);\n", 
                              entry-function-name);
                     end if;
                     format(stream, "}\n");
                     if(~state.unit-embedded?)
                       format(stream, "\nextern void real_main(int argc, char *argv[]);\n\n");
                       format(stream, "int main(int argc, char *argv[]) {\n");
                       format(stream, "    real_main(argc, argv);\n");
                       format(stream, "    exit(0);\n");
                       format(stream, "    return(0);\n");
                       format(stream, "}\n");
                     end if;
                 end method);
end method;

define method link-arguments (state :: <lid-mode-state>) 
 => (arguments :: <string>)
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
          if (state.unit-no-binaries)
            // If cross-compiling use -l -L search mechanism.
            dash-small-ells := stringify(" -l", name, dash-small-ells);
          else
            let archive = find-library-archive(name, state);
            unit-libs := stringify(' ', archive, unit-libs);
          end if;
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

  let dash-cap-ells = "";
  // If cross-compiling, throw in a bunch of -Ls that will probably help.
  if (state.unit-no-binaries)
    for (dir in *data-unit-search-path*)
      dash-cap-ells := concatenate(dash-cap-ells,
                                   " -L", as(<byte-string>, dir));
    end for;
    dash-cap-ells
      := concatenate(" $(LDFLAGS)",
                     use-correct-path-separator(dash-cap-ells,
                                                state.unit-target),
                     " ");                                              

  end;

  let unit-libs = use-correct-path-separator(unit-libs, state.unit-target);

  concatenate(unit-libs, dash-cap-ells, dash-small-ells, " ", linker-args)
end method link-arguments;

define function library-dependencies (state :: <lid-mode-state>) 
 => (deps :: <string>)
  let target = state.unit-target;
  let unit-libs = "";

  local method add-archive (name :: <byte-string>) => ();
          unless (state.unit-no-binaries)
            let archive = find-library-archive(name, state);
            unit-libs := stringify(' ', archive, unit-libs);
          end unless;
        end method add-archive;

  for (unit in *units*)
    unless (unit == state.unit-unit-info)
      add-archive(concatenate(unit.unit-info-name, "-dylan"));
    end unless;
  end;

  add-archive("runtime");

  use-correct-path-separator(unit-libs, state.unit-target);
end function library-dependencies;


define method build-executable (state :: <lid-mode-state>) => ();
  let target = state.unit-target;
  let objects = stream-contents(state.unit-objects-stream);
  state.unit-objects := objects;

  // rule to link executable
  format(state.unit-makefile, "\n%s : %s%s\n", 
         state.unit-executable, state.unit-objects, state.library-dependencies);
  let link-string
    = format-to-string(if(state.unit-link-static)
                         state.unit-target.link-executable-command
                       else
                         state.unit-target.link-shared-executable-command
                       end,
                       state.unit-executable,
                       objects,
                       link-arguments(state));
  format(state.unit-makefile, "\t%s\n", link-string);

  format(state.unit-clean-stream, " %s", state.unit-executable);
  format(state.unit-real-clean-stream, " %s", state.unit-executable);
  format(state.unit-makefile, "\nall-at-end-of-file : %s\n", 
         state.unit-executable);
end method build-executable;


define method dump-library-summary (state :: <lid-mode-state>) => ();
  let dump-buf
    = begin-dumping(as(<symbol>, state.unit-lib-name),
                    $library-summary-unit-type);

  run-stage("Dumping library summary.", rcurry(dump-od, dump-buf),
            state.unit-tlfs);
  dump-od(state.unit-unit-info, dump-buf);
  dump-queued-methods(dump-buf);

  end-dumping(dump-buf);
  unless (state.unit-no-makefile)
    format(state.unit-real-clean-stream, " %s.lib.du",
           as-lowercase(state.unit-lib-name));
  end;
end method;


define method do-make (state :: <lid-mode-state>) => ();
  let target = state.unit-target;
  format(state.unit-makefile, "\nclean :\n");
  format(state.unit-makefile, "\t%s %s\n", target.delete-file-command, 
         state.unit-clean-stream.stream-contents);
  format(state.unit-makefile, "\nrealclean :\n");
  format(state.unit-makefile, "\t%s %s\n", target.delete-file-command, 
         state.unit-real-clean-stream.stream-contents);
  close(state.unit-makefile);

  if (pick-which-file(state.unit-makefile-name,
                      state.unit-temp-makefile-name,
                      target)
        = #t)
    // If the new makefile is different from the old one, then we need
    // to recompile all .c and .s files, regardless of whether they
    // were changed.  So touch them to make them look newer than the
    // object files.
    unless (empty?(state.unit-all-generated-files))
      let touch-command = "touch";
      for (filename in state.unit-all-generated-files)
        touch-command := stringify(touch-command, ' ', filename);
      end for;
      format(*debug-output*, "%s\n", touch-command);
      if (system(touch-command) ~== 0)
        cerror("so what", "touch failed?");
      end if;
    end unless;
  end if;

  if (~state.unit-no-binaries)
    let jobs-string = if((target.make-jobs-flag ~= "#f") & state.unit-thread-count)
                        format-to-string(" %s %d", target.make-jobs-flag,
                                         state.unit-thread-count);
                      else
                        "";
                      end;
    let make-string = format-to-string("%s%s -f %s", target.make-command, 
                                       jobs-string, state.unit-makefile-name);
    format(*debug-output*, "%s\n", make-string);
    unless (zero?(system(make-string)))
      cerror("so what", "gmake failed?");
    end;
  end if;
end method do-make;


define method compile-library (state :: <lid-mode-state>)
    => worked? :: <boolean>;
  block (give-up)
    // We don't really have to give-up if we don't want to, but it
    // seems kind of pointless to compile a file that doesn't parse,
    // or create a dump file for library with undefined variables.
    // Thus, we stick some calls to give-up where it seems useful..
    parse-and-finalize-library(state);
    *errors*.zero? | give-up();
    emit-make-prologue(state);
    compile-all-files(state);
    *errors*.zero? | give-up();
    build-library-inits(state);
    build-local-heap-file(state);
    if (state.unit-executable | state.unit-embedded?)
      calculate-type-inclusion-matrix();
      build-da-global-heap(state);
      build-inits-dot-c(state);
    end if;
    if (state.unit-executable)
      unless (state.unit-no-makefile)
        log-target(state.unit-executable);
        build-executable(state);
      end;
    else
      unless (state.unit-no-makefile)
        build-ar-file(state);
      end;
    end if;
    dump-library-summary(state);

    if (state.unit-log-text-du)
      dump-text-du(state.unit-lib-name,
                   concatenate(state.unit-mprefix, ".lib.du.txt"));
    end if;

    if (state.unit-log-dependencies)
      spew-dependency-log(concatenate(state.unit-mprefix, ".dep"));
    end if;
    
    unless (state.unit-no-makefile)
      do-make(state);
    end;

    if (state.dump-testworks-spec?)
      do-dump-testworks-spec(state);
    end if;

  exception (<fatal-error-recovery-restart>)
    format(*debug-output*, "giving up.\n");
  end block;
  
  format(*debug-output*, "Optimize called %d times.\n", *optimize-ncalls*);

  let worked? = zero?(*errors*);
  format(*debug-output*,
         "Compilation %s with %d Warning%s and %d Error%s\n",
         if (worked?) "finished" else "failed" end,
         *warnings*, if (*warnings* == 1) "" else "s" end,
         *errors*, if (*errors* == 1) "" else "s" end);

  worked?;
end method compile-library;

