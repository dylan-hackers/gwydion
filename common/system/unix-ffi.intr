Module:       system-internals
Author:       Peter S. Housel
Copyright:    Original Code is Copyright 2003 Gwydion Dylan Maintainers
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define interface
  #include { "config.h", "unix-portability.h" },
    //define: { "_XOPEN_SOURCE" => "600" }, // SUSv3 (Issue 6)
    import: { "system_errno" => unix-last-error,
              "system_errno_setter" => unix-last-error-setter,
              "ENOENT", "EACCES", "EINVAL", "ERANGE",
              "strerror" => %strerror,

              "struct tm", "system_localtime" => %system-localtime,
              "struct timeval", "gettimeofday" => %gettimeofday,

              "struct utsname", 
              "uname" => %uname,

              "getlogin" => %getlogin,

              "getgid" => %getgid, "struct group", "getgrgid" => %getgrgid,

              "getenv" => %getenv, "putenv" => %putenv,
              "unsetenv" => %unsetenv,

	      "system_spawn" => %spawn,
	      "waitpid" => %waitpid,
	      "environ",

              "struct passwd",
              "getpwnam" => %getpwnam, "getpwuid" => %getpwuid,

              "struct stat",
              "S_IFMT" => $S_IFMT, "S_IFDIR" => $S_IFDIR,
              "S_IFLNK" => $S_IFLNK, "S_IFREG" => $S_IFREG,
              "S_IRWXU" => $S_IRWXU, "S_IRWXG" => $S_IRWXG,
              "S_IRWXO" => $S_IRWXO,
              "S_IRUSR" => $S_IRUSR, "S_IRGRP" => $S_IRGRP,
              "S_IROTH" => $S_IROTH,
              "S_IWUSR" => $S_IWUSR, "S_IWGRP" => $S_IWGRP,
              "S_IWOTH" => $S_IWOTH,
              "S_IXUSR" => $S_IXUSR, "S_IXGRP" => $S_IXGRP,
              "S_IXOTH" => $S_IXOTH,
              "stat" => %stat, "lstat" => %lstat,
              "system_st_birthtime" => %st-birthtime,
              "system_st_atime" => %st-atime,
              "system_st_mtime" => %st-mtime,

              "pathconf" => %pathconf,
              "_PC_SYMLINK_MAX" => $_PC_SYMLINK_MAX,
              "_PC_PATH_MAX" => $_PC_PATH_MAX,

	      "pipe" => %pipe,

              "readlink" => %readlink,

              "unlink" => %unlink,
              "rename" => %rename,
              "chmod" => %chmod,

              "access" => %access,
              "R_OK" => $R_OK, "W_OK" => $W_OK, "X_OK" => $X_OK,

              "DIR *" => <DIR>,
              "opendir" => %opendir,
              "struct dirent", "readdir" => %readdir,
              "closedir" => %closedir,

              "mkdir" => %mkdir,
              "rmdir" => %rmdir,
              "getcwd" => %getcwd,
              "chdir" => %chdir,

              "system_open" => %open,
              "O_RDONLY" => $O_RDONLY, "O_WRONLY" => $O_WRONLY,
              "O_RDWR" => $O_RDWR,
              "O_APPEND" => $O_APPEND, "O_CREAT" => $O_CREAT,
              "O_TRUNC" => $O_TRUNC, "O_SYNC" => $O_SYNC,
              "close" => unix-close,
              "read" => unix-raw-read,

              "off_t",
              "lseek" => %lseek,
              "SEEK_CUR" => $seek_cur,
              "SEEK_SET" => $seek_set,
              "SEEK_END" => $seek_end },
    name-mapper: minimal-name-mapping,
    equate: { "char *" => <c-string> };

  function "getlogin",
    map-result: <byte-string>;
  
  function "system_localtime",
    map-result: <boolean>,
    output-argument: 2,
    output-argument: 3,
    output-argument: 4,
    map-argument: { 4 => <byte-string> };
  function "gettimeofday",
    map-result: <boolean>,
    output-argument: 1,
    equate-argument: { 2 => <statically-typed-pointer> };

  struct "struct utsname",
    read-only: #t,
    rename: { "release" => utsname-release },
    map: { "sysname" => <byte-string> },
    map: { "release" => <byte-string> };

  struct "struct passwd",
    read-only: #t;

  function "getpwnam",
    map-argument: { 1 => <byte-string> };

  struct "struct group",
    read-only: #t,
    map: { "gr_name" => <byte-string> };
    
  function "uname",
    output-argument: 1;

  function "getenv",
    map-argument: { 1 => <byte-string> };
  function "putenv",
    map-argument: { 1 => <byte-string> };
  function "unsetenv",
    map-argument: { 1 => <byte-string> };

  function "system_spawn",
    map-argument: { 1 => <byte-string> },
    map-argument: { 5 => <boolean> };

  function "waitpid",
    output-argument: 2;

  variable "environ",
    read-only: #t;

  struct "struct stat",
    read-only: #t;
  function "stat",
    map-argument: { 1 => <byte-string> },
    map-result: <boolean>,
    output-argument: 2;
  function "lstat",
    map-argument: { 1 => <byte-string> },
    map-result: <boolean>,
    output-argument: 2;
  function "system_st_birthtime",
    output-argument: 2;
  function "system_st_atime",
    output-argument: 2;
  function "system_st_mtime",
    output-argument: 2;

  function "system_open",
    map-argument: { 1 => <byte-string> };

  function "access",
    map-argument: { 1 => <byte-string> };

  function "unlink",
    map-argument: { 1 => <byte-string> },
    map-result: <boolean>;
  function "rename",
    map-argument: { 1 => <byte-string> },
    map-argument: { 2 => <byte-string> },
    map-result: <boolean>;
  function "mkdir",
    map-argument: { 1 => <byte-string> },
    map-result: <boolean>;
  function "rmdir",
    map-argument: { 1 => <byte-string> },
    map-result: <boolean>;

  function "chdir",
    map-argument: { 1 => <byte-string> };
  function "getcwd",
    map-result: <c-string>;

  function "pathconf",
    map-argument: { 1 => <byte-string> };
  function "readlink",
    map-argument: { 1 => <byte-string> };
  function "chmod",
    map-argument: { 1 => <byte-string> };

  function "opendir",
    map-argument: { 1 => <byte-string> };

  struct "struct dirent",
    read-only: #t,
    rename: { "d_name" => dirent-name },
    map: { "d_name" => <byte-string> };

  function "strerror",
    map-result: <byte-string>;
end interface;

define function unix-last-error-message () => (message :: <string>)
  %strerror(unix-last-error())
end function;

define function unix-file-error
    (operation :: <string>, additional-information,
     #rest additional-information-args)
 => (will-never-return :: <bottom>)
  let status-message = unix-last-error-message();
  if (additional-information)
    error(make(<file-system-error>,
               format-string:
                 concatenate("%s: Can't %s ", additional-information),
               format-arguments:
                 concatenate(list(status-message),
                             list(operation),
                             map(method (x)
                                   if (instance?(x, <locator>))
                                     as(<string>, x)
                                   else
                                     x
                                   end
                                 end method,
                                 additional-information-args))))
  else
    error(make(<file-system-error>,
               format-string: "%s: Can't %s",
               format-arguments: list(status-message, operation)))
  end;
end function unix-file-error;

define function unix-lseek
    (fd :: <integer>, position :: <integer>, mode :: <integer>)
 => (position :: <integer>);
  as(<integer>, %lseek(fd, as(<off-t>, position), mode))
end function;
