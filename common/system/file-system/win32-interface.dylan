Module:       system-internals
Synopsis:     An interface to file-related win32 API calls.
Author:       Eliot Miranda, Scott McKay, Marc Ferguson, Gary Palter
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

// Uses the low-level FFI rather than the real C FFI and should, eventually, be rewritten.
// As it stands now, this code requires the use of glue code written in C.  (Sigh)

// fdwAccess argument
define constant $GENERIC_READ  = #x8000; // shifted right 16 bits
define constant $GENERIC_WRITE = #x4000; // shifted right 16 bits
ignorable($GENERIC_READ, $GENERIC_WRITE);

// fdwShareMode argument
define constant $FILE_SHARE_READ  = 1;
define constant $FILE_SHARE_WRITE = 2;
ignorable($FILE_SHARE_READ, $FILE_SHARE_WRITE);

// fdwCreate argument
define constant $CREATE_NEW        = 1;
define constant $CREATE_ALWAYS     = 2;
define constant $OPEN_EXISTING     = 3;
define constant $OPEN_ALWAYS       = 4;
define constant $TRUNCATE_EXISTING = 5;
ignorable($CREATE_NEW, $CREATE_ALWAYS, 
	  $OPEN_EXISTING, $OPEN_ALWAYS, $TRUNCATE_EXISTING);

// fdwAttrsAndFlags
define constant $FILE_ATTRIBUTE_NORMAL = #x80;
define constant $FILE_FLAG_OVERLAPPED  = #x4000; // shifted right 16 bits
ignorable($FILE_ATTRIBUTE_NORMAL, $FILE_FLAG_OVERLAPPED);

// SetFilePointer
// whence argument
define constant $FILE_BEGIN   = 0;
define constant $FILE_CURRENT = 1;
define constant $FILE_END     = 2;
ignorable($FILE_BEGIN, $FILE_CURRENT, $FILE_END);

define constant $ERROR_HANDLE_EOF = 38;


// A useful utility ...

define function call-succeeded? (result :: <machine-word>) => (success :: <boolean>)
  primitive-machine-word-not-equal?
    (primitive-unwrap-machine-word(result),
     integer-as-raw(-1))
end function call-succeeded?;
 

// Now the actual interfaces ...

define function win32-file-exists? (path :: <byte-string>) => (exists? :: <boolean>)
  let attributes = primitive-wrap-machine-word
		     (%call-c-function ("GetFileAttributesA", c-modifiers: "__stdcall")
                          (path :: <raw-byte-string>)
                       => (exists? :: <raw-c-unsigned-long>)
                        (primitive-string-as-raw(path))
                      end);
  call-succeeded?(attributes)
end function win32-file-exists?;

define method win32-open/create
    (path :: <byte-string>, access :: <integer>, share-mode :: <integer>,
     create-mode :: <integer>, #key overlapped? :: <boolean> = #f)
 => (handle :: false-or(<machine-word>))
  let attributes-high-bits :: <integer> =
    if(overlapped?) $FILE_FLAG_OVERLAPPED else 0 end;
  let handle = primitive-wrap-machine-word
                 (primitive-cast-pointer-as-raw
                    (%call-c-function ("CreateFileA", c-modifiers: "__stdcall")
                         (path :: <raw-byte-string>,
                          access :: <raw-c-unsigned-long>,
                          share-mode :: <raw-c-unsigned-long>,
                          security-attrs :: <raw-c-pointer>,
                          create-mode :: <raw-c-unsigned-long>, 
                          file-attrs :: <raw-c-unsigned-long>,
                          template :: <raw-c-pointer>)
                      => (handle :: <raw-c-pointer>)
                       (primitive-string-as-raw(path), 
                        primitive-machine-word-shift-left-low
                          (integer-as-raw(access),
                           integer-as-raw(16)),
                        integer-as-raw(share-mode),
                        primitive-cast-raw-as-pointer(integer-as-raw(0)),
                        integer-as-raw(create-mode),
			primitive-machine-word-logior(
                          primitive-machine-word-shift-left-low
                            (integer-as-raw(attributes-high-bits),
                             integer-as-raw(16)),
			  integer-as-raw($FILE_ATTRIBUTE_NORMAL)),
                        primitive-cast-raw-as-pointer(integer-as-raw(0)))
                     end));
  call-succeeded?(handle) & handle
end method win32-open/create;

define function win32-close (handle :: <machine-word>) => (success? :: <boolean>)
  primitive-raw-as-boolean
    (%call-c-function ("CloseHandle", c-modifiers: "__stdcall")
         (handle :: <raw-c-pointer>) => (success? :: <raw-c-signed-int>)
       (primitive-cast-raw-as-pointer(primitive-unwrap-machine-word(handle)))
     end)
end function win32-close;

define function win32-file-size (handle :: <machine-word>)
 => (fsize :: false-or(<integer>))
  let fsize = primitive-wrap-machine-word
                (%call-c-function ("GetFileSize", c-modifiers: "__stdcall")
                     (handle :: <raw-c-pointer>, lpFileSizeHigh :: <raw-c-pointer>) 
                  => (eof :: <raw-c-unsigned-long>)
                   (primitive-cast-raw-as-pointer(primitive-unwrap-machine-word(handle)),
                    primitive-cast-raw-as-pointer(integer-as-raw(0)))
                 end);
  call-succeeded?(fsize) & raw-as-integer(primitive-unwrap-machine-word(fsize))
end function win32-file-size;

ignorable(win32-set-file-position);
define function win32-set-file-position (handle :: <machine-word>, position :: <integer>)
 => (success? :: <boolean>)
  let newpos = primitive-wrap-machine-word
                (%call-c-function ("SetFilePointer", c-modifiers: "__stdcall")
                     (handle :: <raw-c-pointer>,
                      distance-to-move :: <raw-c-signed-long>,
                      lpDistanceToMoveHigh :: <raw-c-pointer>,
                      move-method :: <raw-c-unsigned-long>)
                  => (newpos :: <raw-c-unsigned-long>)
                   (primitive-cast-raw-as-pointer(primitive-unwrap-machine-word(handle)),
                    integer-as-raw(position),
                    primitive-cast-raw-as-pointer(integer-as-raw(0)),
                    integer-as-raw($FILE_BEGIN))
                 end);
  call-succeeded?(newpos) 
    & primitive-machine-word-equal?
        (primitive-unwrap-machine-word(newpos),
	 integer-as-raw(position))
end function win32-set-file-position;

// NOTE -- Should probably have one of these per thread, possibly per stream ...
define variable actual-count-ptr =
  primitive-wrap-machine-word
    (primitive-cast-pointer-as-raw
       (%call-c-function ("LocalAlloc", c-modifiers: "__stdcall")
           (flags :: <raw-c-unsigned-int>, bytes :: <raw-c-unsigned-int>)
        => (pointer :: <raw-c-pointer>)
         (integer-as-raw(0), integer-as-raw(4))
        end));

define function win32-read
    (handle :: <machine-word>, data :: <buffer>, data-offset :: <integer>, 
     count :: <integer> /* , overlapped :: false-or(<win32-overlapped>) */ )
 => (nread :: false-or(<integer>))
  let success?
    = primitive-raw-as-boolean
        (%call-c-function ("ReadFile", c-modifiers: "__stdcall")
	     (handle :: <raw-c-pointer>, buffer-ptr :: <raw-c-pointer>,
	      count :: <raw-c-unsigned-long>, actual-count :: <raw-c-pointer>,
	      lpOverlapped :: <raw-c-pointer>)
	  => (success? :: <raw-c-signed-int>)
	   (primitive-cast-raw-as-pointer(primitive-unwrap-machine-word(handle)),
	    primitive-cast-raw-as-pointer
	      (primitive-machine-word-add
		 (primitive-cast-pointer-as-raw
		    (primitive-repeated-slot-as-raw(data,
						    primitive-repeated-slot-offset(data))),
		  integer-as-raw(data-offset))),
	    integer-as-raw(count),
	    primitive-cast-raw-as-pointer
	      (primitive-unwrap-machine-word(actual-count-ptr)),
	    primitive-cast-raw-as-pointer(integer-as-raw(0)))
	 end);
  success? := success? | (win32-raw-last-error() = $ERROR_HANDLE_EOF);
  success? & raw-as-integer
               (primitive-c-unsigned-long-at
		  (primitive-unwrap-machine-word(actual-count-ptr),
		   integer-as-raw(0),
		   integer-as-raw(0)))
end function win32-read;

define function win32-write
    (handle :: <machine-word>, data :: <buffer>, data-offset :: <integer>, 
     count :: <integer> /* , overlapped :: false-or(<win32-overlapped>) */ )
 => (nwritten :: false-or(<integer>))
  let success?
    = primitive-raw-as-boolean
        (%call-c-function ("WriteFile", c-modifiers: "__stdcall")
	     (handle :: <raw-c-pointer>, buffer-ptr :: <raw-c-pointer>,
	      count :: <raw-c-unsigned-long>, actual-count :: <raw-c-pointer>,
	      lpOverlapped :: <raw-c-pointer>)
	  => (success? :: <raw-c-signed-int>)
	     (primitive-cast-raw-as-pointer(primitive-unwrap-machine-word(handle)),
	      primitive-cast-raw-as-pointer
		(primitive-machine-word-add
		   (primitive-cast-pointer-as-raw
		      (primitive-repeated-slot-as-raw(data,
						      primitive-repeated-slot-offset(data))),
		    integer-as-raw(data-offset))),
	      integer-as-raw(count),
	      primitive-cast-raw-as-pointer
		(primitive-unwrap-machine-word(actual-count-ptr)),
	      primitive-cast-raw-as-pointer(integer-as-raw(0)))
	 end);
  success? & raw-as-integer
               (primitive-c-unsigned-long-at
                  (primitive-unwrap-machine-word(actual-count-ptr),
                   integer-as-raw(0),
                   integer-as-raw(0)))
end function win32-write;

define function win32-force-output (handle :: <machine-word>) => (success? :: <boolean>)
  primitive-raw-as-boolean
    (%call-c-function ("FlushFileBuffers", c-modifiers: "__stdcall")
         (handle :: <raw-c-pointer>) => (success? :: <raw-c-signed-int>)
       (primitive-cast-raw-as-pointer(primitive-unwrap-machine-word(handle)))
      end)
end function win32-force-output;

//---*** andrewa: ideally we should merge the use of this with win32-last-error
//---*** but until then I've renamed this as win32-raw-last-error.
define function win32-raw-last-error () => (status :: <machine-word>)
  primitive-wrap-machine-word
    (%call-c-function ("GetLastError", c-modifiers: "__stdcall")
         () => (status :: <raw-c-unsigned-long>)
       ()
     end)
end function win32-raw-last-error;

// NOTE -- Should probably have one of these per thread ...
define variable message-buffer-ptr =
  primitive-wrap-machine-word
    (primitive-cast-pointer-as-raw
       (%call-c-function ("LocalAlloc", c-modifiers: "__stdcall")
           (flags :: <raw-c-unsigned-int>, bytes :: <raw-c-unsigned-int>)
        => (pointer :: <raw-c-pointer>)
         (integer-as-raw(0), integer-as-raw(4))
        end));

// What are the proper error codes for a file access error?
define function win32-access-error? () => (access-error? :: <boolean>)
  #f
end function win32-access-error?;
