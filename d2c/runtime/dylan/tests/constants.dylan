Module:       dylan-test-suite
Synopsis:     Dylan test suite
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1996-2000 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Constant testing

define dylan constant-test $permanent-hash-state ()
  //---*** Fill this in...
end constant-test $permanent-hash-state;

define dylan-extensions constant-test $minimum-integer ()
  //---*** Add some more tests here...
  check-condition("$minimum-integer - 1 overflows",
		  <error>,
		  $minimum-integer - 1)
end constant-test $minimum-integer;

define dylan-extensions constant-test $maximum-integer ()
  //---*** Add some more tests here...
  check-condition("$maximum-integer + 1 overflows",
		  <error>,
		  $maximum-integer + 1)
end constant-test $maximum-integer;
