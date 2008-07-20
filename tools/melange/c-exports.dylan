module: dylan-user
copyright: see below
	   This code was produced by the Gwydion Project at Carnegie Mellon
	   University.  If you are interested in using this code, contact
	   "Scott.Fahlman@cs.cmu.edu" (Internet).

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

//======================================================================
//
// Copyright (c) 1994, 1996  Carnegie Mellon University
// Copyright (c) 1998, 1999, 2000  Gwydion Dylan Maintainers
// All rights reserved.
//
//======================================================================

define library melange-c
  use dylan;
  use common-dylan;
  use string-extensions;
  use collection-extensions;
  use regular-expressions;
  use table-extensions;
  use system;
  use io;

  // General purpose utility modules.
  export
    source-locations,
    parse-conditions,
    multistring-match;

  // Melange-specific.
  export
    c-lexer,
    c-declarations,
    portability;
end library melange-c;

define module source-locations
  use common-dylan, exclude: { format-to-string, <stream>, close };
  use streams;
  use format;
  use standard-io;
  export
    source-location,
    <source-location>,
    describe-source-location,
    <unknown-source-location>,
    <file-source-location>,
      source-file,
      source-line;
end module source-locations;

define module parse-conditions
  use common-dylan, exclude: { format-to-string, <stream>, close };
  use source-locations;
  use streams;
  use format;
  use standard-io;
  export
    *show-parse-progress-level*,
    $parse-progress-level-none,
    $parse-progress-level-headers,
    $parse-progress-level-all,
    <parse-condition>,
    <simple-parse-error>,
    <simple-parse-warning>,
    <parse-progress-report>,
    push-default-parse-context,
    pop-default-parse-context,
    // \with-default-parse-context,
    parse-error,
    parse-warning,
    parse-progress-report,
    parse-header-progress-report;
end module;

define module multistring-match
  use common-dylan;
  export
#if (~mindy)
    multistring-checker-definer, multistring-positioner-definer,
#endif
    make-multistring-positioner, make-multistring-checker
end module multistring-match;

define module c-lexer
  use common-dylan,
    exclude: { format, format-to-string, 
               string-to-integer, integer-to-string, split, position,
               <stream>, close };
  use format;
  use table-extensions;
  use self-organizing-list;
  use string-conversions;
  use regular-expressions;
  use substring-search;
  use character-type;
  use streams;
  use file-system;
  use source-locations;
  use parse-conditions,
    // XXX - These should probably go away.
    export: {parse-error,
	     parse-warning,
	     parse-progress-report};
  use multistring-match;
  create cpp-parse;
  export
    *handle-c++-comments*,
    *framework-paths*, find-frameworks,
    <tokenizer>, cpp-table, cpp-decls, <token>, token-id, generator,
    <simple-token>, <reserved-word-token>, <punctuation-token>,
    <literal-token>, <ei-token>, <name-token>, <type-specifier-token>,
    <identifier-token>, <integer-token>, <character-token>, <struct-token>,
    <short-token>, <long-token>, <int-token>, <char-token>, <signed-token>,
    <unsigned-token>, <float-token>, <double-token>, <void-token>,
    <union-token>, <enum-token>, <minus-token>, <tilde-token>, <bang-token>,
    <alien-name-token>, <macro-parse-token>, <cpp-parse-token>, string-value,
    value, unget-token, add-typedef, get-token, include-path,
    check-cpp-expansion, file-in-include-path
end module c-lexer;

define module portability
  use dylan;
  use c-lexer, import: {include-path, *handle-c++-comments*, *framework-paths*};
  use system, import: {getenv};  // win32 only
  use regular-expressions;       // win32 only			  
  export
    $default-defines,
    $enum-size,
    $pointer-size, $function-pointer-size,
    $integer-size, $short-int-size,
    $long-int-size, $char-size,
    $longlong-int-size,
    $float-size, $double-float-size,
    $long-double-size;
end module portability;

define module c-parse
  use common-dylan, exclude: { format-to-string, <stream>, close };
  use extensions, import: { <extended-integer> };
  use self-organizing-list;
  use c-lexer;
  use streams;
  use format;
  use standard-io;
  create
    <parse-state>, <parse-file-state>, <parse-value-state>,
    <parse-type-state>, <parse-cpp-state>,
    <parse-macro-state>, tokenizer, verbose, verbose-setter,
    push-include-level, pop-include-level, objects, process-type-list,
    process-declarator, declare-objects, make-struct-type, c-type-size,
    add-cpp-declaration, unknown-type, <declaration>, <arg-declaration>,
    <varargs-declaration>, <enum-slot-declaration>, constant-value,
    <integer-type-declaration>,
    <signed-integer-type-declaration>,
    <unsigned-integer-type-declaration>,
    canonical-name, true-type, type-size-slot, make-enum-slot,
    referent;
  export
    parse, parse-type, parse-macro;
end module c-parse;

define module c-declarations
  use common-dylan, exclude: { format-to-string, split, <stream>, close };
  use table-extensions, rename: { table => make-table };
  use regular-expressions;
  use streams;
  use file-system;
  use format;
  use standard-io;

  // We completely encapsulate "c-parse" and only pass out the very few 
  // objects that will be needed by "define-interface".  Note that the 
  // classes are actually defined within this module but are exported
  // from c-parse.
  use c-parse, export: {<declaration>, <parse-state>, parse, parse-type,
			constant-value, true-type, canonical-name, referent};

  use c-lexer;			// Tokens are used in process-type-list and
				// make-struct-type
  use portability;              // constants for size of C data types
  use source-locations;         // Used for error and 
  use parse-conditions;         //   progress reporting.

  export
    // Basic type declarations
    <function-declaration>, <structured-type-declaration>,
    <struct-declaration>, <union-declaration>, <variable-declaration>,
    <constant-declaration>, <typedef-declaration>, <pointer-declaration>,
    <vector-declaration>, <function-type-declaration>,
    local-name-mapper, local-name-mapper-setter,
    callback-maker-name, callback-maker-name-setter,
    callout-function-name, callout-function-name-setter,

    // Preliminary "set declaration properties phase"
    ignored?-setter, find-result, find-parameter, find-slot,
    argument-direction-setter, constant-value-setter, getter-setter,
    setter-setter, read-only-setter, sealed-string-setter, excluded?-setter,
    exclude-slots, equate, remap, rename, superclasses-setter, pointer-equiv,
    dylan-name, exclude-decl, 

    // "Import declarations phase" 
    declaration-closure, // also calls compute-closure

    // "Name computation phase"
    apply-options, apply-container-options, // also calls find-dylan-name,
					    // compute-dylan-name

    // "Write declaration phase"
    <written-name-record>,
		written-names,
    write-declaration, 
    write-file-load, write-mindy-includes,

    // Miscellaneous
    getter, setter, sealed-string, excluded?,
    declarations, *inhibit-struct-accessors?*,
    melange-target;
end module c-declarations;
