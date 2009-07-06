Module:       system-test-suite
Synopsis:     System library test suite
Author:	      Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Operating system tests

define operating-system constant-test $architecture-little-endian? ()
  check-true("$architecture-little-endian? is true if x86",
             $machine-name ~== #"x86" | $architecture-little-endian?);
end constant-test $architecture-little-endian?;

define operating-system constant-test $os-name ()
  //---*** Fill this in...
end constant-test $os-name;

define operating-system constant-test $os-variant ()
  //---*** Fill this in...
end constant-test $os-variant;

define operating-system constant-test $os-version ()
  //---*** Fill this in...
end constant-test $os-version;

define operating-system constant-test $platform-name ()
  //---*** Fill this in...
end constant-test $platform-name;

define operating-system constant-test $machine-name ()
  //---*** Fill this in...
end constant-test $machine-name;


/// Operating System functions

define operating-system function-test login-name ()
  check-instance?("login-name returns #f or a string",
                  false-or(<string>), login-name());
end function-test login-name;

define operating-system function-test login-group ()
  check-instance?("login-group returns #f or a string",
                  false-or(<string>), login-group());
end function-test login-group;

define operating-system function-test owner-name ()
  check-instance?("owner-name returns #f or a string",
                  false-or(<string>), owner-name());
end function-test owner-name;

define operating-system function-test owner-organization ()
  check-instance?("owner-organization returns #f or a string",
                  false-or(<string>), owner-organization());
end function-test owner-organization;

define operating-system class-test <application-process> ()
  //---*** Fill this in...
end class-test <application-process>;

define operating-system function-test run-application ()
  select ($os-name)
    #"win32" =>
      #f;
    otherwise =>
      // Assume POSIX of some sort

      // Synchronous true exit
      begin
        let (exit-code, signal, child) = run-application("true");
        check-equal("true exit 0", 0, exit-code);
        check-equal("true no signal", #f, signal);
        check-false("no child for synchronous run-application", child);
      end;

      // Synchronous false exit
      begin
        let (exit-code, signal, child) = run-application("false");
        check-equal("false exit 1", 1, exit-code);
        check-equal("false no signal", #f, signal);
        check-false("no child for synchronous run-application", child);
      end;

      // Asynchronous true exit
      begin
        let (exit-code, signal, child)
          = run-application("true", asynchronous?: #t);
        check-equal("asynchronous exit 0", 0, exit-code);
        check-equal("asynchronous no signal", #f, signal);
        check-instance?("child returned for asynchronous run-application",
                        <application-process>, child);

        let (exit-code, signal) = wait-for-application-process(child);
        check-equal("wait true exit 0", 0, exit-code);
        check-equal("wait true no signal", #f, signal);
      end;

      // Asynchronous false exit
      begin
        let (exit-code, signal, child)
          = run-application("false", asynchronous?: #t);
        check-equal("asynchronous exit 0", 0, exit-code);
        check-equal("asynchronous no signal", #f, signal);
        check-instance?("child returned for asynchronous run-application",
                        <application-process>, child);

        let (exit-code, signal) = wait-for-application-process(child);
        check-equal("wait false exit 1", 1, exit-code);
        check-equal("wait false no signal", #f, signal);
      end;

      // Output stream
      begin
        let (exit-code, signal, child, stream)
          = run-application("echo hello, world",
                            asynchronous?: #t, output: #"stream");
        check-equal("asynchronous exit 0", 0, exit-code);
        check-equal("asynchronous no signal", #f, signal);
        check-instance?("child returned for asynchronous run-application",
                        <application-process>, child);
        check-instance?("stream returned for run-application w/output stream",
                        <stream>, stream);

        let contents = read-to-end(stream);
        check-equal("echo results read from stream",
                    "hello, world\n", contents);

        let (exit-code, signal) = wait-for-application-process(child);
        check-equal("wait echo exit 0", 0, exit-code);
        check-equal("wait echo no signal", #f, signal);

        close(stream);
      end;

      // Input stream
      begin
        let (exit-code, signal, child, stream)
          = run-application("sh", asynchronous?: #t, input: #"stream");
        
        check-equal("asynchronous exit 0", 0, exit-code);
        check-equal("asynchronous no signal", #f, signal);
        check-instance?("child returned for asynchronous run-application",
                        <application-process>, child);
        check-instance?("stream returned for run-application w/input stream",
                        <stream>, stream);

        write(stream, "exit 1\n");
        close(stream);

        let (exit-code, signal) = wait-for-application-process(child);
        check-equal("wait sh exit 1", 1, exit-code);
        check-equal("wait sh no signal", #f, signal);
      end;

      // Input and output streams
      begin
        let (exit-code, signal, child, input-stream, output-stream)
          = run-application("tr a-z A-Z", asynchronous?: #t,
                            input: #"stream", output: #"stream");
        
        check-equal("asynchronous exit 0", 0, exit-code);
        check-equal("asynchronous no signal", #f, signal);
        check-instance?("child returned for asynchronous run-application",
                        <application-process>, child);
        check-instance?("input stream returned for run-application",
                        <stream>, input-stream);
        check-instance?("output stream returned for run-application",
                        <stream>, output-stream);

        write(input-stream, "Dylan programming language\n");
        close(input-stream);

        let contents = read-to-end(output-stream);
        check-equal("tr results read from stream",
                    "DYLAN PROGRAMMING LANGUAGE\n", contents);

        let (exit-code, signal) = wait-for-application-process(child);
        check-equal("wait tr exit 0", 0, exit-code);
        check-equal("wait tr no signal", #f, signal);

        close(output-stream);
      end;
      
      // Environment variable setting
      begin
        check-false("test preconditions: OS_TEST_RUN_APPLICATION not set",
                    environment-variable("OS_TEST_RUN_APPLICATION"));

        let env = make(<string-table>);
        env["OS_TEST_RUN_APPLICATION"] := "Dylan programming language";

        let (exit-code, signal, child, stream)
          = run-application("echo $OS_TEST_RUN_APPLICATION",
                            asynchronous?: #t, output: #"stream",
                            environment: env);
        check-equal("asynchronous exit 0", 0, exit-code);
        check-equal("asynchronous no signal", #f, signal);
        check-instance?("child returned for asynchronous run-application",
                        <application-process>, child);
        check-instance?("stream returned for run-application w/output stream",
                        <stream>, stream);

        let contents = read-to-end(stream);
        check-equal("echo w/environment variable results read from stream",
                    "Dylan programming language\n", contents);

        let (exit-code, signal) = wait-for-application-process(child);
        check-equal("wait echo exit 0", 0, exit-code);
        check-equal("wait echo no signal", #f, signal);

        close(stream);
      end;
  end select;
end function-test run-application;

define operating-system function-test wait-for-application-process ()
  //---*** Fill this in...
end function-test wait-for-application-process;

define operating-system function-test load-library ()
  //---*** Fill this in...
end function-test load-library;


// Application startup handling

define operating-system function-test application-name ()
  check-instance?("application-name returns #f or a string",
                  false-or(<string>), application-name());
end function-test application-name;

define operating-system function-test application-filename ()
  let filename = application-filename();
  check-true("application-filename returns #f or a valid, existing file name",
             ~filename
               | begin
                   let locator = as(<file-system-file-locator>, filename);
                   file-exists?(locator)
                 end)

end function-test application-filename;

define operating-system function-test application-arguments ()
  check-instance?("application-arguments returns a sequence",
                  <sequence>, application-arguments());
end function-test application-arguments;

define operating-system function-test tokenize-command-string ()
  //---*** Fill this in...
end function-test tokenize-command-string;

define operating-system function-test command-line-option-prefix ()
  check-instance?("command-line-option-prefix returns a character",
                  <character>, command-line-option-prefix());
end function-test command-line-option-prefix;

define operating-system function-test exit-application ()
  //---*** Fill this in...
end function-test exit-application;

define operating-system function-test register-application-exit-function ()
  //---*** Fill this in...
end function-test register-application-exit-function;


// Environment variables

define operating-system function-test environment-variable ()
  check-false("unset environment variable returns false",
              environment-variable("HIGHLY_UNLIKELY_TO_BE_SET"));
  check-instance?("PATH is set and is a string",
                  <string>, environment-variable("PATH"));
end function-test environment-variable;

define operating-system function-test environment-variable-setter ()
  check-equal("environment-variable-setter returns new value",
              "new-value",
              environment-variable("OS_TEST_E_V_S") := "new-value");
  check-equal("newly set value reflected in environment",
              "new-value", environment-variable("OS_TEST_E_V_S"));
  check-false("environment-variable-setter to #f returns #f",
              environment-variable("OS_TEST_E_V_S") := #f);
  check-false("newly unset value reflected in environment",
              environment-variable("OS_TEST_E_V_S"));
end function-test environment-variable-setter;

define operating-system function-test tokenize-environment-variable ()
  //---*** Fill this in...
end function-test tokenize-environment-variable;


// Macro tests

define operating-system macro-test with-application-output-test ()
  with-application-output (stream = "echo hello, world")
    let contents = read-to-end(stream);
    check-equal("echo results read from stream",
                "hello, world\n", contents);
  end;
end macro-test with-application-output-test;
