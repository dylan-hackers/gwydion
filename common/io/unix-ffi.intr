Module: io-internals

define interface
  #include { "config.h", "unix-portability.h" },
  //    define: { "_XOPEN_SOURCE" => "600" }, // SUSv3 (Issue 6)
    import: { "io_errno" => unix-last-error,
              "strerror" => %strerror,
              "close" => unix-close,
              "read" => %read,
              "write" => %write,
              "fsync" => unix-fsync,
              "off_t",
              "lseek" => %lseek,
              "SEEK_CUR" => $seek_cur,
              "SEEK_SET" => $seek_set,
              "SEEK_END" => $seek_end,
              "io_fd_info" => unix-fd-info };
  function "strerror",
    equate-result: <c-string>,
    map-result: <byte-string>;
  function "io_fd_info",
    output-argument: 2,
    map-argument: { 2 => <boolean> };
end interface;

define function unix-read
    (fd :: <integer>, data :: <buffer>, offset :: <integer>,
     count :: <integer>)
 => (result :: <integer>);
  let addr = as(<machine-pointer>, vector-elements-address(data) + offset);
  %read(fd, addr, count)
end function;

define function unix-write
    (fd :: <integer>, data :: <buffer>, offset :: <integer>,
     count :: <integer>)
 => (result :: <integer>);
  let addr = as(<machine-pointer>, vector-elements-address(data) + offset);
  %write(fd, addr, count)
end function;

define function unix-lseek
    (fd :: <integer>, position :: <integer>, mode :: <integer>)
 => (position :: <integer>);
  as(<integer>, %lseek(fd, as(<off-t>, position), mode))
end function;

define function unix-error (syscall :: <string>,
                            #key errno = unix-last-error()) => ()
  let message :: <string> = %strerror(errno);
  error("%s %s", syscall, message);
end function unix-error;
