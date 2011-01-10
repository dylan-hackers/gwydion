Module:       dylan-user
Synopsis:     Dylan test suite
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1996-2000 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define module dylan-test-suite
  //use dylan-extensions,
  use dylan;
  use extensions;
  use common-dylan;
  use testworks;
  use testworks-specs;

  // Suites
  export dylan-test-suite;

  // Generics
  export //test-collection-class,
         test-condition-class,
         test-number-class;
end module dylan-test-suite;
