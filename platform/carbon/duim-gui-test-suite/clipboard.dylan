Module:       duim-gui-test-suite
Author:       Andy Armstrong
Synopsis:     DUIM example code
Copyright:    Original Code is Copyright (c) 1995-2000 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

/// Clipboard test

define frame <clipboard-test-frame> (<simple-frame>)
  pane clipboard-text-field (frame)
    make(<text-field>);
  pane main-layout (frame)
    vertically ()
      frame.clipboard-text-field
    end;
  pane file-menu (frame)
    make(<menu>,
	 label: "File",
	 children: vector(frame.exit-button));
  pane exit-button (frame)
    make(<menu-button>,
	 label: "Exit",
	 accelerator: make(<gesture>, keysym: #"z", modifiers: #[#"control"]),
	 activate-callback: method (button)
			      exit-frame(sheet-frame(button))
			    end);
  pane edit-menu (frame)
    make(<menu>,
	 label: "Edit",
	 children: vector(frame.cut-menu-button, 
			  frame.copy-menu-button,
			  frame.paste-menu-button));
  pane cut-menu-button (frame)
    make(<menu-button>,
	 label: "Cut",
	 accelerator: make(<gesture>, keysym: #"x", modifiers: #[#"control"]),
	 activate-callback: method (button)
			      frame-cut(sheet-frame(button))
			    end);
  pane copy-menu-button (frame)
    make(<menu-button>,
	 label: "Copy",
	 accelerator: make(<gesture>, keysym: #"c", modifiers: #[#"control"]),
	 activate-callback: method (button)
			      frame-copy(sheet-frame(button))
			    end);
  pane paste-menu-button (frame)
    make(<menu-button>,
	 label: "Paste",
	 accelerator: make(<gesture>, keysym: #"v", modifiers: #[#"control"]),
	 activate-callback: method (button)
			      frame-paste(sheet-frame(button))
			    end);

  pane cut-button (frame)
    make(<push-button>,
	 label: "X",
	 activate-callback: method (button)
			      frame-cut(sheet-frame(button))
			    end);
  pane copy-button (frame)
    make(<push-button>,
	 label: "C",
	 activate-callback: method (button)
			      frame-copy(sheet-frame(button))
			    end);
  pane paste-button (frame)
    make(<push-button>,
	 label: "P",
	 activate-callback: method (button)
			      frame-paste(sheet-frame(button))
			    end);
  layout (frame) frame.main-layout;
  menu-bar (frame) 
    make(<menu-bar>,
	 children: vector(frame.file-menu, frame.edit-menu));
  tool-bar (frame)
    make(<tool-bar>,
         child: make(<row-layout>,
		     children: vector(frame.cut-button,
				      frame.copy-button,
				      frame.paste-button)));
end frame <clipboard-test-frame>;

define method frame-cut
    (frame :: <clipboard-test-frame>) => (success? :: <boolean>)
  let gadget = clipboard-text-field(frame);
  if (frame-copy(frame))
    gadget-value(gadget) := "";
    #t
  end
end method frame-cut;

define method frame-copy 
    (frame :: <clipboard-test-frame>) => (success? :: <boolean>)
  let gadget = clipboard-text-field(frame);
  with-clipboard (clipboard = gadget)
    if (clipboard)
      let text = selected-text(gadget) | gadget-value(gadget);
      if (add-clipboard-data(clipboard, text))
	#t
      else
	notify-user("Failed to put text onto clipboard", owner: gadget)
      end
    else
      notify-user("Clipboard not available", owner: gadget)
    end
  end
end method frame-copy;

define method frame-paste 
    (frame :: <clipboard-test-frame>) => (success? :: <boolean>)
  let gadget = clipboard-text-field(frame);
  with-clipboard (clipboard = gadget)
    if (clipboard)
      let text = get-clipboard-data-as(<string>, clipboard);
      if (text)
	gadget-value(gadget) := text;
	#t
      else
	notify-user("No text on clipboard", owner: gadget)
      end
    else
      notify-user("Clipboard not available", owner: gadget)
    end
  end
end method frame-paste;


/// Install the test
install-test(<clipboard-test-frame>, "Clipboard");
