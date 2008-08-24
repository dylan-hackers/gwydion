module: main
copyright: see below
synopsis: Translate binary DU format to text.


//======================================================================
//
// Copyright (c) 2008  Gwydion Dylan Maintainers
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


// This file provides the output for the --dump-du switch. Each line of output
// is an ODF object. An ODF object may have a label (if it is the target of a
// forward or external reference), data content, and sub-objects, all optional.
// The label and content is displayed on the line and sub-objects are indented
// and displayed on subsequent lines. A sub-object can be a forward reference
// within the same library (labeled with double brackets) or an external
// reference to another library (labeled with brackets). Here is some sample
// output:
//
// extern-index
//   extern-handle [0]  8C8C908E 00000000 0000079A 
//     byte-symbol  #"io"
//     file-locator  "usr/local/lib/dylan/2.5.0pre3/intel-darwin-gcc4/io.lib.du"
//   extern-handle [1]  8C8C908E 00000000 00000043 
// ...
// define-binding-tlf  
//   class-definition [[2]]  
//     ...
//     defined-class [[4]]  
//       constant-info  
//         ...
//       [[4]]
//       basic-name  
//         byte-symbol  #"<basic-wrapper-stream>"
//       list  
//         [0]
// 
// The second line ("extern-handle [0]") is an ODF #"extern-handle" object.
// This is a reference to a particular ODF object in the IO library. The last
// line ("[0]") is referring to the second line, and should be taken to mean
// the ODF object in the IO library. Similarly, the thirteenth line ("[[4]]")
// is a reference to the ODF object on the tenth line ("defined-class [[4]]").
// This means the #"defined-class" on line ten is self-referential: its second
// sub-object (on line thirteen) is the #"defined-class" object itself.
// 
// Reference labels are in hexadecimal for easier cross-referencing with an
// extern-handle.
//
// Note that in actual usage, all references are replaced by their referents
// or a <forward-ref> object, even across libraries.


define function dump-text-du
    (unit-name :: <byte-string>, file :: <byte-string>)
 => ();
  format(*debug-output*, "Dumping library summary as text.\n", file);
  let stream = make(<file-stream>, locator: file, direction: #"output");
  let ind-stream = make(<indenting-stream>,
                        inner-stream: stream,
                        output-tab-width: #f);
  *extern-count* := 0;
  let du = find-data-unit(as(<symbol>, unit-name), $library-summary-unit-type,
                          check-hash: #f, load-external: #f,
                          dispatcher: make-dispatcher(ind-stream));
  close(stream);
end function;


define function make-dispatcher (stream :: <indenting-stream>)
 => dispatcher :: <dispatcher>;
  let dispatcher = make(<dispatcher>, initialize-from: #f);
  let entry-types = registered-object-ids();
  for (unusable-entry in #[ #"32bit-data-unit", #"64bit-data-unit" ])
    entry-types := remove!(entry-types, unusable-entry);
  end for;

  for (entry-type in entry-types)
    add-od-loader(dispatcher, entry-type,
        method (state :: <load-state>, flags :: <integer>,
                label :: false-or(<integer>),
                default-loader :: false-or(<function>))
         => (obj :: <object>)
          load-and-format-odf-entry(state, flags, label, default-loader,
                                    entry-type, stream);
        end method);
  end for;
  dispatcher;
end function;


// We handle extern references ourselves, because we need to display them.
// The od-format library would normally build <extern-ref>s and put them in
// a vector for extern-index. Instead, we build <extern-marker>s and put them
// in a vector.
//
define variable *extern-count* :: <integer> = 0;
define class <extern-marker> (<object>)
  constant slot index :: <integer>, required-init-keyword: index:;
end class;


// Element types to delegate to default dispatcher. These are elemental ODF
// types without sub-objects.
//
define constant $default-loader-entries
  = #[ #"local-index", #"local-object-map",
       #"true", #"false", #"fixed-integer", #"extended-integer",
       #"file-locator", #"byte-string", #"byte-symbol", #"byte-character" ];

  
// The load state and buffer can't handle state.od-next being forced to some
// value, so avoid doing that.
//
define method load-and-format-odf-entry
    (state :: <load-state>, flags :: <integer>, label :: false-or(<integer>),
     default-loader :: false-or(<function>), entry-type :: <symbol>,
     stream :: <indenting-stream>)
 => obj :: <object>;
  // Print entry label and type.
  format(stream, "%s", as(<string>, entry-type));
  if (label)
    format(stream, " [[%x]]", label);
  end if;
  if (entry-type = #"extern-handle")
    format(stream, " [%x]", *extern-count*);
    *extern-count* := *extern-count* + 1;
  end if;
  write(stream, "  ");

  // Delegate to default dispatcher?
  let default-entry-type?
    = default-loader & member?(entry-type, $default-loader-entries);
    
  // Get info.
  let has-data?
    = logand(flags, $odf-raw-format-mask) ~= $odf-no-raw-data-format;
  let has-subobjects?
    = logand(flags, $odf-subobjects-flag) = $odf-subobjects-flag;
    
  // Get raw data size if we need it.
  let (data-size, padding-size)
    = if (~default-entry-type?) 
        odf-data-size(state, flags);
      else
        values(0, 0);
      end if;
  
  // Get data or delegate that to default dispatcher.
  let data
    = if (default-entry-type?)
        default-loader(state);
      else
        let buf = make(<byte-string>, size: data-size);
        if (data-size > 0)
          // Read raw data then advance past padding.
          load-raw-data(buf, data-size, state);
          buffer-at-least(padding-size, state);
        end if;
        buf;
      end if;

  // Print data (if any).
  if (has-data?)
    format-raw-data(stream, flags, data, entry-type);
  end if;
  new-line(stream);

  // Print sub-objects (if any).
  let subobjects = make(<stretchy-vector>);
  if (has-subobjects?)
    indent(stream, +2);
    for (sub = load-object-dispatch(state) then load-object-dispatch(state),
         until: sub == $end-object)
      add!(subobjects, sub);
      case
        instance?(sub, <forward-ref>) =>
          if (sub.forward-ref-id)
            format(stream, "[[%x]]\n", sub.forward-ref-id)
          else
            write(stream, "[[unknown forward reference]]");
          end if;
        instance?(sub, <extern-marker>) & entry-type ~= #"extern-index" =>
          format(stream, "[%x]\n", sub.index);
      end case;
    end for;
    indent(stream, -2);
  end if;

  // Special return values for extern handling.
  select (entry-type)
    #"extern-index" => as(<simple-object-vector>, subobjects);
    #"extern-handle" => make(<extern-marker>, index: *extern-count* - 1);
    otherwise => data;
  end select;
end method;


// Only call this if we aren't using a default loader, because we may need to
// buffer a word to get the size and that will confuse the loader.
//
define method odf-data-size (state :: <load-state>, flags :: <integer>)
 => (data-size :: <integer>, padding-size :: <integer>);
  let raw-data-format = logand(flags, $odf-raw-format-mask);
  let size-unit
    = select (raw-data-format)
        $odf-no-raw-data-format => 0;
        $odf-byte-raw-data-format => 1;
        $odf-16bit-raw-data-format => 2;
        $odf-32bit-raw-data-format => 4;
        $odf-64bit-raw-data-format => 8;
        $odf-word-raw-data-format => $word-bytes;
        otherwise =>
          error("Untranslatable or unrecognized raw data format at index %d",
                raw-data-format, state.od-next);
      end select;
  let data-size
    = select (size-unit)
        0 => 0;
        otherwise =>
          let (buf, next) = buffer-at-least($word-bytes, state);
          buffer-word(buf, next) * size-unit;
      end select;
  let padding-size
    = if (modulo(data-size, $word-bytes) ~= 0)
        $word-bytes - modulo(data-size, $word-bytes);
      else
        0
      end if;
  values(data-size, padding-size);
end method;


define method format-raw-data
    (stream :: <stream>, flags :: <integer>, data :: <object>,
     entry-type :: <symbol>)
 => ();
  let raw-data-format = logand(flags, $odf-raw-format-mask);
  let group-every
    = select (raw-data-format)
        $odf-byte-raw-data-format => 1;
        $odf-16bit-raw-data-format => 2;
        $odf-32bit-raw-data-format => 4;
        $odf-64bit-raw-data-format => 8;
        $odf-word-raw-data-format => $word-bytes;
      end select;
  let data-size = data.size;
  let capped-data-size = min(16, data-size);
  for (i from 0 below capped-data-size)
    format(stream, "%02x", as(<integer>, data[i]));
    if (modulo(i + 1, group-every) == 0)
      write-element(stream, ' ');
    end if;
  end for;
  if (data-size > capped-data-size)
    format(stream, "... (%d bytes)", data-size);
  end if;
end method;

define method format-raw-data
    (stream :: <stream>, flags :: <integer>, data :: <object>,
     entry-type :: one-of(#"local-index", #"local-object-map"))
 => ();
  let raw-data-format = logand(flags, $odf-raw-format-mask);
  let elem-size
    = select (raw-data-format)
        $odf-byte-raw-data-format => 1;
        $odf-16bit-raw-data-format => 2;
        $odf-32bit-raw-data-format => 4;
        $odf-64bit-raw-data-format => 8;
        $odf-word-raw-data-format => $word-bytes;
      end select;
  let (field, cap)
    = select (elem-size)
        1 => values("%02x", 16);
        2 => values("%04x", 8);
        4 => values("%08x", 4);
        8 => values("%016x", 2);
      end select;
  let data-size = data.size;
  let capped-data-size = min(cap, data-size);
  for (i from 0 below capped-data-size)
    format(stream, field, data[i]);
    write-element(stream, ' ');
  end for;
  if (data-size > capped-data-size)
    format(stream, "... (%d bytes)", data-size * elem-size);
  end if;
end method;

define method format-raw-data
    (stream :: <stream>, flags :: <integer>, data :: <object>,
     entry-type :: one-of(#"fixed-integer", #"extended-integer", #"ratio",
                          #"single-float"))
 => ()
  format(stream, "%s", data);
end method;

define method format-raw-data
    (stream :: <stream>, flags :: <integer>, data :: <object>,
     entry-type :: one-of(#"file-locator", #"byte-string"))
 => ();
  format(stream, "\"%s\"", as(<string>, data));
end method;

define method format-raw-data
    (stream :: <stream>, flags :: <integer>, data :: <object>,
     entry-type == #"byte-symbol")
 => ();
  format(stream, "#\"%s\"", as(<string>, data));
end method;

define method format-raw-data
    (stream :: <stream>, flags :: <integer>, data :: <object>,
     entry-type == #"byte-character")
 => ();
  format(stream, "'%c'", data);
end method;
