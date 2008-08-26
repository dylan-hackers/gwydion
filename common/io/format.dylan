Module:    format-internals
Author:    Gwydion Project
Synopsis:  This file implements a simple mechanism for formatting output.
Copyright: See below.

///======================================================================
///
/// Copyright (c) 1994  Carnegie Mellon University
/// All rights reserved.
/// 
/// Use and copying of this software and preparation of derivative
/// works based on this software are permitted, including commercial
/// use, provided that the following conditions are observed:
/// 
/// 1. This copyright notice must be retained in full on any copies
///    and on appropriate parts of any derivative works.
/// 2. Documentation (paper or online) accompanying any system that
///    incorporates this software, or any part of it, must acknowledge
///    the contribution of the Gwydion Project at Carnegie Mellon
///    University.
/// 
/// This software is made available "as is".  Neither the authors nor
/// Carnegie Mellon University make any warranty about the software,
/// its performance, or its conformity to any specification.
/// 
/// Bug reports, questions, comments, and suggestions should be sent by
/// E-mail to the Internet address "gwydion-bugs@cs.cmu.edu".
///
///======================================================================
///

/// This code was modified at Functional Objects, Inc. to work with the new Streams
/// Library designed by Functional Objects and CMU.
///



/// format-to-string.
///

/// format-to-string -- Exported.
///
define generic format-to-string (control-string :: <string>, #rest args)
    => result :: <string>;

define method format-to-string (control-string :: <byte-string>, #rest args)
    => result :: <byte-string>;
  // Format-to-string is typically used for small amounts of output, so
  // use a smaller string to collect the contents.
  let s :: <byte-string-stream>
    = make(<byte-string-stream>,
           contents: make(<byte-string>, size: 32), direction: #"output");
  apply(format, s, control-string, args);
  s.stream-contents
end method;



/// Print-message.
///

/// print-message -- Exported.
///
define open generic print-message (object :: <object>, stream :: <stream>)
    => ();

define /* sealed */ method print-message (object :: <object>, stream :: <stream>)
    => ();
  dynamic-bind (*print-escape?* = #f)   // print as a string
    print-object(object, stream)
  end
end method;

define /* sealed */ method print-message (object :: <condition>, stream :: <stream>)
    => ();
  dynamic-bind (*print-escape?* = #f)   // print as a string
    print-object(object, stream)
  end
end method;

define method print-message (condition :: <format-string-condition>, stream :: <stream>)
    => ();
  apply(format, stream, condition-format-string(condition), 
        condition-format-arguments(condition))
end method;

define sealed method print-message (object :: <string>, stream :: <stream>)
    => ();
  write-text(stream, object);
end method;

define sealed method print-message (object :: <character>, stream :: <stream>)
    => ();
  write-element(stream, object);
end method;

define sealed method print-message (object :: <symbol>, stream :: <stream>)
    => ();
  write(stream, as(<string>, object));
end method;



/// Format.
///

define constant $dispatch-char = '%';

define generic format (stream :: <stream>, control-string :: <string>,
                       #rest args)
    => ();

define method format (stream :: <stream>, control-string :: <byte-string>,
                      #rest args)
    => ();
  let control-len :: <integer> = control-string.size;
  with-stream-locked (stream)
    block (exit)
      let start :: <integer> = 0;
      let arg-i :: <integer> = 0;
      // Ensure all output is contiguous at stream's destination.
      lock-stream(stream);
      while (start < control-len)
        // Skip to dispatch char.
        for (i :: <integer> = start then (i + 1),
             until: ((i == control-len)
                     | (control-string[i] == $dispatch-char)
                     | (control-string[i] == '\n')))
        finally
          if (i ~== start)
            write(stream, control-string, start: start, end: i);
          end;
          if (i == control-len)
            exit();
          else
            start := i + 1;
          end;
        end for;
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
            let s :: <byte-string-stream>
              = make(<byte-string-stream>,
                     contents: make(<byte-string>, size: 80),
                     direction: #"output");
            if (do-dispatch(control-string[precision-end],
                            s, element(args, arg-i, default: #f),
                            flags, zero-fill? & width, precision))
              arg-i := arg-i + 1;
            end;
            let output :: <byte-string> = s.stream-contents;
            let output-len :: <integer> = output.size;
            let padding :: <integer> = width - output-len;
            let fill :: <character> = if (zero-fill?) '0' else ' ' end if;
            case
              (padding <= 0) =>
                write(stream, output);
              (left-justified?) =>
                write(stream, output);
                write(stream, make(<byte-string>, size: padding, fill: ' '));
              otherwise =>
                write(stream, make(<byte-string>, size: padding, fill: fill));
                write(stream, output);
            end;
          else
            if (do-dispatch(control-string[precision-end],
                            stream, element(args, arg-i, default: #f),
                            flags, #f, precision))
              arg-i := arg-i + 1;
            end;
          end;
          start := precision-end + 1;  // Add one to skip dispatch char.
        end
      end while;
    end block;
  end with-stream-locked;
end method;
    
/// parse-flags -- Internal.
///
define method parse-flags
    (input :: <byte-string>, index :: <integer>)
 => (flags :: <list>, left-justified? :: <boolean>,
     zero-fill? :: <boolean>, index :: <integer>);
  let input-size = input.size;
  iterate loop (flags :: <list> = #(),
                left-justified? :: <boolean> = #f,
                zero-fill? :: <boolean> = #f,
                index :: <integer> = index)
    if (index = input-size)
      values(flags, left-justified?, zero-fill?, index)
    else
      select (input[index] by \==)
        ('-') =>
          loop(pair(left-justified?:, pair(#t, flags)), #t, zero-fill?,
               index + 1);
        ('+') =>
          loop(pair(plus-sign:, pair('+', flags)), left-justified?,
               zero-fill?, index + 1);
        (' ') =>
          loop(pair(plus-sign:, pair(' ', flags)), left-justified?,
               zero-fill?, index + 1);
        ('#') =>
          loop(pair(alternate-form?:, pair(#t, flags)), left-justified?,
               zero-fill?, index + 1);
        ('0') =>
          loop(pair(zero-fill?:, pair(#t, flags)), left-justified?, #t,
               index + 1);
        otherwise =>
          values(flags, left-justified?, zero-fill?, index);
      end select;
    end;
  end iterate;
end method;

/// parse-width -- Internal.
///
define method parse-width
    (input :: <byte-string>, index :: <integer>,
     args :: <sequence>, arg-i :: <integer>)
 => (width :: <integer>, index :: <integer>, arg-used? :: <boolean>);
  if (input[index] == '*')
    values(args[arg-i], index + 1, #t)
  else
    let (width :: <integer>, index :: <integer>)
      = string-to-integer(input, start: index, default: 0);
    values(width, index, #f)
  end if
end method;

/// parse-precision -- Internal.
///
define method parse-precision
    (input :: <byte-string>, index :: <integer>,
     args :: <sequence>, arg-i :: <integer>)
 => (precision :: false-or(<integer>), index :: <integer>,
     arg-used? :: <boolean>);
  if (input[index] == '.')
    if (input[index + 1] == '*')
      if (args[arg-i] < 0)
        values(#f, index + 2, #t)
      else
        values(args[arg-i], index + 2, #t)
      end if
    else
      let (precision :: <integer>, index :: <integer>)
        = string-to-integer(input, start: index + 1, default: 0);
      values(precision, index, #f)
    end if
  else
    values(#f, index, #f)
  end if
end method;

/// do-dispatch -- Internal.
///
/// This function dispatches on char, which should be a format directive.
/// The return value indicates whether to consume one format argument;
/// otherwise, consume none.
///
define method do-dispatch
    (char :: <byte-character>, stream :: <stream>, arg, flags :: <list>,
     width :: false-or(<integer>), precision :: false-or(<integer>))
 => (consumed-arg? :: <boolean>);
  select (char by \==)
    ('s'), ('S'), ('c'), ('C') =>
      print-message(arg, stream);
      #t;
    ('=') =>
      dynamic-bind (*print-escape?* = #t)       // print as an object
        print-object(arg, stream)
      end;
      #t;
    ('d'), ('D') =>
      apply(format-integer, arg, 10, width, precision, stream, flags);
      #t;
    ('b'), ('B') =>
      apply(format-integer, arg,  2, width, precision, stream, flags);
      #t;
    ('o'), ('O') =>
      apply(format-integer, arg,  8, width, precision, stream, flags);
      #t;
    ('x'), ('X') =>
      apply(format-integer, arg, 16, width, precision, stream, flags);
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
      write-element(stream, '%');
      #f;
    otherwise =>
      error("Unknown format dispatch character, %c", char);
  end;
end method;

define constant $digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

/// format-integer -- internal.
///

define method format-integer (arg :: <abstract-integer>,
                              radix :: limited(<integer>, min: 2, max: 36),
                              width :: false-or(<integer>),
                              precision :: false-or(<integer>),
                              stream :: <stream>,
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
          write-element(stream, digit);
        end;
      end;
    end,
    method zero-pad (count :: <integer>) => ();
      if (width)
        for (i from count below width)
          write-element(stream, '0');
        end;
      end;
    end;
  // Set up for the iteration.
  if (negative?(arg))
    write-element(stream, '-');
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
      write-element(stream, $digits[as(<integer>, - remainder)]);
    end
  else
    if (plus-sign)
      write-element(stream, plus-sign);
    end if;
    if (~zero?(arg) | ~precision | 0 < precision)
      repeat(arg, #(), 1, true?(plus-sign));
    end if;
  end
end method;

define method format-integer (arg :: <float>,
                              radix :: limited(<integer>, min: 2, max: 36),
                              width :: false-or(<integer>),
                              precision :: false-or(<integer>),
                              stream :: <stream>,
                              #key, #all-keys) => ()
  //--- Should we really be this compulsive?
  assert(radix = 10, "Can only print floats in base 10");
  print(arg, stream)
end method;

/// format-float-exponential -- internal.
///

define method format-float-exponential
    (v :: <float>, precision :: false-or(<integer>), stream :: <stream>,
     #key plus-sign :: false-or(<character>),
          alternate-form? :: <boolean>,
     #all-keys)
 => ();
  let precision = precision | 6;
  let v = if (negative?(v))
            write-element(stream, '-');
            -v;
          elseif (plus-sign)
            write-element(stream, plus-sign);
            v;
          else
            v;
          end;

  block (return)
    let (exponent :: <integer>, digits :: <list>) =
      if (zero?(v))
        values(1, #(0))
      elseif (v ~= v)
        write(stream, "nan");
        return();
      elseif (v + v = v)
        write(stream, "infinity");
        return();
      else
        float-decimal-digits(v, round-significant-digits: precision + 1);
      end if;
    let digits
      = if(alternate-form?) digits else strip-trailing-zeroes(digits) end;
    
    for (digit in digits, first? = #t then #f, place from 0 by -1)
      write-element(stream, $digits[as(<integer>, digit)]);
      if (first?)
        write-element(stream, '.')
      end;
    finally
      if (alternate-form?)
        for (i from place above -precision - 1 by -1)
          write-element(stream, '0');
        end;
      end if;
    end;
    write-element(stream, 'e');
    format-exponent(exponent - 1, stream);
  end block;
end method;

/// format-float-fixed -- internal.
///

define method format-float-fixed
    (v :: <float>, precision :: false-or(<integer>), stream :: <stream>,
     #key plus-sign :: false-or(<character>),
          alternate-form? :: <boolean>,
     #all-keys)
 => ();
  let precision = precision | 6;
  let v = if (negative?(v))
            write-element(stream, '-');
            -v;
          elseif (plus-sign)
            write-element(stream, plus-sign);
            v;
          else
            v;
          end;

  block (return)
    let (exponent :: <integer>, digits :: <list>) =
      if (zero?(v))
        values(0, #())
      elseif (v ~= v)
        write(stream, "nan");
        return();
      elseif (v + v = v)
        write(stream, "infinity");
        return();
      else
        float-decimal-digits(v, round-position: -precision);
      end if;
    let digits
      = if(~alternate-form?) digits else strip-trailing-zeroes(digits) end;
    
    if (exponent = 0)
      write-element(stream, '0');
    end if;
    for (digit in digits, place from exponent by -1)
      if (place = 0)
        write-element(stream, '.');
      end;
      write-element(stream, $digits[as(<integer>, digit)]);
    finally
      if (alternate-form?)
        for (i from place above -precision by -1)
          write-element(stream, '0');
        end;
        if (place = 0)
          write-element(stream, '.');
        end;
      end if;
    end for;
  end block;
end method;

/// format-float-general -- internal.
///

define method format-float-general
    (v :: <float>, precision :: false-or(<integer>), stream :: <stream>,
     #key plus-sign :: false-or(<character>),
          alternate-form? :: <boolean>,
     #all-keys)
 => ();
  let precision = precision | 6;
  let v = if (negative?(v))
            write-element(stream, '-');
            -v;
          elseif (plus-sign)
            write-element(stream, plus-sign);
            v;
          else
            v;
          end;

  block (return)
    let (exponent :: <integer>, digits :: <list>) =
      if (zero?(v))
        values(1, #(0))
      elseif (v ~= v)
        write(stream, "nan");
        return();
      elseif (v + v = v)
        write(stream, "infinity");
        return();
      else
        float-decimal-digits(v, round-significant-digits: precision);
      end if;
    let digits
      = if(alternate-form?) digits else strip-trailing-zeroes(digits) end;
    
    if (-3 <= exponent & exponent <= 0)
      write-element(stream, '0');
      if (~empty?(digits) | alternate-form?) write-element(stream, '.') end;
      for (i from exponent below 0)
        write-element(stream, '0');
      end for;
      for (digit in digits, place from exponent by -1)
        write-element(stream, $digits[as(<integer>, digit)]);
      finally
        if (alternate-form?)
          for (i from place above -precision by -1)
            write-element(stream, '0');
          end;
        end if;
      end for;
    elseif (0 < exponent & exponent - 1 < precision)
      for (digit in digits, place from exponent by -1)
        if (place = 0)
          write-element(stream, '.');
        end;
        write-element(stream, $digits[as(<integer>, digit)]);
      finally
        let limit = if (alternate-form?) exponent - precision else 0 end;
        for (i from place above limit by -1)
          write-element(stream, '0');
        end;
        if (alternate-form? & place = 0)
          write-element(stream, '.');
        end;
      end for;
    else
      for (digit in digits, first? = #t then #f, place from 0 by -1)
        write-element(stream, $digits[as(<integer>, digit)]);
        if (first?)
          write-element(stream, '.')
        end;
      finally
        if (alternate-form?)
          for (i from place above -precision by -1)
            write-element(stream, '0');
          end;
        end if;
      end for;
      write-element(stream, 'e');
      format-exponent(exponent - 1, stream);
    end if;
  end block;
end method;

// format-exponent -- internal
//

define method format-exponent (e :: <integer>, stream :: <stream>) => ();
  let e = if (e < 0)
            write-element(stream, '-');
            -e
          else
            write-element(stream, '+');
            e
          end;
  let (tens, ones) = truncate/(e, 10);
  format-integer(tens, 10, #f, #f, stream);
  write-element(stream, $digits[ones]);
end method;

// strip-trailing-zeroes -- internal
//

define function strip-trailing-zeroes (digits :: <list>) => (result :: <list>);
  if (empty?(digits))
    #()
  else
    let stripped = strip-trailing-zeroes(digits.tail);
    if (zero?(digits.head) & empty?(stripped))
      #()
    elseif (stripped == digits.tail)
      digits
    else
      pair(digits.head, stripped)
    end if
  end if
end function;
