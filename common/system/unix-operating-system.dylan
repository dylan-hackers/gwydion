Module:       system-internals
Author:       Gary Palter
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define constant $os-name = begin
                             let (result, utsname) = %uname();
                             as(<symbol>, utsname.sysname)
                           end;

define constant $os-variant = $os-name;
define constant $os-version = begin
                                let (result, utsname) = %uname();
                                utsname.utsname-release
                              end;

define constant $command-line-option-prefix = '-';

define function command-line-option-prefix
    () => (prefix :: <character>)
  $command-line-option-prefix
end function command-line-option-prefix;

define function login-name () => (name :: false-or(<string>))
  %getlogin();
end function login-name;

define function login-group () => (group :: false-or(<string>))
  let gid = %getgid();
  let gr-ent = %getgrgid(gid);
  if (gr-ent = $null-pointer)
    #f
  else
    as(<byte-string>, gr-ent.gr-name)
  end;
end function login-group;

///---*** NOTE: Provide a non-null implementation when time permits...
define function owner-name () => (name :: false-or(<string>))
  #f
end function owner-name;

///---*** NOTE: Provide a non-null implementation when time permits...
define function owner-organization () => (organization :: false-or(<string>))
  #f
end function owner-organization;

define constant $environment-variable-delimiter = ':';

define function environment-variable
    (name :: <byte-string>) => (value :: false-or(<byte-string>))
  let v = %getenv(name);
  if (v = $null-pointer)
    #f
  else
    as(<byte-string>, v)
  end;
end function environment-variable;

define function environment-variable-setter
    (new-value :: false-or(<byte-string>), name :: <byte-string>)
 => (new-value :: false-or(<byte-string>))
  if(new-value)
    %putenv(concatenate(name, "=", new-value));
  else
    %unsetenv(name);
  end;
  new-value;
end function environment-variable-setter;

define class <application-process> (<object>)
  constant slot application-process-id :: <integer>,
    required-init-keyword: process-id:;
  slot %application-process-state :: one-of(#"running", #"exited"),
    init-value: #"running";
  slot %application-process-status-code :: <integer>,
    init-value: 0;
end class;

define function make-pipe() => (read-fd :: <integer>, write-fd :: <integer>);
  let filedes = make(<int*>, element-count: 2);
  if (%pipe(filedes) < 0)
    error("pipe creation failed");
  end if;
  let read-fd = pointer-value(filedes, index: 0);
  let write-fd = pointer-value(filedes, index: 1);
  destroy(filedes);
  values(read-fd, write-fd)
end function;

define constant $null-device = "/dev/null";
define constant $posix-shell = "/bin/sh";

define function run-application
    (command :: type-union(<string>, limited(<sequence>, of: <string>)),
     #key under-shell? = #t,
          inherit-console? = #t,
          activate? = #t,       // ignored on POSIX systems
          minimize? = #f,       // ignored on POSIX systems
          hide? = #f,           // ignored on POSIX systems
          outputter :: false-or(<function>) = #f,
          asynchronous? = #f,

          environment :: false-or(<explicit-key-collection>),
          working-directory :: false-or(<pathname>) = #f,
     
          input :: type-union(one-of(#"inherit", #"null", #"stream"),
                              <pathname>) = #"inherit",
          if-input-does-not-exist :: one-of(#"signal", #"create") = #"signal",
          output :: type-union(one-of(#"inherit", #"null", #"stream"),
                               <pathname>) = #"inherit",
          if-output-exists :: one-of(#"signal", #"new-version", #"replace",
                                     #"overwrite", #"append",
                                     #"truncate") = #"replace",
          error: _error :: type-union(one-of(#"inherit", #"null", #"stream", #"output"),
                              <pathname>) = #"inherit",
          if-error-exists :: one-of(#"signal", #"new-version", #"replace",
                                    #"overwrite", #"append",
                                    #"truncate") = #"replace")
 => (exit-code :: <integer>, signal :: false-or(<integer>),
     child :: false-or(<application-process>), #rest streams);

  ignore(activate?, minimize?, hide?);

  let (program, argv)
    = if (under-shell?)
        if (instance?(command, <string>))
          let argv = make(<char**>, element-count: 4);
          pointer-value(argv, index: 0) := as(<c-string>, "sh");
          pointer-value(argv, index: 1) := as(<c-string>, "-c");
          pointer-value(argv, index: 2) := as(<c-string>, command);
          values($posix-shell, argv)
        else
          let argv = make(<char**>, element-count: 3 + command.size);
          pointer-value(argv, index: 0) := as(<c-string>, "sh");
          pointer-value(argv, index: 1) := as(<c-string>, "-c");
          for (i from 0 below command.size)
            pointer-value(argv, index: 2 + i) := as(<c-string>, command[i]);
          end for;
          values($posix-shell, argv)
        end if
      else
        if (instance?(command, <string>))
          let argv = make(<char**>, element-count: 2);
          pointer-value(argv, index: 0) := as(<c-string>, command);
          values(command, argv)
        else
          let argv = make(<char**>, element-count: 1 + command.size);
          for (i from 0 below command.size)
            pointer-value(argv, index: i) := as(<c-string>, command[i]);
          end for;
          values(command[0], argv)
        end if
      end if;

  let envp
    = if (environment)
        make-envp(environment)
      else
        environ()
      end if;

  let dir :: <c-string>
    = if (working-directory)
        as(<c-string>, as(<byte-string>, working-directory))
      else
        make(<c-string>, pointer: $null-pointer)
      end if;

  let close-fds :: <list> = #();
  let streams :: <list> = #();

  let input-fd
    = select (input)
        #"inherit" =>
          -1;
        #"null" =>
          %open($null-device, $O_RDONLY, $file_create_permissions);
        #"stream" =>
          let (read-fd, write-fd) = make-pipe();
          streams := add(streams, make(<file-stream>,
                                       locator: write-fd,
                                       file-descriptor: write-fd,
                                       direction: #"output"));
          close-fds := add(close-fds, read-fd);
          read-fd;
        otherwise =>
          let pathstring = as(<byte-string>, expand-pathname(input));
          let mode-code
            = if (if-input-does-not-exist == #"create")
                logior($O_RDONLY, $O_CREAT);
              else
                $O_RDONLY;
              end if;
          %open(pathstring, mode-code, $file_create_permissions);
      end select;

  local
    method open-output (key, if-exists, output-fd) => (fd :: <integer>);
      select (key)
        #"inherit" =>
          -1;
        #"null" =>
          %open($null-device, $O_WRONLY, $file_create_permissions);
        #"stream" =>
          let (read-fd, write-fd) = make-pipe();
          streams := add(streams, make(<file-stream>,
                                       locator: read-fd,
                                       file-descriptor: read-fd,
                                       direction: #"input"));
          close-fds := add(close-fds, write-fd);
          write-fd;
        #"output" =>
          output-fd;
        otherwise =>
          let pathstring = as(<byte-string>, expand-pathname(key));
          let mode-code
            = select (if-exists)
                #"signal" =>
                  error("not yet");
                #"new-version", #"replace" =>
                  logior($O_WRONLY, $O_CREAT); // FIXME is this correct?
                #"overwrite", #"append" =>
                  $O_WRONLY;
                #"truncate" =>
                  logior($O_WRONLY, $O_TRUNC);
              end select;
          let fd = %open(pathstring, mode-code, $file_create_permissions);
          if (if-output-exists == #"append")
            unix-lseek(fd, 0, $seek_end);
          end if;
          fd;
      end select;
    end method;

  let output-fd = open-output(output, if-output-exists, #f);
  let error-fd = open-output(_error, if-error-exists, output-fd);

  let outputter-read-fd = -1;
  if (outputter)
    let (read-fd, write-fd) = make-pipe();
    outputter-read-fd := read-fd;
    error-fd := output-fd := write-fd;
    close-fds := add(close-fds, write-fd);
  end if;

  let pid = %spawn(program, argv, envp, dir, inherit-console?,
                   input-fd, output-fd, error-fd);

  // Close fds that belong to the child
  do(unix-close, close-fds);

  if (asynchronous?)
    apply(values, 0, #f, make(<application-process>, process-id: pid),
          reverse!(streams))
  else
    if (outputter)
      run-outputter(outputter, outputter-read-fd);
    end if;
    
    let (return-pid, status-code) = %waitpid(pid, 0);
    let signal-code = logand(status-code, #o177);
    let exit-code = ash(status-code, -8);
    apply(values, exit-code, (signal-code ~= 0) & signal-code, #f,
          reverse!(streams))
  end if
end function run-application;

define constant $BUFFER-MAX = 4096;

define function run-outputter
    (outputter :: <function>, outputter-read-fd :: <integer>) => ();
  let dylan-output-buffer = make(<byte-string>, size: $BUFFER-MAX, fill: '\0');
  let output-buffer
    = as(<machine-pointer>, vector-elements-address(dylan-output-buffer));
  iterate loop ()
    let count = unix-raw-read(outputter-read-fd, output-buffer, $BUFFER-MAX);
    if (count > 0)
      outputter(dylan-output-buffer, end: count);
      loop();
    end if;
  end iterate;
end function;

define function wait-for-application-process
    (process :: <application-process>)
 => (exit-code :: <integer>, signal :: false-or(<integer>));
  if (process.%application-process-state == #"running")
    let (return-pid, return-status)
      = %waitpid(process.application-process-id, 0);
    process.%application-process-status-code := return-status;
    process.%application-process-state := #"exited";
  end if;
  let status-code = process.%application-process-status-code;
  let signal-code = logand(status-code, #o177);
  let exit-code = ash(status-code, -8);
  values(exit-code, (signal-code ~= 0) & signal-code);
end function;

define function make-envp
    (environment :: <explicit-key-collection>)
 => (result :: <char**>)
  let temp-table :: <string-table> = make(<string-table>);

  // Obtain the current environment as a <string-table> keyed by the
  // environment variable name
  let old-envp :: <char**> = environ();
  block (envp-done)
    for (i :: <integer> from 0)
      let item = pointer-value(old-envp, index: i);
      if (item = $null-pointer)
        envp-done();
      else
        block (item-done)
          for (char in item, j from 0)
            if (char == '=')
              let key = copy-sequence(item, end: j);
              temp-table[key] := item;
              item-done();
            end if;
          end for;
        end block;
      end if;
    end for;
  end block;

  // Override anything set in the user-supplied environment
  for (value keyed-by key in environment)
    temp-table[key] := as(<c-string>, concatenate(key, "=", value));
  end for;

  // Create a new environment vector and initialize it
  let new-envp = make(<char**>, element-count: temp-table.size + 1);
  for (i :: <integer> from 0, item keyed-by key in temp-table)
    pointer-value(new-envp, index: i) := item;
  end for;

  new-envp
end function;

///---*** NOTE: The following functions need real implementations!

define function create-application-event
    (event :: <string>) => (event-object :: <machine-word>)
  as(<machine-word>, 0)
end function create-application-event;

define constant $INFINITE_TIMEOUT = -1;

define function wait-for-application-event
    (event-object :: <machine-word>, #key timeout :: <integer> = $INFINITE_TIMEOUT)
 => (success? :: <boolean>)
  #t
end function wait-for-application-event;

define function signal-application-event
    (event :: <string>) => (success? :: <boolean>)
  #t
end function signal-application-event;

define function load-library
    (name :: <string>) => (module)
  #f
end function load-library;
