Module:       system-internals
Synopsis:     Abstract modeling of locations
Author:       Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define constant <native-file-system-locator>  = <posix-file-system-locator>;
define constant <native-directory-locator> = <posix-directory-locator>;
define constant <native-file-locator>      = <posix-file-locator>;

define function file-system-separator
    () => (separator :: <character>)
  $posix-separator
end function file-system-separator;
