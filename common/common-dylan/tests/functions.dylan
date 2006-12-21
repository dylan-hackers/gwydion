Module:       common-dylan-test-suite
Synopsis:     Common Dylan library test suite
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1996-2001 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Function test cases

define locators-protocol function-test supports-open-locator? ()
  //---*** Fill this in...
end function-test supports-open-locator?;

define locators-protocol function-test open-locator ()
  //---*** Fill this in...
end function-test open-locator;

define locators-protocol function-test supports-list-locator? ()
  //---*** Fill this in...
end function-test supports-list-locator?;

define locators-protocol function-test list-locator ()
  //---*** Fill this in...
end function-test list-locator;

define common-extensions function-test concatenate! ()
/*
  let my-list = #(3, 4);
  check("test concatenate! on a list", \=, concatenate!(my-list, #(5), #(6)),
	#(3, 4, 5, 6));
  check("concatenate! should have not affected my-list", \=, my-list, #(3, 4));
*/
  let my-stretchy-vector = make(<stretchy-vector>);
  add!(my-stretchy-vector, 3);
  add!(my-stretchy-vector, 4);
  let my-stretchy-vector-afterwards = make(<stretchy-vector>);
  add!(my-stretchy-vector-afterwards, 3);
  add!(my-stretchy-vector-afterwards, 4);
  add!(my-stretchy-vector-afterwards, 5);
  add!(my-stretchy-vector-afterwards, 6);
  check("test concatenate! on a stretchy-vector", \=, 
	concatenate!(my-stretchy-vector, #(5, 6)),
	my-stretchy-vector-afterwards);
  check("concatenate! should have changed my-stretchy-vector",
	\=, my-stretchy-vector, my-stretchy-vector-afterwards);
end function-test concatenate!;

define common-extensions function-test integer-length ()
  //---*** Fill this in...
end function-test integer-length;

define constant $test-error-message = "Test Error";

define class <test-error> (<error>)
end class <test-error>;

define method condition-to-string
    (error :: <test-error>) => (string :: <byte-string>)
  $test-error-message
end method condition-to-string;

define common-extensions function-test condition-to-string ()
  check-equal("condition-to-string of an error produces correct string",
              condition-to-string(make(<simple-error>, format-string: "Hello")),
              "Hello");
  check-instance?("condition-to-string of a type error produces a string",
		  <string>,
		  begin
		    let error = make(<type-error>, value: 10, type: <class>);
		    condition-to-string(error)
		  end);
  check-equal("condition-to-string of an error with a condition-to-string method",
              condition-to-string(make(<test-error>)),
              $test-error-message)
end function-test condition-to-string;

define common-extensions function-test debug-message ()
  check-false("debug-message doesn't crash", debug-message("Hello"));
  check-false("debug-message doesn't crash with incorrect format arguments",
              debug-message("Hello %s"));
end function-test debug-message;

define common-extensions function-test difference ()
  //---*** Do all collections by using dylan-test-suite collection code
  let list1 = #(1, 2, 3);
  let list2 = #(3, 4, 5);
  check("test difference #1", \=, difference(list1, list2), #(1, 2));
  check("test difference #2", \=, difference(list2, list1), #(4, 5));
  check("test difference #3", \=, difference(list1, list1), #());
  check("test difference with \\>", \=, difference(list1, list2, test: \>),
        list1);
end function-test difference;

define common-extensions function-test false-or ()
  let new-type = #f;
  check-instance?("False-or returns type",
		  <type>, new-type := false-or(<string>));
  check-instance?(format-to-string("%s is false-or(<string>)", "abc"),
		  new-type, "abc");
  check-instance?("#f is false-or(<string>)",
		  new-type, #f);
  check-false("#t is not false-or(<string>)",
              instance?(#t, new-type));
end function-test false-or;

define common-extensions function-test find-element ()
  //---*** Do all collections by using dylan-test-suite collection code
  let list1 = #("oh", "we", "like", "sheep", "like");
  check("test find-element", \=, 
	find-element(list1, method (the-element) (the-element = "like") end),
	"like");
  check("test failure find-element", \=,
	find-element(list1, method (the-element) (the-element = "thermos") end),
	#f);
  check("test failure find-element with failure as symbol", \=,
	find-element(list1, method (the-element) (the-element = "thermos") end,  
		     failure: #"heckfire"), #"heckfire");
  check("test find-element with skip: 1", \=,
	find-element(list1, method (the-element) (the-element = "like") end,
		     skip: 1), "like");
  check("skip: is too big", \=,
	find-element(list1, method (the-element) (the-element = "like") end,
		     skip: 2), #f);
end function-test find-element;

//---*** NOTE: The <double-float> results will have to be changed if
//---*** we ever implement a better printing algorithm to get more digits
define constant $float-string-mappings
  = #(#(0.0,           "0.0"),
      #(0.0d0,         "0.0d0"),
      #(1.0,           "1.0000000"),
      #(1.0d0,         "1.0000000d0"),
      #(10.0,          "10.000000"),
      #(10.0d0,        "10.000000d0"),
      #(100.0,         "100.00000"),
      #(100.0d0,       "100.00000d0"),
      #(123456789.0,   "1.2345679s8"),
      #(123456789.0d0, "1.2345678d8"));

define common-extensions function-test float-to-string ()
  for (float-mapping in $float-string-mappings)
    let float  = float-mapping[0];
    let string = float-mapping[1];
    check-equal(format-to-string("float-to-string(%d)", float),
                float-to-string(float), string)
  end;
  //---*** NOTE: Our runtime should catch 0.0 / 0.0 and signal an invalid
  //---***       float operation error rather than generating a {NaN}.
  check-equal("float-to-string(0.0 / 0.0)",
	      float-to-string(0.0 / 0.0),
	      "{NaN}");
  check-equal("float-to-string(0.0d0 / 0.0d0)",
	      float-to-string(0.0d0 / 0.0d0),
	      "{NaN}d0");
  //---*** NOTE: When we implement floating point exception control,
  //---***       replace the above two checks with the following:
/*
  check-equal("float-to-string(0.0 / 0.0)",
	      float-to-string(with-floating-exceptions-disabled ()
				0.0 / 0.0
			      end),
	      "{NaN}");
  check-equal("float-to-string(0.0d0 / 0.0d0)",
	      float-to-string(with-floating-exceptions-disabled ()
				0.0d0 / 0.0d0
			      end),
	      "{NaN}d0");
  check-equal("float-to-string(1.0 / 0.0)",
	      float-to-string(with-floating-exceptions-disabled ()
				1.0 / 0.0
			      end),
	      "+{infinity}");
  check-equal("float-to-string(1.0d0 / 0.0d0)",
	      float-to-string(with-floating-exceptions-disabled ()
				1.0d0 / 0.0d0
			      end),
	      "+{infinity}d0");
  check-equal("float-to-string(-1.0 / 0.0)",
	      float-to-string(with-floating-exceptions-disabled ()
				-1.0 / 0.0
			      end),
	      "-{infinity}");
  check-equal("float-to-string(-1.0d0 / 0.0d0)",
	      float-to-string(with-floating-exceptions-disabled ()
				-1.0d0 / 0.0d0
			      end),
	      "-{infinity}d0");
*/
end function-test float-to-string;

define common-extensions function-test ignorable ()
  check-true("ignorable doesn't crash",
             begin
               ignorable(test-function);
               #t
             end)
end function-test ignorable;

define common-extensions function-test ignore ()
  check-true("ignore doesn't crash",
             begin
               ignore(test-function);
               #t
             end)
end function-test ignore;

define constant $integer-string-mappings
  = #[#[0,     10,  "0"],
      #[1,     10,  "1"],
      #[9,     10,  "9"],
      #[1234,  10,  "1234"],
      #[10,    16,  "A"],
      #[-1,    10,  "-1"],
      #[-9,    10,  "-9"],
      #[-10,   10,  "-10"],
      #[-1234, 10,  "-1234"],
      #[-10,   16,  "-A"]];

define common-extensions function-test integer-to-string ()
  for (integer-mapping in $integer-string-mappings)
    let integer = integer-mapping[0];
    let base    = integer-mapping[1];
    let string  = integer-mapping[2];
    check-equal(format-to-string("integer-to-string(%d)", integer),
                integer-to-string(integer, base: base), string)
  end;
  check-equal("integer-to-string(10, size: 6)",
	      integer-to-string(10, size: 6),
	      "000010");
  check-equal("integer-to-string(10, size: 6, fill: ' ')",
	      integer-to-string(10, size: 6, fill: ' '),
	      "    10");
  check-equal("integer-to-string(127, base: 2, size: 8)",
	      integer-to-string(127, base: 2, size: 8),
	      "01111111");
  check-no-errors("integer-to-string($minimum-integer)",
		  integer-to-string($minimum-integer));
  check-no-errors("integer-to-string($maximum-integer)",
		  integer-to-string($maximum-integer));
end function-test integer-to-string;

define common-extensions function-test number-to-string ()
  //---*** Fill this in...
end function-test number-to-string;

define common-extensions function-test one-of ()
  let new-type = #f;
  check-instance?("one-of returns type",
		  <type>,
		  new-type := one-of(#"one", #t));
  check-instance?(format-to-string("%s is one-of(%=, #t)", #"one", #"one"),
		  new-type, #"one");
  check-instance?(format-to-string("#t is one-of(%=, #t)", #"one"),
		  new-type, #t);
  check-false(format-to-string("#f is one-of(%=, #t)", #"one"),
              instance?(#f, new-type));
end function-test one-of;

define common-extensions function-test position ()
  //---*** Do all collections by using dylan-test-suite collection code
  let list1 = #(1, 'a', 34.43, 'a', "done");
  check-equal("test position",
              position(list1, 'a'),
              1);
  check-equal("test position with skip of 2",
              position(list1, 'a', skip: 1),
              3);
  check-false("test position with wrong item",
              position(list1, 'w'));
  check-false("test posision with skip greater than existance", 
	      position(list1, 'a', skip: 2));
// The following check has been modified to match the documentation at
// http://www.fun-o.com/products/doc/core/core_66.htm#MARKER-2-478
  check-equal("test position using predicate: \\>", 
              position(#(1, 2, 3, 4), 3, predicate: \>),
              3); 
end function-test position;

define common-extensions function-test split ()
  check-equal("split on empty string",
              split("", '/'),
              #[]);
  check-equal("split on single character",
	      split("a", '/'),
	      #["a"]);
  check-equal("split on two characters",
	      split("a/b", '/'),
	      #["a", "b"]);
  check-equal("split on multiple single characters",
	      split("aXbXcXdXeXfXg", 'X'),
	      #["a", "b", "c", "d", "e", "f", "g"]);
  check-equal("split on single word",
	      split("hello", '/'),
	      #["hello"]);
  check-equal("split on two words",
	      split("hello/world", '/'),
	      #["hello", "world"]);
  check-equal("split on three words",
	      split("majorXminorXbuild", 'X'),
	      #["major", "minor", "build"]);
  check-equal("split on multiple words",
	      split("x=100&y=200&width=30&height=10", '&'),
	      #["x=100", "y=200", "width=30", "height=10"]);
  check-equal("split on single separator character",
	      split("/", '/'),
	      #["", ""]);
  check-equal("split on a/",
	      split("a/", '/'),
	      #["a", ""]);
  check-equal("split on /b",
	      split("/b", '/'),
	      #["", "b"]);
  check-equal("split with double separator",
	      split("majorXXbuild", 'X'),
	      #["major", "", "build"]);
  check-equal("split with spaces",
	      split(" major X minor X build ", 'X'),
	      #["major", "minor", "build"]);
  check-equal("no trim split with spaces",
	      split(" major X minor X build ", 'X', trim?: #f),
	      #[" major ", " minor ", " build "]);
  check-equal("split with start",
	      split("123456789x123456789", 'x', start: 1),
	      #["23456789", "123456789"]);
  check-equal("split with end",
	      split("0123456789", '3', end: 8),
	      #["012", "4567"]);
  check-equal("split with start and end",
	      split("0123456789", '3', start: 2, end: 8),
	      #["2", "4567"]);
end function-test split;

define common-extensions function-test remove-all-keys! ()
  //---*** Do all collections by using dylan-test-suite collection code
end function-test remove-all-keys!;

define common-extensions function-test string-to-integer ()
  for (integer-mapping in $integer-string-mappings)
    let integer = integer-mapping[0];
    let base    = integer-mapping[1];
    let string  = integer-mapping[2];
    check-equal(format-to-string("string-to-integer(%s)", string),
                string-to-integer(string, base: base), integer)
  end;
  check-no-errors("string-to-integer of minimum integer",
		  string-to-integer(integer-to-string($minimum-integer)));
  check-no-errors("string-to-integer of maximum integer",
		  string-to-integer(integer-to-string($maximum-integer)));
end function-test string-to-integer;

define common-extensions function-test subclass ()
  let new-type = #f;
  check-instance?("subclass returns type",
		  <type>,
		  new-type := subclass(<string>));
  check-instance?(format-to-string("<string> is subclass(<string>)"),
		  new-type, <string>);
  check-instance?(format-to-string("<byte-string> is subclass(<string>)"),
		  new-type, <byte-string>);
  check-false(format-to-string("<object> is not subclass(<string>)"),
              instance?(<object>, new-type));
end function-test subclass;

define common-extensions function-test fill-table! ()
  let table = make(<table>);
  check-equal("fill-table(...) returns the table",
              fill-table!(table, #[0, "Zero", 1, "One"]),
              table);
  check-equal("table(...)[0] = \"Zero\"",
              table[0], "Zero");
  check-equal("table(...)[1] = \"One\"",
              table[1], "One");
end function-test fill-table!;

define common-extensions function-test application-name ()
  //---*** Fill this in...
end function-test application-name;

define common-extensions function-test application-filename ()
  //---*** Fill this in...
end function-test application-filename;

define common-extensions function-test application-arguments ()
  //---*** Fill this in...
end function-test application-arguments;

define common-extensions function-test tokenize-command-line ()
  //---*** Fill this in...
end function-test tokenize-command-line;

define common-extensions function-test exit-application ()
  //---*** Fill this in...
end function-test exit-application;

define common-extensions function-test register-application-exit-function ()
  //---*** Fill this in...
end function-test register-application-exit-function;

define common-extensions function-test format-to-string ()
  check-instance?("format-to-string returns a string",
		  <string>,
		  format-to-string("Hello"));
  check-condition("format-to-string crashes when missing an argument",
		  <error>, format-to-string("Hello %s"));
  check-condition("format-to-string crashes with argument of wrong type",
		  <error>, format-to-string("Hello %c", 10));
  check-condition("format-to-string crashes with invalid directive %z",
		  <error>, format-to-string("Hello %z", 10));
  check-equal("format-to-string(\"%d\", 10)",
	      format-to-string("%d", 10),
	      "10");
  check-equal("format-to-string(\"%b\", 7)",
	      format-to-string("%b", 7),
	      "111");
  check-equal("format-to-string(\"%o\", 16)",
	      format-to-string("%o", 16),
	      "20");
  check-equal("format-to-string(\"%x\", 257)",
	      format-to-string("%x", 257),
	      "101");
  check-equal("format-to-string(\"%c\", 'a')",
	      format-to-string("%c", 'a'),
	      "a");
  check-equal("format-to-string(\"%%\")",
	      format-to-string("%%"),
	      "%");
  format-object-tests()
end function-test format-to-string;


/// simple-format module

define simple-io function-test format-out ()
  check-false("format-out doesn't crash", format-out("Hello"));
  check-condition("format-out crashes when missing an argument",
		  <error>, format-out("Hello %s"));
  check-condition("format-out crashes with argument of wrong type",
		  <error>, format-out("Hello %c", 10));
  check-condition("format-out crashes with invalid directive %z",
		  <error>, format-out("Hello %z", 10));
end function-test format-out;

define constant $format-object-mappings
  = vector(vector(10, "10", "10"),
	   vector('a', "a", "'a'"),
	   vector('Z', "Z", "'Z'"),
	   vector(#"symbol", "#\"symbol\""),
	   vector(#"symbol", "#\"symbol\""),
	   vector(#f, "#f"),
	   vector(#t, "#t"),
	   vector(<object>, "<object>", "{<class>: <object>}"),
	   vector(find-key, "find-key", "{<incremental-generic-function>: find-key}"),
	   vector("10", "10", "\"10\""));

define constant $format-complex-object-mappings
  = vector(vector(#(), "size 0"),
	   vector(pair(1, 2), "1, 2"),
	   vector(range(from: 0, to: 10), "0 to 10"),
	   vector(range(from: 10, to: 1, by: -1), "10 to 1 by -1"),
	   vector(range(from: 10, by: -1), "10 by -1"),
	   vector(make(<array>, dimensions: #(2, 3)), "2 x 3"),
	   vector(as(<vector>, #(1, 'a', "Hello")),
		  "1, 'a', \"Hello\""),
	   vector(singleton(10), "10"));
		  
define constant $format-type-union-mappings
  = vector(
      vector(type-union(<integer>, <string>),
          list("<integer>, <string>", "<string>, <integer>")),
      vector(type-union(singleton(#f), <string>),
          list("#f, <string>", "<string>, #f"))
    );
	  
define function test-print-name
    (object, pretty-name :: <string>, unique-name :: <string>)
 => ()
  check-equal(format-to-string("format-to-string(\"%%s\", %s)", unique-name),
	      format-to-string("%s", object),
	      pretty-name);
  check-equal(format-to-string("format-to-string(\"%%=\", %s)", unique-name),
	      format-to-string("%=", object),
	      unique-name);
end function test-print-name;

define function test-print-name-variants
    (object, pretty-names :: <sequence>, unique-names :: <sequence>)
 => ()
  local method any-equal (actual, valids)
    ~choose(curry(\=, actual), valids).empty?
        | error("%= not one of %=", actual, valids)
  end;
  check(format-to-string("format-to-string(\"%%s\", %s)", unique-names[0]),
	      any-equal, format-to-string("%s", object), pretty-names);
  check(format-to-string("format-to-string(\"%%=\", %s)", unique-names[0]),
	      any-equal, format-to-string("%=", object), unique-names);
end function test-print-name-variants;

define function format-object-tests
    () => ()
  for (mapping in $format-object-mappings)
    let object = mapping[0];
    let pretty-name = mapping[1];
    let unique-name = if (size(mapping) = 3) mapping[2] else pretty-name end;
    test-print-name(object, pretty-name, unique-name)
  end;
  for (mapping in $format-complex-object-mappings)
    let object = mapping[0];
    let class-name = format-to-string("%s", object-class(object));
    let unique-name = format-to-string("{%s: %s}", class-name, mapping[1]);
    test-print-name(object, unique-name, unique-name)
  end;
  // Handle separately from $format-complex-object-mappings because type-union
  // results are unordered, i.e., "type-union(<integer>, <float>)" and
  // "type-union(<float>, <integer>)" both pass. 
  for (mapping in $format-type-union-mappings)
    let object = mapping[0];
    let class-name = format-to-string("%s", object-class(object));
    let unique-names = map(curry(format-to-string, "{%s: %s}", class-name),
        mapping[1]);
    test-print-name-variants(object, unique-names, unique-names)
  end;
  let type = type-union(<string>, type-union(singleton(10), <character>));
  let class-name = format-to-string("%s", object-class(type));
  let expected-names = map(rcurry(format-to-string, class-name, class-name),
      #("{%s: <string>, {%s: 10, <character>}}",
        "{%s: <string>, {%s: <character>, 10}}",
        "{%s: {%s: 10, <character>}, <string>}",
        "{%s: {%s: <character>, 10}, <string>}"));
  test-print-name-variants(type, expected-names, expected-names)
end function format-object-tests;


/// simple-random tests

/*---*** andrewa: not used yet...
define method chi-square
    (N :: <integer>, range :: <integer>) => (chi-square :: <integer>)
  let f = make(<simple-object-vector>, size: range, fill: 0);
  for (i from 0 below N) 
    let rand = random(range);
    f[rand] := f[rand] + 1;
  end;
  let t = 0;
  for (i from 0 below range) t := t + f[i] * f[i] end;
  floor/(range * t, N) - N
end method chi-square;
*/

define simple-random function-test random ()
  // We should use chi-square somehow, but we don't want it to be slow.
  // Also, what value should it be returning?
  //---*** Fill this in...
end function-test random;


/// simple-profiling tests

define simple-profiling function-test start-profiling-type ()
  //---*** Fill this in...
end function-test start-profiling-type;

define simple-profiling function-test stop-profiling-type ()
  //---*** Fill this in...
end function-test stop-profiling-type;

define simple-profiling function-test profiling-type-result ()
  //---*** Fill this in...
end function-test profiling-type-result;
