module: common-extensions

//=========================================================================
//  unsupplied, unfound.
//=========================================================================
//  Unique objects which can be used as default values for keywords and
//  passed to 'default:'. These cannot be confused with any other Dylan
//  values.

//=========================================================================
//  unsupplied? related functions.
//=========================================================================

define inline function unsupplied ()
    => (unsupplied-marker :: <object>)
  $unsupplied;
end function unsupplied;

define inline function unsupplied? (object :: <object>)
    => (unsupplied? :: <boolean>)
  object == unsupplied();
end function;

define inline function supplied? (object :: <object>)
    => (unsupplied? :: <boolean>)
  ~unsupplied?(object);
end function;

//=========================================================================
//  unfound? related functions.
//=========================================================================

define class <unfound-marker> (<object>)
end;

define constant $unfound = make(<unfound-marker>);

define inline function unfound ()
    => (unfound-marker :: <unfound-marker>)
  $unfound;
end function;

define inline function unfound? (object :: <object>)
    => (unfound? :: <boolean>)
  object == unfound();
end function;

define inline function found? (object :: <object>)
    => (found? :: <boolean>)
  ~unfound?(object);
end function;


#if (~bootstrap)
//=========================================================================
//  Application environment functions.
//=========================================================================
//  Finding yourself and your arguments; exiting.

define function get-argc() => (argc :: <integer>)
  let argc = application-argc();
  if (argc < 1)
    error("Runtime is corrupted: application_argc = %d", argc());
  end;
  argc;
end;

define function application-name () => (string :: <byte-string>)
  get-argc();
  application-argv(0);
end;

define function application-filename () => (filename :: false-or(<string>))
  // XXX - I don't know how to find the application's filename under Unix.
  #f;
end;

define function application-arguments () => (string :: <simple-object-vector>)
  // XXX - Should this be our official return type? Harlequin says so.
  let argc = get-argc();
  let result = make(<simple-object-vector>, size: argc - 1);
  for (i from 1 below argc)
    result[i - 1] := application-argv(i);
  end for;
  result;
end;

define function exit-application (exit-code :: <integer>) => ()
  exit(exit-code: exit-code);
end;

#endif

//=========================================================================
//  Ignore & ignorable
//=========================================================================
//  Control compiler warnings about unused variables.

define function ignorable (#rest noise) => ()
  // XXX - This has the right API, but does nothing. Also fix ignore.
  // XXX - Does it? Should it be #rest?
end;


//=========================================================================
//  Conversions
//=========================================================================
//  Convert numbers to and from strings.

define constant $digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

// This could definitely use a copy-down version specialized for <integer>
define method integer-to-string
    (integer :: <general-integer>,
     #key base :: type-union(limited(<integer>, min: 2, max: 36)) = 10,
          size: desired-size :: false-or(<integer>),
          fill :: <character> = '0')
 => (string :: <byte-string>);
  local
    method collect
        (value :: <general-integer>, digits :: <list>, count :: <integer>)
     => (digits :: <list>, count :: <integer>);
      let (quotient, remainder) = floor/(value, base);
      let digits = pair($digits[as(<integer>, remainder)], digits);
      if(zero?(quotient))
        values(digits, count + 1);
      else
        collect(quotient, digits, count + 1);
      end if;
    end method;
  
  let (digits, count) =
    if (integer < 0)
      // strip off last digit to avoid overflow in $minimum-integer case
      let (quotient, remainder) = truncate/(integer, base);
      if (zero?(quotient))
        values(list($digits[- as(<integer>, remainder)]), 1);
      else
        collect(- quotient, list($digits[- as(<integer>, remainder)]), 1);
      end if;
    else
      collect(integer, #(), 0);
    end if;

  let min-size = if(integer < 0) count + 1 else count end;
  let string-size
    = if(desired-size) max(desired-size, min-size) else min-size end;
  let returned-string
    = make(<byte-string>, size: string-size, fill: fill);
  
  if(integer < 0)
    returned-string[0] := '-';
  end if;

  for (digit in digits, index from string-size - count)
    returned-string[index] := digit;
  end for;
  returned-string;
end method integer-to-string;

define open generic number-to-string
    (number :: <number>) => (string :: <string>);

define sealed inline method number-to-string (integer :: <general-integer>) => (string :: <string>);
  integer-to-string(integer, base: 10);
end method number-to-string;

#if (~bootstrap)
define sealed inline method number-to-string (float :: <float>) => (string :: <string>);
  float-to-string(float);
end method number-to-string;
#endif

// To do: We should probably implement string-to-general-integer too
// or generalize this function.
define method string-to-integer
    (string :: <byte-string>,
     #key base :: <integer> = 10, 
          start :: <integer> = 0, 
          end: _end :: <integer> = size(string),
          default = $unsupplied)
 => (result :: <integer>, next-key :: <integer>);
  // Set initial state
  let valid? :: <boolean> = #f;
  let negative? :: <boolean> = #f;
  let integer :: <integer> = 0;
  
  block (return)
    for (i :: <integer> from start below _end)
      let char :: <character> = string[i];
      let digit :: false-or(<integer>)
        = select (char)
            '-' =>
              if (i = start)
                negative? := #t;
              elseif (valid?)
                return(if (negative?) - integer else integer end, i);
              elseif (supplied?(default))
                return(default, i);
              else
                error("not a valid integer");
              end if;
              #f;
            '+' =>
              if (i = start)
                negative? := #f;
              elseif (valid?)
                return(if (negative?) - integer else integer end, i);
              elseif (supplied?(default))
                return(default, i);
              else
                error("not a valid integer");
              end if;
              #f;
            '0'      => 0;
            '1'      => 1;
            '2'      => 2;
            '3'      => 3;
            '4'      => 4;
            '5'      => 5;
            '6'      => 6;
            '7'      => 7;
            '8'      => 8;
            '9'      => 9;
            'A', 'a' => 10;
            'B', 'b' => 11;
            'C', 'c' => 12;
            'D', 'd' => 13;
            'E', 'e' => 14;
            'F', 'f' => 15;
            'G', 'g' => 16;
            'H', 'h' => 17;
            'I', 'i' => 18;
            'J', 'j' => 19;
            'K', 'k' => 20;
            'L', 'l' => 21;
            'M', 'm' => 22;
            'N', 'n' => 23;
            'O', 'o' => 24;
            'P', 'p' => 25;
            'Q', 'q' => 26;
            'R', 'r' => 27;
            'S', 's' => 28;
            'T', 't' => 29;
            'U', 'u' => 30;
            'V', 'v' => 31;
            'W', 'w' => 32;
            'X', 'x' => 33;
            'Y', 'y' => 34;
            'Z', 'z' => 35;
            otherwise =>
              if (valid?)
                return(if (negative?) - integer else integer end, i);
              elseif (supplied?(default))
                return(default, i);
              else
                error("not a valid integer");
              end if;
            end select;
      if (digit)
        if(digit < base)
          integer := integer * base + digit;
          valid? := #t;
        elseif (valid?)
          return(if (negative?) - integer else integer end, i);
        elseif(supplied?(default))
          return(default, i);
        else
          error("not a valid integer");
        end if;
      end if;
    end for;

    if (valid?)
      values(if (negative?) - integer else integer end, _end);
    elseif(supplied?(default))
      return(default, _end);
    else
      error("not a valid integer");
    end if;
  end block;
end method string-to-integer;

//=========================================================================
//  Macros
//=========================================================================
//  Miscellaneous macros exported from common-extensions. These are not
//  available under Mindy.
//
//  XXX - table-definer conses excessively. With more macrology, it could
//  run much faster.
//  XXX - can the name bound by 'iterate' return?

#if (~mindy)

define macro table-definer
  { define table ?:name ?eq:token { ?keys-and-values } }
    => { define constant ?name :: <table> ?eq make(<table>);
         fill-table!(?name, list(?keys-and-values)); }
  { define table ?:name :: ?type:expression ?eq:token { ?keys-and-values } }
    => { define constant ?name :: ?type ?eq make(?type);
         fill-table!(?name, list(?keys-and-values)); }
keys-and-values:
  { ?key:expression => ?value:expression, ... } => { ?key, ?value, ... }
  { } => { }
end macro;

define macro iterate
  { iterate ?:name (?clauses:*) ?:body end }
    => { %iterate-aux ?name
         %iterate-param-helper(?clauses)
         %iterate-value-helper(?clauses)
         ?body
         end }
end;

define macro %iterate-aux
  { %iterate-aux ?:name
      ?param-clauses:macro
      ?value-clauses:macro
      ?:body
    end }
    => { local method ?name (?param-clauses)
           ?body
         end;
         ?name(?value-clauses) }
end macro;

define macro %iterate-param-helper
  { %iterate-param-helper(?clauses) }
    => { ?clauses }
clauses:
  { ?:name :: ?type:*, ... }
    => { ?name :: ?type, ... }
  { ?:name :: ?type:* = ?value:*, ... }
    => { ?name :: ?type, ... }
  { } => { }
end;

define macro %iterate-value-helper
  { %iterate-value-helper(?clauses) }
    => { ?clauses }
clauses:
  { ?:name :: ?type:*, ... }
    => { #f, ... }
  { ?:name :: ?type:* = ?value:*, ... }
    => { ?value, ... }
  { } => { }
end;

define macro when
  { when (?:expression) ?:body end }
    => { if (?expression) ?body end }
end macro;

#endif

//=========================================================================
//  Hacks for mindy
//=========================================================================
#if (mindy)

define function subclass
    (cls :: <class>)
 => (subclass :: <type>);
  limited(<class>, subclass-of: cls);
end;

define constant <stretchy-object-vector> = <stretchy-vector>;

#endif
