module: dylan-user

define library pidgin
  use common-dylan;
  use collection-extensions;
  use io;
  use system;
  use dylan;
  use string-extensions;
  use command-line-parser;
  use parser-utilities;
  use ansi-c;
  use c-parser;
  use c-ffi-output;
end library;

define module pidgin
  use common-dylan, exclude: { format-to-string };
  use format-out;
  use dylan;
  use streams;
  use file-system;
  use locators;
  use format;
  use standard-io;
  use command-line-parser;
  use substring-search;
  use subseq;
  use parse-conditions;
  use ansi-c;
  use c-parser;
  use c-ffi-output;
end module;
