Module:       gtk2-duim
Synopsis:     GTK2 back-end
Author:	      Scott McKay, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND


/// Color and text style management

define sealed class <gtk2-palette> (<basic-palette>)
  sealed slot port :: false-or(<port>),
    required-init-keyword: port:,
    setter: %port-setter;
end class <gtk2-palette>;

define method make-palette
    (_port :: <gtk2-port>, #key color?, dynamic?, #all-keys)
 => (palette :: <gtk2-palette>)
  make(<gtk2-palette>, port: _port, color?: color?, dynamic?: dynamic?)
end method make-palette;


define method port-default-foreground
    (_port :: <gtk2-port>, sheet :: <sheet>)
 => (foreground :: false-or(<ink>))
  //--- Consult resources here...
  ignoring("port-default-foreground");
  #f
end method port-default-foreground;


define method port-default-background
    (_port :: <gtk2-port>, sheet :: <sheet>)
 => (background :: false-or(<ink>))
  //--- Consult resources here...
  ignoring("port-default-background");
  #f
end method port-default-background;

define method port-default-background
    (_port :: <gtk2-port>, sheet :: <drawing-pane>) => (background :: false-or(<ink>))
  $white
end method port-default-background;

// Viewports try to take their background from their child
define method port-default-background
    (_port :: <gtk2-port>, sheet :: <viewport>) => (background :: false-or(<ink>))
  let child = sheet-child(sheet);    // sheet-child(viewport);
  if (child)
    port-default-background(_port, child)
  else
    next-method()
  end
end method port-default-background;


define method port-default-text-style
    (_port :: <gtk2-port>, sheet :: <sheet>)
 => (text-style :: false-or(<text-style>))
  //--- Consult resources here...
  ignoring("port-default-text-style");
  #f
end method port-default-text-style;


define method do-text-style-mapping
    (_port :: <gtk2-port>, text-style :: <text-style>, character-set)
 => (font :: <gtk2-font>)
  //--- Do this
  not-yet-implemented("do-text-style-mapping")
end method do-text-style-mapping;
