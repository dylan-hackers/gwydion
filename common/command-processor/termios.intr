module: command-processor

define interface
  #include { "termios.h", "cfmakeraw.h" },
  import: {"termios", "tcgetattr", "tcsetattr", "TCSANOW", "cfmakeraw"};
end interface;
