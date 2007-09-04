module: dylan-user

define library refman
  use common-dylan,
    import: { common-dylan };
  use string-extensions,
    import: { substring-search };
  use io,
    import: { format, format-out, standard-io, streams };
  use command-line-parser,
    import: { command-line-parser };
  use system,
    import: { locators };
  
  // Compiler internal
  // These libraries need to be used to initialize loaders for various ODF
  // tags, but for the most part, we don't need to use any of their bindings.
  use compiler-base;
  use compiler-front;
  use compiler-optimize;
  use compiler-cback;
  use compiler-main-du;
  use compiler-convert;
  use compiler-parser;
  // use compiler-fer-transform;
end library;

define module refman
  use common-dylan,
    exclude: { format-to-string, direct-superclasses, direct-subclasses };
  use substring-search;
  use command-line-parser;
  use standard-io;
  use format;
  use format-out;
  use streams;
  use locators;
  
  // Compiler internal
  // We need to use bindings from these modules.
  use common,
    import: { *debug-output* };
  use od-format,
    import: { *data-unit-search-path* };
  use variables;
  use definitions;
  use names;
  use function-definitions;
  use variable-definitions;
  use signature-interface;
  use define-constants-and-variables;
  use define-classes;
  use ctype;
  use classes;
  use macros;
  use compile-time-values;
  use main-constants;
  use platform;
  use platform-constants;
end module;
