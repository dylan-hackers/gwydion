module: pidgin
synopsis: 
author: 
copyright: 

//==============================================================================
// GCC portability
//==============================================================================

define method construct-include-path
    (extra-includes)
 => (result :: <gcc-include-path>)
  make(<gcc-include-path>,
       standard-include-directories:
         $i386-linux-platform.c-platform-default-include-path,
       extra-include-directories: extra-includes,
       extra-user-include-directories: #());
end method;
