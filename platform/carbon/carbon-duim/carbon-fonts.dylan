Module:       carbon-duim
Synopsis:     Carbon font mapping implementation
Author:       Andy Armstrong, Scott McKay, Rob Myers
Copyright:    Original Code is Copyright (c) 1999-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// carbon font management

define sealed class <carbon-font> (<object>)
  sealed slot %font-name :: <string>,
    required-init-keyword: name:;
  sealed slot %font-id :: false-or(<integer>) = #f;
  sealed slot %font-metrics :: false-or(<FontInfo*>) = #f;
end class <carbon-font>;

define sealed domain make (singleton(<carbon-font>));
define sealed domain initialize (<carbon-font>);


define abstract class <font-error> (<error>)
end class <font-error>;

define abstract class <font-name-parse-error> (<font-error>)
  sealed constant slot %font-name, required-init-keyword: name:;
end class <font-name-parse-error>;

define sealed class <font-name-numeric-field-non-numeric> (<font-name-parse-error>)
  sealed constant slot %start, required-init-keyword: start:;
  sealed constant slot %end,   required-init-keyword: end:;
  sealed constant slot %token, required-init-keyword: token:;
end class <font-name-numeric-field-non-numeric>;

/// Font mapping

/*---*** Not used yet!
define constant $carbon-font-families :: <list>
  = #(#(#"fix",        "courier", "monaco"),
      #(#"sans-serif", "helvetica", "geneva"),
      #(#"serif",      "times", "georgia"),
      #(#"symbol",     "symbol"));
*/

//--- We should compute the numbers based on either device characteristics
//--- or some user option
define constant $carbon-logical-sizes :: <simple-object-vector>
    = #[#[#"normal",     10],	// put most common one first for efficiency
	#[#"small",       8],
	#[#"large",      12],
	#[#"very-small",  6],
	#[#"very-large", 14],
	#[#"tiny",        5],
	#[#"huge",       18]];

/*---*** Not used yet!
define method install-default-text-style-mappings
    (_port :: <carbon-port>) => ()
  ignoring("install-default-text-style-mappings");
end method install-default-text-style-mappings;
      
define method can-install-entire-family?
    (_port :: <carbon-port>, duim-family, x-family :: <byte-string>)
 => (can-install? :: <boolean>)
  ignoring("can-install-entire-family?");
  #f
end method can-install-entire-family?;

define method scaleable-font-name-at-size
    (font-name :: <byte-string>, point-size :: <integer>,
     horiz-dpi :: <integer>, vertical-dpi :: <integer>)
 => (font-name :: <integer>)
  not-yet-implemented("scaleable-font-name-at-size")
end method scaleable-font-name-at-size;
*/


define sealed method do-text-style-mapping
    (_port :: <carbon-port>, text-style :: <standard-text-style>, character-set)
 => (font :: <carbon-font>)
  ignore(character-set);
  let text-style
    = standardize-text-style(_port, text-style,
			     character-set: character-set);
  let table :: <object-table> = port-font-mapping-table(_port);
  let font = gethash(table, text-style);
  font
    | begin
	ignoring("do-text-style-mapping");
	//---*** This is not right!
	make(<carbon-font>, name: "fake")
      end
end method do-text-style-mapping;

//--- This approach seems unnecessarily clumsy; we might as well just have 
//--- 'do-text-style-mapping' do the table lookup directly itself.  We shouldn't
//--- need to cons up a whole new text-style object just to map the size.
define sealed method standardize-text-style
    (_port :: <carbon-port>, text-style :: <standard-text-style>,
     #rest keys, #key character-set)
 => (text-style :: <text-style>)
  apply(standardize-text-style-size,
	_port, text-style, $carbon-logical-sizes, keys)
end method standardize-text-style;


/// Font metrics

define sealed inline method font-width
    (text-style :: <text-style>, _port :: <carbon-port>,
     #rest keys, #key character-set)
 => (width :: <integer>)
  let (font, width, height, ascent, descent)
    = apply(font-metrics, text-style, _port, keys);
  ignore(font, height, ascent, descent);
  width
end method font-width;

define sealed inline method font-height
    (text-style :: <text-style>, _port :: <carbon-port>,
     #rest keys, #key character-set)
 => (height :: <integer>)
  let (font, width, height, ascent, descent)
    = apply(font-metrics, text-style, _port, keys);
  ignore(font, width, ascent, descent);
  height
end method font-height;

define sealed inline method font-ascent
    (text-style :: <text-style>, _port :: <carbon-port>,
     #rest keys, #key character-set)
 => (ascent :: <integer>)
  let (font, width, height, ascent, descent)
    = apply(font-metrics, text-style, _port, keys);
  ignore(font, width, height, descent);
  ascent
end method font-ascent;

define sealed inline method font-descent
    (text-style :: <text-style>, _port :: <carbon-port>,
     #rest keys, #key character-set)
 => (descent :: <integer>)
  let (font, width, height, ascent, descent)
    = apply(font-metrics, text-style, _port, keys);
  ignore(font, width, height, ascent);
  descent
end method font-descent;

define sealed inline method fixed-width-font?
    (text-style :: <text-style>, _port :: <carbon-port>, #key character-set)
 => (fixed? :: <boolean>)
  ignoring("fixed-width-font?");
  #f
end method fixed-width-font?;

define sealed method font-metrics
    (text-style :: <text-style>, _port :: <carbon-port>,
     #rest keys, #key character-set)
 => (font,
     width :: <integer>, height :: <integer>, ascent :: <integer>, descent :: <integer>)
  let font :: <carbon-font>
    = apply(text-style-mapping, _port, text-style, keys);
  carbon-font-metrics(font, _port)
end method font-metrics;

define sealed method carbon-font-metrics
    (font :: <carbon-font>, _port :: <carbon-port>)
 => (font :: <carbon-font>,
     width :: <integer>, height :: <integer>, ascent :: <integer>, descent :: <integer>)
  ignoring("carbon-font-metrics");
  values(font, 100, 10, 8, 2)
end method carbon-font-metrics;


/// Text measurement

define sealed method text-size
    (_port :: <carbon-port>, char :: <character>,
     #key text-style :: <text-style> = $default-text-style,
          start: _start, end: _end, do-newlines? = #f, do-tabs? = #f)
 => (largest-x :: <integer>, largest-y :: <integer>,
     cursor-x :: <integer>, cursor-y :: <integer>, baseline :: <integer>)
  ignore(_start, _end, do-newlines?, do-tabs?);
  let string = make(<string>, size: 1, fill: char);
  text-size(_port, string, text-style: text-style)
end method text-size;

//---*** What do we do about Unicode strings?
define sealed method text-size
    (_port :: <carbon-port>, string :: <string>,
     #key text-style :: <text-style> = $default-text-style,
          start: _start, end: _end, do-newlines? = #f, do-tabs? = #f)
 => (largest-x :: <integer>, largest-y :: <integer>,
     cursor-x :: <integer>, cursor-y :: <integer>, baseline :: <integer>)
  let length :: <integer> = size(string);
  let _start :: <integer> = _start | 0;
  let _end   :: <integer> = _end   | length;
  let (font :: <carbon-font>, width, height, ascent, descent)
    = font-metrics(text-style, _port);
  ignore(width, height);
  local method measure-string
	    (font :: <carbon-font>, string :: <string>,
	     _start :: <integer>, _end :: <integer>)
	 => (x1 :: <integer>, y1 :: <integer>, 
	     x2 :: <integer>, y2 :: <integer>)
	  ignoring("measure-string");
	  values(0, 0, 100, 10)
	end method measure-string;
  case
    do-tabs? & do-newlines? =>
      next-method();		// the slow case...
    do-tabs? =>
      let tab-width :: <integer> = width * 8;
      let last-x    :: <integer> = 0;
      let last-y    :: <integer> = 0;
      let s         :: <integer> = _start;
      block (return)
	while (#t)
	  let e = position(string, '\t', start: s, end: _end) | _end;
	  let (x1, y1, x2, y2) = measure-string(font, string, s, e);
	  ignore(x1);
	  if (e = _end)
	    last-x := last-x + x2
	  else
	    last-x := floor/(last-x + x2 + tab-width, tab-width) * tab-width;
	  end;
	  max!(last-y, y2 - y1);
	  s := min(e + 1, _end);
	  when (e = _end)
	    return(last-x, last-y, last-x, last-y, ascent)
	  end
	end
      end;
    do-newlines? =>
      let largest-x :: <integer> = 0;
      let largest-y :: <integer> = 0;
      let last-x    :: <integer> = 0;
      let last-y    :: <integer> = 0;
      let s         :: <integer> = _start;
      block (return)
	while (#t)
	  let e = position(string, '\n', start: s, end: _end) | _end;
	  let (x1, y1, x2, y2) = measure-string(font, string, s, e);
	  ignore(x1);
	  max!(largest-x, x2);
	  last-x := x2;
	  inc!(largest-y, y2 - y1);
	  last-y := y2;
	  s := min(e + 1, _end);
	  when (e = _end)
	    return(largest-x, largest-y, last-x, last-y, ascent)
	  end
	end
      end;
    otherwise =>
      let (x1, y1, x2, y2) = measure-string(font, string, _start, _end);
      ignore(x1);
      values(x2, y2 - y1, x2, y2 - y1, ascent);
  end
end method text-size;
