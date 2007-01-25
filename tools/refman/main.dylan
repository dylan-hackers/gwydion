synopsis:  This code performs set-up and includes main().
author:    Dustin Voss
copyright: © 2007 Dustin Voss
module:    refman


/// Arguments

define argument-parser <my-arg-parser> ()
  regular-arguments libnames;
  option help?, "", "Help", long: "help", short: "h";
  option libpaths, "", "Library paths", long: "libdir", short: "L",
    kind: <repeated-parameter-option-parser>;
  synopsis print-help,
    usage: "refman [options] libnames...",
    description:
"Export a library or libraries to a refman-style XML document, sent to STDOUT."
"\n"
"libnames are library names (as in libname.lib.du).";
end argument-parser;


/// Main

// Load requested libraries and kick off the process.
define function main(name, arguments)

  // Check arguments
  let args = make(<my-arg-parser>);
  parse-arguments(args, arguments);
  if (args.help? | args.libnames.empty?)
    print-help(args, *standard-output*);
    exit-application(0);
  end;

  // Set up library search path if not specified.
  let lib-paths =
      if (args.libpaths.empty?)
        list(".",
             concatenate($default-dylan-user-dir, "/lib/dylan/",
               $version, "/", $default-target-name, "/dylan-user"),
             concatenate($default-dylan-dir, "/lib/dylan/", $version, "/", 
               $default-target-name));
      else
        args.libpaths;
      end;
  *data-unit-search-path* := map(curry(as, <directory-locator>), lib-paths);

  // Prevent d2c from using stdout.
  *debug-output* := make(<string-stream>, direction: #"output");

  // Load libraries of interest.
  let target-libraries = map(curry(as, <symbol>), args.libnames);
  for (name in target-libraries)
    block()
      let lib = find-library(name, create: #t);
      assure-loaded(lib);
    exception (cond :: <format-string-condition>)
      apply(format, *standard-error*, cond.condition-format-string,
          cond.condition-format-arguments);
      format(*standard-error*, "\n");
      exit-application(1);
    exception (cond :: <condition>)
      format(*standard-error*, "Failed to load library %s:\n%s\n",
          name, cond);
      exit-application(1);
    end;
  end;

  // Print out the XML.
  format-out("%s\n", refman($Libraries, target-libraries));
  exit-application(0);
end function main;


// Invoke our main() function.
main(application-name(), application-arguments());
