Module:       gtk2-duim
Synopsis:     GTK2 back-end
Author:	   Scott McKay, Andy Armstrong
Copyright:    Original Code is Copyright (c) 1995-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// GTK2 gadgets

define open abstract class <gtk2-pane-mixin>
    (<standard-input-mixin>,
     <mirrored-sheet-mixin>)
end class <gtk2-pane-mixin>;


define method do-compose-space 
    (pane :: <gtk2-pane-mixin>, #key width, height)
 => (space-requirement :: <space-requirement>)
  //--- Compute the space requirements of all of the backend gadgets
end method do-compose-space;

/*
define method note-gadget-enabled
    (client, gadget :: <gtk2-pane-mixin>) => ()
  //--- Enable the gadget mirror
end method note-gadget-enabled;

define method note-gadget-disabled 
    (client, gadget :: <gtk2-pane-mixin>) => ()
  //--- Enable the gadget mirror
end method note-gadget-disabled;
*/

define method port-handles-repaint?
    (_port :: <gtk2-port>, sheet :: <gtk2-pane-mixin>) => (true? :: <boolean>)
  //--- Return #t if the port generates damage events for each
  //--- mirrored sheet, in effect, handling repaint itself (this is
  //--- the X model).  Return #f if only one damage event comes in for
  //--- the top level sheet, meaning that repainting of child sheets
  //--- must be done manually (the Mac model).
  #t
end method port-handles-repaint?;

define method default-foreground-setter
    (fg :: <ink>, pane :: <gtk2-pane-mixin>, #next next-method) => (foreground :: <ink>)
  next-method();
  //--- Change the foreground of the gadget
  fg;
end method default-foreground-setter;

define method default-background-setter
    (bg :: <ink>, pane :: <gtk2-pane-mixin>, #next next-method) => (background :: <ink>)
  next-method();
  //--- Change the background of the gadget
  bg;
end method default-background-setter;


define sealed class <gtk2-top-level-sheet>
    (<standard-repainting-mixin>,
     <gtk2-pane-mixin>,
     <top-level-sheet>)
end class <gtk2-top-level-sheet>;

define method class-for-make-pane
    (framem :: <gtk2-frame-manager>, class == <top-level-sheet>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-top-level-sheet>, #f)
end method class-for-make-pane;


define sealed class <gtk2-viewport>
    (<gtk2-pane-mixin>,
     <viewport>,
     <permanent-medium-mixin>,
     <mirrored-sheet-mixin>,
     <single-child-composite-pane>)
end class <gtk2-viewport>;

define method class-for-make-pane 
    (framem :: <gtk2-frame-manager>, class == <viewport>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-viewport>, #f)
end method class-for-make-pane;


define open abstract class <gtk2-button-mixin>
    (<gtk2-pane-mixin>)
end class <gtk2-button-mixin>;

define method do-compose-space
    (pane :: <gtk2-button-mixin>, #key width, height)
 => (space-req :: <space-requirement>)
  ignore(width, height);
  make(<space-requirement>,
       width: 40,
       height: 15)
end method do-compose-space;

define method allocate-space
    (pane :: <gtk2-button-mixin>, width :: <integer>, height :: <integer>)
 => ()
end method allocate-space;


define sealed class <gtk2-push-button-pane>
    (<gtk2-button-mixin>,
     <push-button>,
     <leaf-pane>)
end class <gtk2-push-button-pane>;

define method class-for-make-pane 
    (framem :: <gtk2-frame-manager>, class == <push-button>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-push-button-pane>, #f)
end method class-for-make-pane;

define method handle-event 
    (pane :: <gtk2-push-button-pane>, event :: <button-release-event>) => ()
  execute-activate-callback(pane, gadget-client(pane), gadget-id(pane))
end method handle-event;


define sealed class <gtk2-radio-button-pane>
    (<gtk2-button-mixin>,
     <radio-button>,
     <leaf-pane>)
end class <gtk2-radio-button-pane>;

define method class-for-make-pane 
    (framem :: <gtk2-frame-manager>, class == <radio-button>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-radio-button-pane>, #f)
end method class-for-make-pane;

define method handle-event
    (pane :: <gtk2-radio-button-pane>, event :: <button-release-event>) => ()
  gadget-value(pane, do-callback?: #t) := ~gadget-value(pane)
end method handle-event;


define sealed class <gtk2-check-button-pane>
    (<gtk2-button-mixin>,
     <check-button>,
     <leaf-pane>)
end class <gtk2-check-button-pane>;

define method class-for-make-pane
    (framem :: <gtk2-frame-manager>, class == <check-button>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-check-button-pane>, #f)
end method class-for-make-pane;

define method handle-event 
    (pane :: <gtk2-check-button-pane>, event :: <button-release-event>) => ()
  gadget-value(pane, do-callback?: #t) := ~gadget-value(pane)
end method handle-event;


define sealed class <gtk2-list-box-pane> 
    (<gtk2-pane-mixin>,
     <leaf-pane>,
     <list-box>)
end class <gtk2-list-box-pane>;

define method class-for-make-pane 
    (framem :: <gtk2-frame-manager>, class == <list-box>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-list-box-pane>, #f)
end method class-for-make-pane;


define sealed class <gtk2-menu-bar-pane>
    (<gtk2-pane-mixin>,
     <multiple-child-composite-pane>,
     <menu-bar>)
end class <gtk2-menu-bar-pane>;

define method class-for-make-pane 
    (framem :: <gtk2-frame-manager>, class == <menu-bar>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-menu-bar-pane>, #f)
end method class-for-make-pane;


define sealed class <gtk2-menu-pane>
    (<gtk2-pane-mixin>,
     <multiple-child-composite-pane>,
     <menu>)
end class <gtk2-menu-pane>;

define method class-for-make-pane 
    (framem :: <gtk2-frame-manager>, class == <menu>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-menu-pane>, #f)
end method class-for-make-pane;

//* These won't compile even when I unseal the superclass
//* Comment these back in when we integrate FD 2.0 Gadgets
//* Rob - robmyers@mac.com
/*
define sealed class <gtk2-push-menu-button-pane>
    (<gtk2-button-mixin>,
     <push-menu-button>)
end class <gtk2-push-menu-button-pane>;

define method class-for-make-pane 
    (framem :: <gtk2-frame-manager>, class == <push-menu-button>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-push-menu-button-pane>, #f)
end method class-for-make-pane;


define sealed class <gtk2-radio-menu-button-pane>
    (<gtk2-button-mixin>,
     <radio-menu-button>)
end class <gtk2-radio-menu-button-pane>;

define method class-for-make-pane 
    (framem :: <gtk2-frame-manager>, class == <radio-menu-button>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-radio-menu-button-pane>, #f)
end method class-for-make-pane;


define sealed class <gtk2-check-menu-button-pane>
    (<gtk2-button-mixin>,
     <check-menu-button>)
end class <gtk2-check-menu-button-pane>;

define method class-for-make-pane 
    (framem :: <gtk2-frame-manager>, class == <check-menu-button>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-check-menu-button-pane>, #f)
end method class-for-make-pane;


//--- It might be the case that this does not need to be mirrored,
//--- in which case this class and the 'class-for-make-pane' go away.
define sealed class <gtk2-push-menu-box-pane>
    (<gtk2-pane-mixin>,
     <push-menu-box-pane>)
end class <gtk2-push-menu-box-pane>;

define method class-for-make-pane 
    (framem :: <gtk2-frame-manager>, class == <push-menu-box>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-push-menu-box-pane>, #f)
end method class-for-make-pane;


//--- Same as <gtk2-push-menu-box-pane>
define sealed class <gtk2-radio-menu-box-pane>
    (<gtk2-pane-mixin>,
     <radio-menu-box-pane>)
end class <gtk2-radio-menu-box-pane>;

define method class-for-make-pane 
    (framem :: <gtk2-frame-manager>, class == <radio-menu-box>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-radio-menu-box-pane>, #f)
end method class-for-make-pane;


//--- Same as <gtk2-push-menu-box-pane>
define sealed class <gtk2-check-menu-box-pane>
    (<gtk2-pane-mixin>,
     <check-menu-box-pane>)
end class <gtk2-check-menu-box-pane>;

define method class-for-make-pane 
    (framem :: <gtk2-frame-manager>, class == <check-menu-box>, #key)
 => (class :: <class>, options :: false-or(<sequence>))
  values(<gtk2-check-menu-box-pane>, #f)
end method class-for-make-pane;

*/

//--- Missing
//---  <scroll-bar>
//---  <slider>
//---  <label>
//---  <text-field>
//---  <text-editor>
//---  <option-box>

