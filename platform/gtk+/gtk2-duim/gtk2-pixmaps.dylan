Module:       gtk2-duim
Synopsis:     GTK2 back-end
Author:	   Scott McKay, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define sealed class <gtk2-pixmap> (<pixmap>)
  sealed slot %pixmap,
    init-keyword: pixmap:;
  sealed slot %medium :: <medium>, 
    init-keyword: medium:;
end class <gtk2-pixmap>;

/*
//--- A little wierd that this is called 'medium-drawable', but what the heck
define method medium-drawable
    (pixmap :: <gtk2-pixmap>) => (drawable)
  pixmap.%pixmap
end method medium-drawable;
*/

define method image-width 
    (pixmap :: <gtk2-pixmap>) => (width :: <integer>)
  //--- Do it
end method image-width;

define method image-height 
    (pixmap :: <gtk2-pixmap>) => (width :: <integer>)
  //--- Do it
end method image-height;

define method image-depth 
    (pixmap :: <gtk2-pixmap>) => (width :: <integer>)
  //--- Do it
end method image-depth;

//---*** Should all pixmaps just keep a track of their medium anyway?
define method port 
    (pixmap :: <gtk2-pixmap>) => (port :: <port>)
  port(pixmap.%medium)
end method port;


define method do-make-mirror
    (_port :: <gtk2-port>, sheet :: <pixmap-sheet>)
 => (mirror :: <gtk2-mirror>)
  //--- Do it, or maybe you don't need to do anything
end method do-make-mirror;


define method do-make-pixmap
    (_port :: <gtk2-port>, medium :: <gtk2-medium>, 
     width :: <integer>, height :: <integer>)
 => (pixmap :: <gtk2-pixmap>)
  //--- Do it
end method do-make-pixmap;

define method destroy-pixmap
    (pixmap :: <gtk2-pixmap>) => ()
  //--- Do it
end method destroy-pixmap;


define sealed class <gtk2-pixmap-medium>
    (<gtk2-medium>, 
     <basic-pixmap-medium>)
  sealed slot %pixmap, init-keyword: pixmap:;
  sealed slot %medium, init-keyword: medium:;
end class <gtk2-pixmap-medium>;

define method make-pixmap-medium
    (_port :: <gtk2-port>, sheet :: <sheet>, #key width, height)
 => (medium :: <gtk2-pixmap-medium>)
  //--- Do it
end method make-pixmap-medium;


define method do-copy-area
    (from :: <gtk2-pixmap>, from-x, from-y, width, height,
     to :: <gtk2-pixmap>, to-x, to-y,
     #key function = $boole-1) => ()
  //--- Do it
end method do-copy-area;

define method do-copy-area
    (from :: <gtk2-pixmap>, from-x, from-y, width, height,
     to :: <gtk2-medium>, to-x, to-y,
     #key function = $boole-1) => ()
  //--- Do it
end method do-copy-area;

define method do-copy-area
    (from :: <gtk2-medium>, from-x, from-y, width, height,
     to :: <gtk2-pixmap>, to-x, to-y,
     #key function = $boole-1) => ()
  //--- Do it
end method do-copy-area;

define method do-copy-area
    (from :: <gtk2-medium>, from-x, from-y, width, height,
     to :: <gtk2-medium>, to-x, to-y,
     #key function = $boole-1) => ()
  //--- Do it
end method do-copy-area;
