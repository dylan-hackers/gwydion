Module:       common-dylan-test-suite
Synopsis:     Common Dylan library test suite
Author:	      Andy Armstrong
Copyright:    Original Code is Copyright (c) 1996-2001 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Class test cases

define locators-protocol class-test <locator> ()
  //---*** Fill this in...
end class-test <locator>;

define common-extensions class-test <format-string-condition> ()
  //---*** Fill this in...
end class-test <format-string-condition>;

define common-extensions class-test <simple-condition> ()
  //---*** Fill this in...
end class-test <simple-condition>;

define common-extensions class-test <arithmetic-error> ()
  //---*** Fill this in...
end class-test <arithmetic-error>;

/// NOTE: These rather strange expressions are used to prevent the compiler from
///       attempting any compile-time optimizations of the original expressions.

/*
define common-extensions class-test <division-by-zero-error> ()
  check-condition("floor/(1, 0) signals <division-by-zero-error>",
		  <division-by-zero-error>,
		  begin
		    let x :: <integer> = 0;
		    for (i from 0 below 1)
		      x := x + 1;
		      x := floor/(x, 0);
		    end
		  end);
  check-condition("1.0s0 / 0.0s0 signals <division-by-zero-error>",
		  <division-by-zero-error>,
		  begin
		    let x :: <single-float> = 0.0s0;
		    for (i from 0 below 1)
		      x := x + 1.0s0;
		      x := x / 0.0s0;
		    end
		  end);
  check-condition("1.0d0 / 0.0d0 signals <division-by-zero-error>",
		  <division-by-zero-error>,
		  begin
		    let x :: <double-float> = 0.0d0;
		    for (i from 0 below 1)
		      x := x + 1.0d0;
		      x := x / 0.0d0;
		    end
		  end);
end class-test <division-by-zero-error>;

define common-extensions class-test <arithmetic-overflow-error> ()
  check-condition("$maximum-integer + 1 signals <arithmetic-overflow-error>",
		  <arithmetic-overflow-error>,
		  begin
		    let x :: <integer> = $maximum-integer - 1;
		    for (i from 0 below 2)
		      x := x + 1;
		    end
		  end);
  check-condition("$minimum-integer - 1 signals <arithmetic-overflow-error>",
		  <arithmetic-overflow-error>,
		  begin
		    let x :: <integer> = $minimum-integer + 1;
		    for (i from 0 below 2)
		      x := x - 1;
		    end
		  end);
  check-condition("1.0s20 * 1.0s20 signals <arithmetic-overflow-error>",
		  <arithmetic-overflow-error>,
		  begin
		    let x :: <single-float> = 1.0s0;
		    for (i from 0 below 2)
		      x := x * 1.0s20;
		    end;
		    x
		  end);
  check-condition("1.0d160 * 1.0d160 signals <arithmetic-overflow-error>",
		  <arithmetic-overflow-error>,
		  begin
		    let x :: <double-float> = 1.0d0;
		    for (i from 0 below 2)
		      x := x * 1.0d160;
		    end;
		    x
		  end);
end class-test <arithmetic-overflow-error>;

define common-extensions class-test <arithmetic-underflow-error> ()
  check-condition("1.0s-20 * 1.0s-20 signals <arithmetic-underflow-error>",
		  <arithmetic-underflow-error>,
		  begin
		    let x :: <single-float> = 1.0s0;
		    for (i from 0 below 2)
		      x := x * 1.0s-20;
		    end;
		    x
		  end);
  check-condition("1.0d-160 * 1.0d-160 signals <arithmetic-underflow-error>",
		  <arithmetic-underflow-error>,
		  begin
		    let x :: <double-float> = 1.0d0;
		    for (i from 0 below 2)
		      x := x * 1.0d-160;
		    end;
		    x
		  end);
end class-test <arithmetic-underflow-error>;
*/

define common-extensions class-test <stretchy-sequence> ()
  //---*** Fill this in...
end class-test <stretchy-sequence>;


/// simple-random classes

define simple-random class-test <random> ()
  //---*** Fill this in...
end class-test <random>;


/// simple-profiling classes

define common-extensions class-test <profiling-state> ()
  //---*** Fill this in...
end class-test <profiling-state>;
