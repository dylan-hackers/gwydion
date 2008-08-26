Module:       format-internals
Author:       Scott McKay, Peter S. Housel
Synopsis:     This file implements 'format' to buffered output streams
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Faster 'format' to buffered output streams

// Assumes, but does not verify, that the output buffer is held
define method buffered-write-element
    (stream :: <buffered-stream>, sb :: <buffer>, elt :: <object>) => ()
  if (sb.buffer-next >= sb.buffer-size)
    sb := do-next-output-buffer(stream, bytes: 1)
  end;
  let bi :: <buffer-index> = sb.buffer-next;
  coerce-from-element(stream, sb, bi, elt);
  sb.buffer-dirty? := #t;
  sb.buffer-next := bi + 1;
  sb.buffer-end  := max(bi + 1, sb.buffer-end)
end method buffered-write-element;

// Assumes, but does not verify, that the output buffer is held
define method buffered-write
    (stream :: <buffered-stream>, sb :: <buffer>, elements :: <sequence>,
     #key start: _start = 0, end: _end = unsupplied()) => ()
  let i :: <integer> = _start;
  let e :: <integer> = if (supplied?(_end)) _end else elements.size end;
  while (sb & (i < e))
    let bi :: <buffer-index> = sb.buffer-next;
    let bufsiz :: <buffer-index> = sb.buffer-size;
    if (bi >= bufsiz)
      sb := do-next-output-buffer(stream)
    else
      let count = min(bufsiz - bi, e - i);
      coerce-from-sequence(stream, sb, bi, elements, i, count);
      sb.buffer-dirty? := #t;
      i := i + count;
      sb.buffer-next := bi + count;
      sb.buffer-end  := max(bi + count, sb.buffer-end)
    end
  end;
  if (i < e)
    signal(make(<end-of-stream-error>, stream: stream))
  end
end method buffered-write;

define method format
    (stream :: <buffered-stream>, control-string :: <byte-string>, #rest args) => ()
  let control-len :: <integer> = control-string.size;
  block (exit)
    let start :: <integer> = 0;
    let arg-i :: <integer> = 0;
    // Ensure all output is contiguous at stream's destination.
    lock-stream(stream);
    // Grab the output buffer, and don't let go for a while
    let sb = get-output-buffer(stream);
    // The rest is just like the non-buffered case of 'format',
    // except that we use the two functions above...
    while (start < control-len)
      // Skip to dispatch char.
      for (i = start then (i + 1),
           until: ((i == control-len)
                   | (control-string[i] == $dispatch-char)
                   | (control-string[i] == '\n')))
      finally
        if (i ~== start)
          buffered-write(stream, sb, control-string, start: start, end: i);
        end;
        if (i == control-len)
          exit()
        else
          start := i + 1
        end
      end;
      if (control-string[start - 1] == '\n')
        new-line(stream)
      else
        // Parse conversion modifier flags
        let (flags, left-justified?, zero-fill?, flags-end)
          = parse-flags(control-string, start);
        
        // Parse for field width within which to pad output.
        let (width, width-end, width-arg?)
          = parse-width(control-string, flags-end, args, arg-i);
        if (width-arg?)
          arg-i := arg-i + 1;
        end;
        if (width < 0)
          left-justified? := #t;
          width := -width;
        end;
        
        // Parse precision specifier
        let (precision, precision-end, precision-arg?)
          = parse-precision(control-string, width-end, args, arg-i);
        if (precision-arg?)
          arg-i := arg-i + 1;
        end;
        
        if (width > 0)
          // Capture output in string and compute padding.
          // Assume the output is very small in length.
          let s = make(<byte-string-stream>,
                       contents: make(<byte-string>, size: 80),
                       direction: #"output");
          if (do-dispatch(control-string[precision-end], s,
                          element(args, arg-i, default: #f),
                          flags, zero-fill? & width, precision))
            arg-i := arg-i + 1
          end;
          let output = s.stream-contents;
          let output-len :: <integer> = output.size;
          let padding :: <integer> = width - output-len;
          let fill :: <character> = if (zero-fill?) '0' else ' ' end if;
          case
            (padding <= 0) =>
              buffered-write(stream, sb, output);
            (left-justified?) =>
              buffered-write(stream, sb, output);
              buffered-write(stream, sb,
                             make(<byte-string>, size: padding, fill: ' '));
            otherwise =>
              buffered-write(stream, sb,
                             make(<byte-string>, size: padding, fill: fill));
              buffered-write(stream, sb, output);
          end;
        else
          if (buffered-do-dispatch(control-string[precision-end], stream, sb,
                                   element(args, arg-i, default: #f),
                                   flags, #f, precision))
            arg-i := arg-i + 1
          end;
        end;
        start := precision-end + 1 // Add one to skip dispatch char.
      end
    end while;
  cleanup
    unlock-stream(stream)
  end
end method format;

define method buffered-do-dispatch
    (char :: <byte-character>, stream :: <buffered-stream>, sb :: <buffer>,
     arg, flags :: <list>,
     width :: false-or(<integer>), precision :: false-or(<integer>))
 => (consumed-arg? :: <boolean>)
  select (char by \==)
    ('s'), ('S') =>
      if (instance?(arg, <byte-string>))
        // Simulate "write-message" upon the argument.  This code must be
        // changed if the semantics of "write-message" changes.
        buffered-write(stream, sb, arg)
      else
        print-message(arg, stream)
      end;
      #t;
    ('c'), ('C') =>
      select (arg by instance?)
        <byte-character> =>
          buffered-write-element(stream, sb, arg);
        <character> =>
          print-message(arg, stream);
        otherwise =>
          error("The %%C format directive only works for characters: %=", arg);
      end;
      #t;
    ('=') =>
      dynamic-bind (*print-escape?* = #t)
        print-object(arg, stream)
      end;
      #t;
    ('d'), ('D') =>
      apply(buffered-format-integer, arg, 10, width, precision, stream, sb,
            flags);
      #t;
    ('b'), ('B') =>
      apply(buffered-format-integer, arg,  2, width, precision, stream, sb,
            flags);
      #t;
    ('o'), ('O') =>
      apply(buffered-format-integer, arg,  8, width, precision, stream, sb,
            flags);
      #t;
    ('x'), ('X') =>
      apply(buffered-format-integer, arg, 16, width, precision, stream, sb,
            flags);
      #t;
    ('e'), ('E') =>
      apply(format-float-exponential, arg, precision, stream, flags);
      #t;
    ('f'), ('F') =>
      apply(format-float-fixed, arg, precision, stream, flags);
      #t;
    ('g'), ('G') =>
      apply(format-float-general, arg, precision, stream, flags);
      #t;
    ('m'), ('M') =>
      apply(arg, list(stream));
      #t;
    ('%') =>
      buffered-write-element(stream, sb, '%');
      #f;
    otherwise =>
      error("Unknown format dispatch character, %c", char);
  end
end method buffered-do-dispatch;

define method buffered-format-integer
    (arg :: <abstract-integer>, radix :: limited(<integer>, min: 2, max: 36),
     width :: false-or(<integer>),
     precision :: false-or(<integer>),
     stream :: <stream>, sb :: <buffer>,
     #key plus-sign :: false-or(<character>),
          alternate-form? :: <boolean>,
     #all-keys)
 => ();
  // Define an iteration that collects the digits for the print
  // representation of arg.
  local
    method repeat (arg :: <abstract-integer>, digits :: <list>,
                   count :: <integer>, sign? :: <boolean>)
          let (quotient :: <abstract-integer>, remainder :: <abstract-integer>)
            = floor/(arg, radix);
          let digits = pair($digits[as(<integer>, remainder)], digits);
          if (~zero?(quotient) | (precision & count < precision))
            repeat(quotient, digits, count + 1, sign?);
          else
            zero-pad(if (sign?) count + 1 else count end);
            for (digit in digits)
              buffered-write-element(stream, sb, digit);
            end
          end;
    end,
    method zero-pad (count :: <integer>) => ();
      if (width)
        for (i from count below width)
          buffered-write-element(stream, sb, '0');
        end;
      end;
    end;

  // Set up for the iteration.
  if (negative?(arg))
    buffered-write-element(stream, sb, '-');
    // Pick off one digit before beginning the iteration to ensure that we
    // don't need Generic-arithmetic.  If arg were the mininum signed
    // machine word, and we simply negated it and called repeat, then it
    // would turn into an integer that was one larger than the maximum
    // signed integer.
    let (quotient :: <abstract-integer>, remainder :: <abstract-integer>)
      = truncate/(arg, radix);
    if (~zero?(quotient) | (precision & 1 < precision))
      repeat(- quotient, list($digits[as(<integer>, - remainder)]), 2, #t);
    else
      zero-pad(2);
      buffered-write-element(stream, sb, $digits[as(<integer>, - remainder)]);
    end
  else
    if (plus-sign)
      buffered-write-element(stream, sb, plus-sign);
    end if;
    if (~zero?(arg) | ~precision | 0 < precision)
      repeat(arg, #(), 1, true?(plus-sign));
    end if;
  end
end method;

define method buffered-format-integer
    (arg :: <float>, radix :: limited(<integer>, min: 2, max: 36),
     width :: false-or(<integer>),
     precision :: false-or(<integer>),
     stream :: <buffered-stream>, buffer :: <buffer>,
     #key, #all-keys) => ()
  //--- Should we really be this compulsive?
  assert(radix = 10, "Can only print floats in base 10");
  print(arg, stream)
end method buffered-format-integer;
