module: indenting-streams
author: William Lott

//======================================================================
//
// Copyright (c) 1996  Carnegie Mellon University
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

// Types:
//   <indenting-stream>
//      Wrapper stream which outputs indented text with conversions of
//      spaces into tabs.  Keywords include "inner-stream:" and
//      "indentation:".  indentation: is the initial indentation of
//      the stream (default 0); change with the indent() function.
//
// Functions:
//   indent(stream :: <indenting-stream>, delta :: <integer>)
//      Changes the current indentation for stream text.
//   inner-stream(stream :: <indenting-stream>)
//      Returns the inner-stream.



define sealed class <indenting-stream> (<wrapper-stream>)
  slot is-after-newline? :: <boolean> = #t;
  slot is-column :: <integer> = 0;
  slot is-indentation :: <integer> = 0, init-keyword: indentation:;
end;

define sealed domain make(singleton(<indenting-stream>));
define sealed domain initialize(<indenting-stream>);

define method write-element
    (stream :: <indenting-stream>, elt :: <character>) => ()
  if (stream.is-after-newline?)
    for (i from 0 below stream.is-indentation)
      write-element(stream.inner-stream, ' ');
    end;
    stream.is-after-newline? := #f;
  end if;
  write-element(stream.inner-stream, elt);
  if (elt == '\t')
    stream.is-column := stream.is-column + 8 - truncate/(stream.is-column, 8);
  else
    stream.is-column := stream.is-column + 1;
  end;
end method write-element;

define method write
    (stream :: <indenting-stream>, elements :: <sequence>,
     #key start: _start = 0, end: _end = elements.size) => ()
  if (stream.is-after-newline?)
    for (i from 0 below stream.is-indentation)
      write-element(stream.inner-stream, ' ');
    end;
    stream.is-after-newline? := #f;
  end if;
  write(stream.inner-stream, elements, start: _start, end: _end);
  for (i from _start below _end,
       col = stream.is-column
         then if (elements[i] = '\t')
                col + 8 - truncate/(col, 8)
              else
                col + 1
              end)
  finally
    stream.is-column := col;
  end;
end method write;

define method new-line (stream :: <indenting-stream>) => ()
  stream.is-after-newline? := #t;
  stream.is-column := 0;
  new-line(stream.inner-stream)
end method new-line;

define method discard-output
    (stream :: <indenting-stream>) => ()
  stream.is-after-newline? := #t;
  stream.is-column := 0;
  discard-output(stream.inner-stream)
end method discard-output;

define method close (stream :: <indenting-stream>, #key, #all-keys) => ();
  force-output(stream);
end;

define method indent (stream :: <indenting-stream>, delta :: <integer>)
    => ();
  stream.is-indentation := stream.is-indentation + delta;
end;
