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

define library compiler-main
  use Dylan;
  use Common-Dylan;
  use IO;
  use Stream-extensions,
     import: {indenting-streams};
  use System;
  use String-extensions;
  use Random;
  use debugger;
  use command-processor;
  use command-line-parser;
  use compiler-base;
  use compiler-front;
  use compiler-fer-transform;
  use compiler-optimize;
  use compiler-parser;
  use compiler-cback;
  use compiler-convert;
  use compiler-main-du;
end;

define module progress-indicator
  use dylan;
  use streams;
  use format;
  use utils;
  use System, 
     import: {get-time-of-day};
  
  export <progress-indicator>, increment-progress, report-progress,
    increment-and-report-progress, 
    <draw-dots-progress-indicator>, <n-of-k-progress-indicator>;
  
end module progress-indicator;

define module main
  use common;
  use byte-vector;
  use Extensions, exclude: { element-type, value };
  use System, 
     import: {system, getenv, <raw-pointer>, import-string, 
              export-string, no-core-dumps,
              c-include, c-expr, c-decl, pointer-deref, pointer-deref-setter, call-out};
  use string-conversions, import: {string-to-integer};
  use substring-search;
  use character-type;
  use random;
  use command-line-parser;
  use option-parser-protocol;
  use indenting-streams;
   
  use utils;
  use variables;
  use definitions;
  use variable-definitions;
  use function-definitions;
  use define-classes;
  use define-libraries-and-modules;
  use define-constants-and-variables;
  use define-functions;
  use define-macros;
  use parser;
  use macros;
  use tokenize;
  use lexer;
  use header;
  use source;
  use top-level-forms;
  use flow;
  use builder-interface;
// use fer-convert;
  use front;
// use dump;
  use fer-convert;
  use top-level-expressions;
  use classes;
  use c-representation;
  use cback;
  use heap;
  use compile-time-values;
  use compile-time-functions;
  use signature-interface;
  use ctype;
  use abstract-optimizer;
  use null-optimizer;
  use cheese;
  use od-format;
  use standard-io;
  use tokens;
  use names;
  use errors;
  use policy;
  use macros;
  use fragments;
  use parse-tree, exclude: {primitive-name};
  use definitions;
  use platform;
  use platform-constants;
  use main-constants;
  use main-unit-info;
  use file-system;
  use extensions, import: {key-exists?};
  use command-processor;
  use debugger;
  use progress-indicator;
end;
