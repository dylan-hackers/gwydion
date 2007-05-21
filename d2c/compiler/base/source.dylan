module: source
copyright: see below

//======================================================================
//
// Copyright (c) 1995 - 1997  Carnegie Mellon University
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

// source-location -- exported.
//
// Return the location in the source where the thing came from, or #f if
// unknown.
// 
define open generic source-location (thing :: <object>)
    => res :: <source-location>;


// The <source-location-mixin> class.

define open abstract class <source-location-mixin> (<object>)
  sealed constant slot source-location :: <source-location>
      = make(<unknown-source-location>),
    init-keyword: source-location:;
end;


// The <source-location> class.

define open abstract class <source-location> (<object>)
end;

define sealed domain make (singleton(<source-location>));


define method make (wot == <source-location>, #key)
    => res :: <source-location>;
  make(<unknown-source-location>);
end;


define open generic describe-source-location
    (srcloc :: <source-location>, stream :: <stream>) => ();



// Unknown source locations.

define class <unknown-source-location> (<source-location>)
end;

define sealed domain make (singleton(<unknown-source-location>));
define sealed domain initialize (<unknown-source-location>);

define variable *unknown-srcloc* :: false-or(<unknown-source-location>) = #f;
define variable *unknown-srcloc-counter* :: <integer> = 0;

define method make
    (class == <unknown-source-location>, #next next-method, #key)
    => res :: <unknown-source-location>;
  *unknown-srcloc-counter* := *unknown-srcloc-counter* + 1;
  *unknown-srcloc* | (*unknown-srcloc* := next-method());
end method make;
  
define sealed method describe-source-location
    (srcloc :: <unknown-source-location>, stream :: <stream>)
    => ();
  format(stream, "unknown source location");
end method describe-source-location;

add-make-dumper(#"unknown-source-location", *compiler-dispatcher*,
		<unknown-source-location>, #());


// Source files.

define constant <file-contents> = type-union(<buffer>, <byte-vector>);

define inline method make-buffer (size :: <integer>)
    => res :: <file-contents>;
  make(<buffer>, size: size);
end method make-buffer;

define method fill-buffer (buf :: <buffer>, stream :: <stream>) => ();
  block ()
    read-into!(stream, buf.size, buf);
  exception (inc-read :: <incomplete-read-error>)
    copy-into-buffer!(buf, 0, inc-read.stream-error-sequence);
  exception (<end-of-stream-error>)
    #f;
  end; 
end method fill-buffer;

// <source> -- exported.
//
// Anything that gives us source code, be it a file, database
// or user input.
//
define abstract class <source> (<identity-preserving-mixin>)
end class <source>;

define sealed domain make (singleton(<source>));
define sealed domain initialize (<source>);

define method extract-line
    (source :: <source>, line-start :: <integer>) => res :: <byte-string>;
  let contents = source.contents;
  for (index from line-start below contents.size,
       until: contents[index] == as(<integer>, '\n')
	      | contents[index] == as(<integer>, '\r'))
  finally
    let len = index - line-start;
    let result = make(<byte-string>, size: len);
    copy-bytes(result, 0, contents, line-start, len);
    result;
  end for;
end method extract-line;


// <source-file> -- exported.
// 
define class <source-file> (<source>)
  //
  // The name for this source file.
  constant slot source-locator :: <file-locator>,
    required-init-keyword: #"locator";
  //
  // The contents, or #f if we haven't read them in yet.
  slot %contents :: false-or(<file-contents>) = #f;
end;

define sealed domain make (singleton(<source-file>));
define sealed domain initialize (<source-file>);

define function file-name (source-file :: <source-file>) => name :: <string>;
  source-file.source-locator.locator-name
end function file-name;

define sealed method source-name (src :: <source-file>)
  src.file-name;
end method source-name;

define method print-object (sf :: <source-file>, stream :: <stream>) => ();
  pprint-fields(sf, stream, name: sf.file-name);
end;

// contents -- exported
//
// Return the contents of the source file as a buffer.  If we have
// never done this before, we read the entire file and stash the
// results so that we don't have to read the file again.  And so that
// we don't have to come up with some silly interface to read parts of
// the file and switch back and forth.
// 
define method contents (source :: <source-file>)
 => contents :: <file-contents>;
  source.%contents
    | begin
	let file = make(<file-stream>, locator: source.source-locator);
	block ()
	  let result = make-buffer(file.stream-size);
	  fill-buffer(result, file);
	  source.%contents := result;
	cleanup
	  close(file);
	end block;
      end;
end method contents;





add-make-dumper(#"source-file", *compiler-dispatcher*, <source-file>,
		list(source-locator, locator:, #f));


// <source-buffer> -- exported.
// 
define class <source-buffer> (<source>)
  //
  // The name for this source buffer
  constant slot buffer-name :: <byte-string> = "<anonymous source buffer>", 
    init-keyword: #"name";
  //
  // The contents, or #f if we haven't read them in yet.
  slot contents,             // FIXME: which type?
    required-init-keyword: #"buffer";
end;


define sealed domain make (singleton(<source-buffer>));
define sealed domain initialize (<source-buffer>);

define sealed method source-name (src :: <source-buffer>)
  src.buffer-name;
end method source-name;

define method print-object (sb :: <source-buffer>, stream :: <stream>) => ();
  pprint-fields(sb, stream, name: sb.buffer-name);
end;


add-make-dumper(#"source-buffer", *compiler-dispatcher*, <source-buffer>,
		list(buffer-name, name:, #f));




define class <known-source-location> (<source-location>)
  constant slot source :: <source>,
    required-init-keyword: source:;

  constant slot start-posn :: <integer>,
    required-init-keyword: start-posn:;
  
  constant slot start-line :: <integer>,
    required-init-keyword: start-line:;
  
  constant slot start-column :: <integer>,
    required-init-keyword: start-column:;
  
  constant slot end-posn :: <integer>,
    required-init-keyword: end-posn:;
  
  constant slot end-line :: <integer>,
    required-init-keyword: end-line:;
  
  constant slot end-column :: <integer>,
    required-init-keyword: end-column:;
end;

define sealed domain make (singleton(<known-source-location>));
define sealed domain initialize (<known-source-location>);

define sealed method describe-source-location
    (srcloc :: <known-source-location>, stream :: <stream>)
    => ();
  pprint-logical-block
    (stream,
     body:
       method (stream :: <stream>)
	 local method corrupted-file() => ();
		 format(stream, "<<< file \"%s\" seems to be corrupted >>>", srcloc.source.source-name);
		 pprint-newline(#"mandatory", stream);
	       end;
		 
	 if (srcloc.end-line <= srcloc.start-line)
	   if (srcloc.end-column <= srcloc.start-column)
	     format(stream, "\"%s\", line %d, before character %d:",
		    srcloc.source.source-name, srcloc.start-line,
		    srcloc.start-column + 1);
	   elseif (srcloc.end-column == srcloc.start-column + 1)
	     format(stream, "\"%s\", line %d, character %d:",
		    srcloc.source.source-name, srcloc.start-line,
		    srcloc.start-column + 1);
	   else
	     format(stream, "\"%s\", line %d, characters %d through %d:",
		    srcloc.source.source-name, srcloc.start-line,
		    srcloc.start-column + 1, srcloc.end-column);
	   end if;
	   pprint-newline(#"mandatory", stream);
	   block (return)
	     let line
	       = begin
		   let handler (<file-does-not-exist-error>)
		     = method (cond, next-handler) return() end method;
		   extract-line(srcloc.source,
				srcloc.start-posn - srcloc.start-column);
		 end;
	     highlight-line(line, srcloc.start-column, srcloc.end-column,
			    stream);
	   
	   exception (<error>)
	     corrupted-file();
	   end block;
	 else
	   format(stream,
		  "\"%s\", line %d, character %d through "
		    "line %d, character %d:",
		  srcloc.source.source-name, srcloc.start-line,
		  srcloc.start-column + 1, srcloc.end-line,
		  srcloc.end-column);
	   pprint-newline(#"mandatory", stream);
	   block (return)
	     let (first-line, last-line)
	       = begin
		   let handler (<file-does-not-exist-error>)
		     = method (cond, next-handler) return() end method;
		   values(extract-line
			    (srcloc.source,
			     srcloc.start-posn - srcloc.start-column),
			  extract-line
			    (srcloc.source,
			     srcloc.end-posn - srcloc.end-column));
		 end;
	     highlight-line(first-line, srcloc.start-column,
			    first-line.size, stream);
	     unless (srcloc.start-line + 1 == srcloc.end-line)
	       write(stream, "  through");
	     end unless;
	     pprint-newline(#"mandatory", stream);
	     highlight-line(last-line, 0, srcloc.end-column, stream);
	   
	   exception (<error>)
	     corrupted-file();
	   end block;
	 end if;
       end method);
  write(stream, "  ");
end method describe-source-location;

define method print-object (sl :: <source-location>, stream :: <stream>)
    => ();
  describe-source-location(sl, stream);
end;



// file source locations.


define method highlight-line
    (line :: <byte-string>, start-char :: <integer>, end-char :: <integer>,
     stream :: <stream>)
    => ();
  write(stream, "    ");
  local method repeat (index :: <integer>, column :: <integer>)
	  if (index < line.size)
	    let char = line[index];
	    if (char == '\t')
	      let new-column = floor/(column + 8, 8) * 8;
	      for (column from column below new-column)
		write-element(stream, ' ');
	      end for;
	      repeat(index + 1, new-column);
	    else
	      write-element(stream, char);
	      repeat(index + 1, column + 1);
	    end if;
	  end if;
	end method repeat;
  repeat(0, 0);
  pprint-newline(#"mandatory", stream);
  let start-column = compute-column(line, start-char);
  if (start-char < end-char)
    let end-column = compute-column(line, end-char);
    for (column from 0 below start-column + 4)
      write-element(stream, ' ');
    end for;
    for (column from start-column below end-column)
      write-element(stream, '^');
    end for;
  else
    for (column from 0 below start-column + 3)
      write-element(stream, ' ');
    end for;
    write(stream, "/\\");
  end if;
  pprint-newline(#"mandatory", stream);
end method highlight-line;


define method compute-column (line :: <byte-string>, target :: <integer>)
 => col :: <integer>;
  for (i from 0 below target,
       column = 0
	 then if (line[i] == '\t')
		floor/(column + 8, 8) * 8;
	      else
		column + 1;
	      end if)
  finally
    column;
  end for;
end method compute-column;


// extract-string -- exported.
//
// Extracts the text behind the source location and returns it as a string.
// Does no processing of the input.  The start: and end: keywords can
// be used to adjust exactly where to start and end the string.
// 
define method extract-string
    (source-location :: <known-source-location>,
     #key start :: <integer> = -1,
          end: finish :: <integer> = -1)
 => string :: <byte-string>;
  if (start < 0)
    start := source-location.start-posn;
  end;
  if (finish < 0)
    finish := source-location.end-posn;
  end;
  let len = finish - start;
  if (len.positive?)
    let result = make(<string>, size: len);
    copy-bytes(result, 0, source-location.source.contents, start, len);
    result;
  else
    "";
  end if;
end;



define constant $source-file-location-words = 6;

// We represent most slots in known source locations as raw data to save
// space/time.  The only subobject is the source.
//
define method dump-od (obj :: <known-source-location>, buf :: <dump-state>)
 => ();
  let start-pos = buf.current-pos;
  dump-definition-header(#"known-source-location", buf, subobjects: #t,
  			 raw-data: $odf-word-raw-data-format);
  dump-word($source-file-location-words, buf);
  dump-word(obj.start-posn, buf);
  dump-word(obj.start-line, buf);
  dump-word(obj.start-column, buf);
  dump-word(obj.end-posn, buf);
  dump-word(obj.end-line, buf);
  dump-word(obj.end-column, buf);
  dump-od(obj.source, buf);
  dump-end-entry(start-pos, buf);
end method;

add-od-loader(*compiler-dispatcher*, #"known-source-location",
  method (state :: <load-state>) => res :: <known-source-location>;
    let nbytes = $source-file-location-words * $word-bytes;
    let (buf, next) = buffer-at-least(nbytes + $word-bytes, state);
    let s-posn = buffer-word(buf, next + (1 * $word-bytes));
    let s-line = buffer-word(buf, next + (2 * $word-bytes));
    let s-column = buffer-word(buf, next + (3 * $word-bytes));
    let e-posn = buffer-word(buf, next + (4 * $word-bytes));
    let e-line = buffer-word(buf, next + (5 * $word-bytes));
    let e-column = buffer-word(buf, next + (6 * $word-bytes));
    let file = load-object-dispatch(state);
    assert-end-object(state);
    make(<known-source-location>,
         source: file,
         start-posn: s-posn,
	 start-line: s-line,
	 start-column: s-column,
	 end-posn: e-posn,
	 end-line: e-line,
	 end-column: e-column);
    end method
);

