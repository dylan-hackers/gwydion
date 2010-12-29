module:  c-lexer
author:  Robert Stockton (rgs@cs.cmu.edu)
synopsis: Encapsulates the lexical conventions of the C language.
          This file also incorporates most of the functionality of CPP.
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

//======================================================================
// This file contains functions which emulate the functionality of CPP.  These
// functions are then called by the general lexing routines in
// "c-lexer.dylan".  The only items directly exported from this file are
// "default-cpp-table" and "include-path", which are made available to other
// modules so that they can add elements before the parse begins.  In
// particular, module "portability" is expected to define the "standard"
// definitions for whatever machine we are compiling for as well as the
// standard "include" directories.
//======================================================================

// This table maps strings defined by the preprocessor into tokens.  Initial
// values are taken from the appropriate portability module.  Entries should
// be sequences of tokens in reverse order.  These sequences will not
// themselves be "expanded".  In other words, some of the tokens may
// themselves have entries in the table.  Macro expansion will, therefore,
// recursively expand each "expanded" token, recursing as deeply as necessary.
//
define constant default-cpp-table = make(<string-table>);

// include-path -- exported constant.
//
// This sequence should contain a complete list of "standard include
// directories". It gets initialized by the appropriate portability
// module at load time. Any command-line include directories are
// added (preserving order) to the front of the list by main(). The
// directory "./" is to the front after adding any specified on
// the command line.
//
define /* exported */ constant include-path :: <deque> = make(<deque>);

// *framework-path* -- exported variable

define variable *framework-paths* :: <vector> = make( <vector> );

// *frameworks* -- private variable
// This is the table of (MacOSX/Darwin-style) framework include paths
// keyed by framework name
// This is of little interest outside Mac OS X but is here to make the code simpler

define variable *frameworks* :: <table> = make( <table> );

define method file-is-header?(path :: <pathname>)
 => (header? :: <boolean>)
  let path = as(<file-system-locator>, path);
  path.file-exists? & path.link-target.file-type = #"file";
end;

// These routines support finding frameworks at run time

define method framework-exists?( path :: <string>, name :: <string> )
=> ( exists :: <boolean> )
    let framework-header :: <string> =
        concatenate( path, name, ".h" );
    path.file-is-header?;
end method framework-exists?;

define method find-frameworks( frameworks :: <vector> )
=> ()
    for( framework :: <string> in frameworks )
        find-framework( framework );
    end for;
end method find-frameworks;

define method find-framework
    ( framework-name :: <string> )
 => ( framework-path :: false-or(<string>) )
  let framework-key = as( <symbol>, framework-name );
  
  // First, see if we've already got the framework path cached.
  element( *frameworks*, framework-key, default: #f )
    | block (return)
        for (path :: <string> in *framework-paths*)
          let full-path :: <string> = concatenate( path, framework-name, ".framework" );
          
          // If it has a headers directory
          let framework-headers-path :: <string> = concatenate( full-path, "/Headers/" );
          if (framework-exists?( framework-headers-path, framework-name ))
            *frameworks*[ framework-key ] := framework-headers-path;
            
            // Add it to the end of the normal include paths as well
            // so non-prefixed includes within framework headers can be found
            push-last( include-path, framework-headers-path );
            
            // Guess that it has a frameworks directory and add this
            // It's a little wasteful, but it isolates us from file-system
            // And the path won't be added if we don't find a header
            // Note that this means that parent frameworks must be listed before children
            let recursive-path :: <string> = concatenate( full-path, "/Frameworks/" );
            *framework-paths* := add!( *framework-paths*, recursive-path );

            return( framework-headers-path );
          end if;
        end for;
      end block;
end method find-framework;

// This routine grabs tokens from within the "parameter list" of a
// parameterized macro use.  The calling routine should have already consumed
// the opening paren.  The result is a reversed list of reversed token lists.
// In other words "foo, (bar + baz))" would result in
//   #(#(rparen, baz, plus, bar, lparen), #(foo)).
//
// Although this seems an odd order, it turns out to be fairly convenient for
// matching to the formal parameters and for actually expanding the token
// sequences when they are matched.
//
define function get-macro-params
    (state :: <tokenizer>,
     params :: <list>,
     #key expand)
 => (params :: <list>);
  let paren-count = 0;
  for (token = get-token(state) then get-token(state, expand: expand),
       list = #() then pair(token, list),
       until: (paren-count == 0
		& instance?(token, type-union(<rparen-token>, <comma-token>))))
    select (token by instance?)
      <eof-token>, <error-token> =>
	parse-error(state, "Badly formed macro use.");
      <lparen-token> => paren-count := paren-count + 1;
      <rparen-token> => paren-count := paren-count - 1;
      otherwise => #f;
    end select;
  finally
    if (instance?(token, <comma-token>))
      get-macro-params(state, pair(list, params));
    else
      pair(list, params);
    end if;
  end for;
end function get-macro-params;

// When we are generating expansions, we wish to make copies of the token
// rather than return the original.  This will put the right character
// position and "generator" in the token.
//
define method copy-token
    (token :: <token>, tokenizer :: <tokenizer>) => (result :: <token>);
  make(object-class(token), position: tokenizer.position,
       string: string-value(token), generator: tokenizer);
end method copy-token;

define constant empty-table = make(<self-organizing-list>);

// check-cpp-expansion -- exported function.
//
// Recursively handle expansion of preprocessor tokens.  Returns #f if the
// string has no expansion.  Otherwise, adds a series of tokens to the
// "unget-stack", so that the next get-token call will get the first expanded
// token.  This routine will recurse as deeply as necessary to make sure that
// all tokens are expanded.  The recursive expansions are actually done from
// back to front, but this seems not to yield any particular problems on
// existing header files.  It is, however, possible that some *very* obscure
// hacks might fail.
// 
// Note that the pushed tokens are newly generated copies of the ones in
// cpp-table.  Thus they will have appropriate location information for error
// reporting. 
//
// Added forbidden-expansions to prevent recursive macro
// expansion. [obsolete: This is insufficient by itself; we're also supposed to tag
// tokens which we weren't allow to expand to ensure that they never get
// expanded in any other place. But this should handle the most common
// problems.]
// Now the called functions accept #key expand to be a list of forbidden-expansions
// from the outer level. This means that the expansion will be done for all but the
// names included in the list. This way we can expand macro calls to "foo" that appear
// as actuals of an outer macro call to "foo" (as in foo(foo(XXX))) but suppress
// expansion in a "#define foo(P) foo(P)" situation, because "foo" in the rhs will
// be put in the forbidden-expansions.

define constant $maximum-cpp-expansion-depth = 32;

define /* exported */ function check-cpp-expansion
    (string :: <string>, tokenizer :: <tokenizer>,
     #key parameters: parameter-table = empty-table,
     forbidden-expansions = #(),
     current-depth = 0)
 => (result :: <boolean>);
  let headless-string 
    = if (string.first == '#') copy-sequence(string, start: 1) else string end;
  let token-list :: false-or(<sequence>)
    = (element(parameter-table, headless-string, default: #f)
	 | element(tokenizer.cpp-table, string, default: #f));

  local method expand-inner(token-list :: <sequence>, #key parameters = empty-table)
  	let forbidden = pair(string, forbidden-expansions);
	for (token in token-list)
	  unless (check-cpp-expansion(token.string-value, tokenizer,
				      parameters: parameters,
				      current-depth: current-depth + 1,
				      forbidden-expansions: forbidden))
	    // Successful call will have already pushed the expanded tokens
	    let cls = element(reserved-word-table,
			      token.string-value, default: #f);
	    if (cls)
	      let reserved-word-token = make(cls,
					     position: tokenizer.position,
					     string: string-value(token),
					     generator: tokenizer);
	      push(tokenizer.unget-stack, reserved-word-token);
	    else
	      push(tokenizer.unget-stack, copy-token(token, tokenizer));
	    end if;
	  end unless;
	finally
	  #t;
	end for;
      end method expand-inner;

  case
    current-depth >= $maximum-cpp-expansion-depth =>
      parse-error(tokenizer, "Preprocessor macro expansion of ~s too deep",
		  string);
    member?(string, forbidden-expansions, test: \=) =>
      #f;
    string.first == '#' =>
      if (string = "##")
	// Special case for <pound-pound-token>
	#f;
      else
	if (~token-list)
	  parse-error(tokenizer, "%s in macro not matched.", string)
	end if;

	// Concatenate the parameter's string-values, bracketed by double
	// quotes so that we get a string literal.  We won't do expansion --
	// hopefully this won't cause problems in "real" code.
	let reversed-strings = map(string-value, token-list);
	let quoted = pair("\"", reverse!(pair("\"", reversed-strings)));
	push(tokenizer.unget-stack,
	     make(<string-literal-token>, position: tokenizer.position,
		  generator: tokenizer, string: apply(concatenate, quoted)));
	#t;
      end if;
    ~token-list =>
      #f;
    token-list.empty? =>
      #t;
    instance?(token-list.head, <list>) =>
      // This is a parameterized macro.  Therefore we have to do some really
      // hairy expansion.
      let lparen-token = get-token(tokenizer);
      if (~instance?(lparen-token, <lparen-token>))
	// Apparently some systems (i.e. VC++) accept non-parenthesized uses
	// of parameterized macros as ordinary symbols.  Therefore, we'd
	// better do likewise.
	push(tokenizer.unget-stack, lparen-token);
	#f;
      else
	let params = get-macro-params(tokenizer, #(), expand: forbidden-expansions);
	let formal-params = token-list.head;
	if (params.size ~= formal-params.size)
	  parse-error(tokenizer, "Wrong number of parameters in macro use.")
	end if;
	let params-table = make(<self-organizing-list>, test: \=);
	// Add params to params table, keyed by formal params.
	for (key in formal-params, value in params)
	  params-table[key] := value;
	end for;
	expand-inner(token-list.tail, parameters: params-table);
      end if;
    otherwise =>
      // Depends upon the fact that tokens are stored in reverse order in the
      // stored macro expansion.
      expand-inner(token-list);
  end case;
end function check-cpp-expansion;

// framework-include
// Check for #include<Framework/Framework.h>

define method framework-include( filename :: <string> )
 => (full-name :: false-or( <string> ))
  
  // Break the include down into a framework name and a file name
  let slash-position :: false-or( <integer> ) = subsequence-position( filename, "/" );
  if (slash-position)
    let framework-name :: <string> = copy-sequence( filename, end: slash-position );
    
    // Try to find the framework
    let framework-path :: false-or( <string> ) = find-framework( framework-name );
    
    // If we found it, try to open the file
    if (framework-path)
      let file-name :: <string> = copy-sequence( filename, start: slash-position + 1 );
      let full-path :: <string> = concatenate( framework-path, file-name );
      if(full-path.file-is-header?) full-path else #f end;
    else
      // It may be a nested framework
      // Try to find it
      // Otherwise it's probably not a framework include.
      // Let file-in-include-path try
      #f;
    end if;
  else
    #f;
  end if;
end method framework-include;

// file-in-include-path -- exported function.
//
define /* exported */ function file-in-include-path (name :: <string>,
                                                     #key skip-to)
 => (full-name :: false-or(<string>));
 
  if (first(name) == '/')
    if(name.file-is-header?) name else #f end;
  else

    // We don't have any "file-exists" functions, so we just keep trying
    // to open files until one of them fails to signal an error.
    block (return)
      let search-path =
        if(skip-to)
          // XXX
        else
          include-path;
        end if;
        
      for (dir in search-path)
        block ()
          let full-name = concatenate(dir, "/", name);
          if(full-name.file-is-header?) return(full-name) end;
        end block;
      finally
        // Try looking in the frameworks
        framework-include( name );
      end for;
    end block;
  end if;
end function file-in-include-path;

define /* exported */ function next-file-in-include-path (state,file-path :: <string>,file-name :: <string>)
 => (full-name :: false-or(<string>));
  let skip = #t;
  block (return)
    for (dir in include-path)
      if (skip = #f)
        block ()
          let full-name = concatenate(dir, "/", file-name);
          if(full-name.file-is-header?) return(full-name) end;
        end block;
      end if;
      if (skip & dir = file-path) skip := #f end if;
    end for;
  end block;
end function next-file-in-include-path;

// Check for a #include<angles.h> file
//
define method angle-include( state, contents, angle-start, angle-end )
 =>( tokenizer :: <tokenizer> )
  // We've got a '<>' name, so we need to successively try each of the
  // directories in include-path until we find it.  (Of course, if a
  // full pathname is specified, we just use that.)
  let name = copy-sequence(contents,
                           start: angle-start + 1,
                           end: angle-end - 1);
  let full-name = file-in-include-path(name);
  if (full-name)
    state.include-tokenizer
      := make(<tokenizer>, name: full-name, parent: state);
  else
    parse-error(state, "File not found: %s", name);
  end if;
end;

define method angle-include-next( state, filename )
 =>( tokenizer :: <tokenizer> )
  let name = copy-sequence(state.file-name);
  if (first(filename) == '/')
    let (found,match-end,path-start,path-end,filename-start,filename-end) 
      = regexp-position(filename, "^(.*)/([^/]+)");
    filename := copy-sequence(filename,start: filename-start, end: filename-end);
  end if;
  if (first(name) == '/')
    let (found,match-end,path-start,path-end,filename-start,filename-end) 
      = regexp-position(state.file-name, "^(.*)/([^/]+)");
    if(found)
      let file-path = copy-sequence(name,start: path-start, end: path-end);      
      let full-name = next-file-in-include-path(state,file-path,filename);
      if (full-name)
        state.include-tokenizer
          := make(<tokenizer>, name: full-name, parent: state);
      else
        state.include-tokenizer
          := make(<tokenizer>, contents: "", parent: state);
      end if;
    end if;
  else
    parse-error(state,"Filename is not absolute %s",name);
  end if;
end;

// Check for a #include"quotes.h" file
// We could just use angle-include for everything
// but this maintains the original intent.
//
define method quote-include( state, contents, quote-start, quote-end )
=>( tokenizer :: <tokenizer> )
    // We've got a '""' name, so we should look in the same directory as
    // the current ".h" file first.  (Of course, if a full pathname is
    // specified, we just use that.)
    let name = copy-sequence(contents, start: quote-start + 1,
                                end: quote-end - 1);
    let absolute-name = "";
    // if (name is not an absolute path) [drive/UNC optional on win32 systems]
#if (compiled-for-win32)
    if (regexp-position(name, "((.:)|\\\\)?(\\\\|/)"))
#else
    if (first(name) == '/')
#endif
        absolute-name := name;
    else
        // Turn the a relative pathname into an absolute pathname by
        // replacing everything after the last path separator with
        // the new relative path name.  Honestly, no one remembers
        // why we want to do this, although "gives more useful error
        // messages" sounds like a good guess.

        // ### If we try to absolutize a relative path with a drive
        // letter, this will do something horribly wrong.  Then
        // again, I suspect Melange will have crapped out long
        // before now if a user tried that.
        absolute-name := regexp-replace(state.file-name, 
                                        #if (compiled-for-x86-win32)
                                            "[^\\\\/]+$", 
                                        #else
                                            "[^/]+$", 
                                        #endif
                                            name);
    end if;
    
    if (absolute-name.file-is-header?)
        state.include-tokenizer
          := make(<tokenizer>, name: absolute-name, parent: state);
    else
        angle-include( state, contents, quote-start, quote-end );
    end if;
end;

// Creates a nested tokenizer corresponding to a new file specified by an
// "#include" directive.  The file location is computed from the '<>' or '""'
// string combined with the enclosing file's directory or the "include-path".
//
define method cpp-include (state :: <tokenizer>, pos :: <integer>) => ();
  let contents :: <string> = state.contents;
  let (found, match-end, angle-start, angle-end, quote-start, quote-end)
    = regexp-position(contents, "^(<[^>]+>)|(\"[^\"]+\")", start: pos);
  state.position := match-end;
  let generator
    = if (~found)
	parse-error(state, "Ill formed #include directive.");
      elseif (angle-start & angle-end)
        angle-include(state, contents, angle-start, angle-end);
      elseif (quote-start & quote-end)
        quote-include(state, contents, quote-start, quote-end);
      else
        parse-error(state, "Fatal error handling #include: %= %= %= %= %= %=",
                    found, match-end,
                    angle-start, angle-end,
                    quote-start, quote-end);
      end if;
  parse-header-progress-report(generator, ">>> entered header >>>");
  unget-token(generator, make(<begin-include-token>, position: pos,
			      generator: generator,
			      string: generator.file-name));
end method cpp-include;
    
define method cpp-include-next (state :: <tokenizer>, pos :: <integer>) => ();
  let contents :: <string> = state.contents;
  let (found, match-end, angle-start, angle-end, quote-start, quote-end)
    = regexp-position(contents, "^(<[^>]+>)|(\"[^\"]+\")", start: pos);
  state.position := match-end;
  let filename = "";
  if (angle-start & angle-end) 
    filename := copy-sequence(contents,
                              start: angle-start + 1,
                              end: angle-end - 1);
  elseif(quote-start & quote-end)
    filename := copy-sequence(contents,
                              start: quote-start + 1,
                              end: quote-end - 1);
  else
    parse-error(state, "Fatal error handling #include_next: %= %= %= %= %= %=",
                found, match-end,
                angle-start, angle-end,
                quote-start, quote-end);
  end if;
  let generator = angle-include-next(state, filename);

  parse-header-progress-report(generator, ">>> entered header >>>");
  unget-token(generator, make(<begin-include-token>, position: pos,
			      generator: generator,
			      string: generator.file-name));
end method cpp-include-next;

// Processes a preprocessor macro definition.  For "simple" macros, this only
// involves building a reversed sequence of tokens from the remainder of the
// line and putting it in cpp-table.  However, if it is a parameterized macro
// than we must also parse the parameter list and place it at the front of the
// token sequence.  The expander identifies parameterized macros by the fact
// that the first element of the token sequence is itself a sequence.
//
define method cpp-define (state :: <tokenizer>, pos :: <integer>) => ();
  let name = try-identifier(state, pos, expand: #f);
  if (~name)
    parse-error(state, "Ill formed #define directive.");
  end if;

  // Simply read the rest of the line and build a reversed list of tokens.
  local method grab-tokens (list :: <list>)
	  let token = get-token(state, cpp-line: #t);
	  select (token by instance?)
	    <eof-token> =>
	      list;
	    otherwise =>
	      grab-tokens(pair(token, list));
	  end select;
	end method grab-tokens;

  if (state.contents[state.position] == '(')
    // Check whether this is a parameterized macro.
    // We can't just ask for the next token, as this is the one place in C
    // where whitespace between tokens is significant.
    get-token(state, cpp-line: #t);  // Eat the open paren
    local method grab-params (state :: <tokenizer>, param-list :: <list>)
	    let name = get-token(state, cpp-line: #t);
	    if (empty?(param-list) & instance?(name, <rparen-token>))
	      // Parameter lists may be empty, in which case we won't get an
	      // identifier here.
	      param-list;
	    elseif (instance?(name, <name-token>))
	      let next-token = get-token(state, cpp-line: #t);
	      select (next-token by instance?)
		<comma-token> =>
		  grab-params(state, pair(name.value, param-list));
		<rparen-token> =>
		  pair(name.value, param-list);
                <ellipsis-token> =>
                  unless (instance?(get-token(state, cpp-line: #t),
                                    <rparen-token>))
                    parse-error(state, "Badly formed parameter list in #define,"
                                  " ellipsis must be last parameter.");
                  end unless;
                  name.value;                
		otherwise =>
		  parse-error(state,"Badly formed parameter list in #define.");
	      end select;            
            elseif (instance?(name, <ellipsis-token>))
              unless (instance?(get-token(state, cpp-line: #t), <rparen-token>))
                parse-error(state, "Badly formed parameter list in #define,"
                                   " ellipsis must be last parameter.");
              end unless;
              "__VA_ARGS__"
	    else
	      parse-error(state, "Badly formed parameter list in #define.");
	    end if;
	  end method grab-params;
    let params = grab-params(state, #());
    state.cpp-table[name.string-value] := pair(params, grab-tokens(#()));
  else
    state.cpp-table[name.string-value] := grab-tokens(#());
    if (state.cpp-decls) push-last(state.cpp-decls, name.string-value) end if;
  end if;

  // some of this is expensive
  if (*show-parse-progress-level* > $parse-progress-level-none)
    let defn = state.cpp-table[name.string-value];
    let (args, expansion) =
      if (defn ~== #() & instance?(defn.head, <list>))
        values(defn.head.reverse, defn.tail.reverse)
      else
        values(#f, defn.reverse)
      end;
    parse-progress-report(name, "Processing define %= %= => %=",
                          name.string-value,
                          args,
                          map(string-value, expansion));
  end;
end method cpp-define;

//define constant preprocessor-match
//  = make-regexp-positioner("^#[ \t]*(define|undef|include|ifdef|ifndef|if"
//			     "|else|elif|line|endif|error|pragma)\\b",
//			   byte-characters-only: #t, case-sensitive: #t);
#if (~mindy)
define multistring-checker preprocessor-match
  ("define", "undef", "include", "include_next", "ifdef", "ifndef", "if",
   "else", "elif", "line", "endif", "error", "warning", "pragma");
define multistring-positioner do-skip-matcher("#", "/*");
#else
define constant preprocessor-match
  = make-multistring-checker("define", "undef", "include", "include_next",
			     "ifdef", "ifndef", "if", "else", "elif", "line",
			     "endif", "error", "warning", "pragma");
define constant do-skip-matcher
  = make-multistring-positioner("#", "/*");
#endif

//define constant do-skip-matcher
//  = make-regexp-positioner("#|/\\*",
//			   byte-characters-only: #t, case-sensitive: #t);

// Checks to see whether we are looking at a preprocessor directive.  If so,
// we handle the directive and return #t.  The state may change drastically,
// so we expect the caller to re-invoke "get-token" afterwards.  If we aren't
// looking at a preprocessor directive, we return #f and the caller can
// continue as normal.
//

// for debugging
define method map-string-value
    (foo) => (string-values :: <collection>)
  #();
end;

define method map-string-value
    (foo :: <collection>) => (string-values :: <collection>)
  map(string-value, foo);
end;


define method try-cpp
    (state :: <tokenizer>, start-pos :: <integer>) => (result :: <boolean>);
  let contents = state.contents;

  if (contents[start-pos] ~= '#')
    #f;
  else
    let start-pos
      = for (i from start-pos + 1 below contents.size,
	     until: contents[i] ~== ' ' & contents[i] ~== '\t')
	finally i;
	end for;
      
    let (word) = preprocessor-match(contents, start: start-pos);
    
//    if (found)
    if (word)
      // If an #if killed off a region of code, this routine will quickly skip
      // over it.  Because we may have to deal with nested #ifs, we don't
      // directly look for #else or #endif.  Instead we re-call "try-cpp" and
      // then check to see if it changed the "cpp-stack".  If so, we must be
      // done.  Note that nested #ifs are eliminated by recursive calls to
      // do-skip, even if their conditions would normally evaluate to true.
      //
      local method do-skip(pos, current-stack) => ();
	      let i = do-skip-matcher(contents, start: pos);
	      unless (i)
		parse-error(state, "Unmatched #if in include file.")
	      end;
	      let i = skip-whitespace(contents, i);
	      if (~try-cpp(state, i))
		// We may get false matches -- if so, just move on
		do-skip(i + 1, current-stack);
	      elseif (current-stack == state.cpp-stack)
		do-skip(state.position, current-stack);
	      end if;
	    end method do-skip;

//      let word = copy-sequence(contents, start: word-start, end: word-end);
//      let pos = skip-cpp-whitespace(contents, pos);
      let pos = skip-cpp-whitespace(contents, start-pos + word.size);
      state.position := pos;
      select (word by \=)
	"define" =>
	  if (empty?(state.cpp-stack) | head(state.cpp-stack) == #"accept")
	    cpp-define(state, pos)
	  end if;
	"undef" =>
	  if (empty?(state.cpp-stack) | head(state.cpp-stack) == #"accept")
	    let name = try-identifier(state, pos, expand: #f);
	    if (~name)
	      parse-error(state, "Ill formed #undef directive.");
	    end if;
            parse-progress-report(name, "undef %=", name.string-value);
	    remove-key!(state.cpp-table, name.string-value);
	  end if;
	"ifdef" =>
	  if (empty?(state.cpp-stack) | head(state.cpp-stack) == #"accept")
            let name = try-identifier(state, pos, expand: #f);
            if (~name)
              parse-error(state, "Ill formed #ifdef directive.");
            end if;
            parse-progress-report(name, "ifdef %=, element = %=", name.string-value,
                                  element(state.cpp-table, name.string-value,
                                          default: #f).map-string-value);
            if (element(state.cpp-table, name.string-value, default: #f))
              parse-progress-report(name, "ifdef %= -- taking true branch",
                                    name.string-value);
              state.cpp-stack := pair(#"accept", state.cpp-stack);
            else
              parse-progress-report(name, "ifdef %= -- skipping", name.string-value);
              do-skip(state.position,
                      state.cpp-stack := pair(#"retry", state.cpp-stack));
            end if;
          else
            do-skip(state.position,
                    state.cpp-stack := pair(#"retry", state.cpp-stack));
          end if;
	"ifndef" =>
	  if (empty?(state.cpp-stack) | head(state.cpp-stack) == #"accept")
            let name = try-identifier(state, pos, expand: #f);
            if (~name)
              parse-error(state, "Ill formed #ifndef directive.");
            end if;
            parse-progress-report(name, "ifndef %=, element = %=", name.string-value,
                                  element(state.cpp-table, name.string-value,
                                          default: #f).map-string-value);
            if (~element(state.cpp-table, name.string-value, default: #f))
              parse-progress-report(name, "ifndef %= -- taking true branch",
                                    name.string-value);
              state.cpp-stack := pair(#"accept", state.cpp-stack);
            else
              parse-progress-report(name, "ifndef %= -- skipping", name.string-value);
              do-skip(state.position,
                      state.cpp-stack := pair(#"retry", state.cpp-stack));
            end if;
          else
            do-skip(state.position,
                    state.cpp-stack := pair(#"retry", state.cpp-stack));
          end if;
	"if" =>
	  let stack = state.cpp-stack;
	  if ((empty?(stack) | head(stack) == #"accept")
		& cpp-parse(state) ~= 0)
            parse-progress-report(state, "if -- taking true branch");
	    state.cpp-stack := pair(#"accept", stack);
	  else
            parse-progress-report(state, "if -- skipping");
	    do-skip(pos, state.cpp-stack := pair(#"retry", stack));
	  end if;
	"else" =>
	  let stack = state.cpp-stack;
	  if (empty?(stack))
	    parse-error(state, "Mismatched #else.");
	  else
	    let rest = tail(stack);
	    if (head(stack) == #"accept")
              parse-progress-report(state, "else -- skipping");
	      do-skip(pos, state.cpp-stack := pair(#"done", tail(stack)));
	    elseif (head(stack) == #"retry"
		  & (empty?(rest) | head(rest) == #"accept"))
              parse-progress-report(state, "else -- processing");
	      state.cpp-stack := pair(#"accept", rest);
	    else
              parse-progress-report(state, "else -- skipping");
	      do-skip(pos, stack);
	    end if;
	  end if;
	  // For SUN4 headers, kill to end of line
	  for (i from state.position below contents.size,
	       until: contents[i] == '\n')
	  finally
	    state.position := i;
	  end for;
	"elif" =>
	  let stack = state.cpp-stack;
	  if (empty?(stack))
	    parse-error(state, "Mismatched #elif.");
	  else
	    let rest = tail(stack); 
	    if (head(stack) == #"accept")
	      do-skip(pos, state.cpp-stack := pair(#"done", tail(stack)));
	    elseif (head(stack) == #"retry"
		  & (empty?(rest) | head(rest) == #"accept")
		  & cpp-parse(state) ~= 0)
	      state.cpp-stack := pair(#"accept", rest);
	    else 
	      do-skip(pos, stack);
	    end if;
	  end if;
	  // For SUN4 headers, kill to end of line
	  for (i from state.position below contents.size,
	       until: contents[i] == '\n')
	  finally
	    state.position := i;
	  end for;
	"endif" =>
	  let old-stack = state.cpp-stack;
	  if (empty?(old-stack))
	    parse-error(state, "Unmatched #endif.");
	  end if;
	  state.cpp-stack := tail(old-stack);
	  // For SUN4 headers, kill to end of line
	  for (i from state.position below contents.size,
	       until: contents[i] == '\n')
	  finally
	    state.position := i;
	  end for;
	"error" =>
	  if (empty?(state.cpp-stack) | head(state.cpp-stack) == #"accept")
            for (i from pos below contents.size,
                 until: (contents[i] == '\n' | contents[i] == '\r'))
            finally
              parse-error(state, "Encountered #error directive: %s",
                          copy-sequence(contents, start: pos, end: i));
            end for;
	  end if;
        "warning" =>
          if (empty?(state.cpp-stack) | head(state.cpp-stack) == #"accept")
            for (i from pos below contents.size,
                 until: (contents[i] == '\n' | contents[i] == '\r'))
            finally
              parse-warning(state,
                            "Warning: %s\n", 
                            copy-sequence(contents, start: pos, end: i));
              state.position := i;
            end for;
          end if;
	"line", "pragma" =>
	  // Kill to end of line
	  for (i from pos below contents.size,
               until: (contents[i] == '\n' | contents[i] == '\r'))
	  finally
	    state.position := i;
	  end for;
	"include" =>
	  if (empty?(state.cpp-stack) | head(state.cpp-stack) == #"accept")
	    cpp-include(state, pos);
	  end if;
	"include_next" =>
	  //signal("Warning: doing the wrong thing with #include_next.");
	  if (empty?(state.cpp-stack) | head(state.cpp-stack) == #"accept")
	    cpp-include-next(state, pos);
	  end if;
	otherwise =>
	  parse-error(state, "Unhandled preprocessor directive.");
      end select;
      #t;
    else
      // Certain compilers might accept additional directives.  As long as
      // they are within failed #ifdefs, we can ignore them.
      if (empty?(state.cpp-stack) | head(state.cpp-stack) == #"accept")
	parse-error(state, "Unknown preprocessor directive starting with %=",
		    // Take a wild guess at how much context is enough
		    copy-sequence(contents, start: start-pos, 
				  end: start-pos + 30));
      end if;
      #f;
    end if;
  end if;
end method try-cpp;
