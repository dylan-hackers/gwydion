module: debugger

define constant $dll-handle = dlopen(as(<c-string>, $null-pointer), $RTLD-LAZY);

define method find-address(symbol-name :: <string>)
 => (ptr :: <raw-pointer>)
  if(symbol-name[0] = '0' & symbol-name[1] = 'x')
    as(<raw-pointer>, string-to-integer(copy-sequence(symbol-name, start: 2),
                                        base: 16));
  else
    if($dll-handle == as(<dll-handle>, $null-pointer))
      signal("An error occurred dlopen()ing 0.\n");
    else
      let object-address =
        dlsym($dll-handle, export-value(<c-string>, symbol-name));
      if(object-address == as(<raw-pointer>, $null-pointer))
        signal("dlsym returned NULL.\n");
      else
        object-address
      end if;
    end;
  end if;
end;

define function find-runtime-object-from-heap-label(symbol-name :: <string>)
 => (obj :: <object>)
  heap-object-at(find-address(symbol-name));
end function find-runtime-object-from-heap-label;

define function inspect-heap-rep(object-address :: <string>)
  block()
    dump-object(heap-object-at(find-address(object-address)));
  exception(condition :: <condition>)
    condition-format(*standard-output*, "%s\r\n", condition);
    force-output(*standard-output*);
    #f
  end block
end function inspect-heap-rep;

define function print-heap-rep(object-address :: <string>)
  block()
    format-out("%=\r\n", (heap-object-at(find-address(object-address))));
  exception(condition :: <condition>)
    condition-format(*standard-output*, "%s\r\n", condition);
    force-output(*standard-output*);
    #f
  end block
end function print-heap-rep;

define function inspect-general-rep(object-address :: <string>)
  block()
    dump-object(general-object-at(find-address(object-address)));
  exception(condition :: <condition>)
    condition-format(*standard-output*, "%s\r\n", condition);
    force-output(*standard-output*);
    #f
  end block
end function inspect-general-rep;

define function print-general-rep(object-address :: <string>)
  block()
    format-out("%=\r\n", (general-object-at(find-address(object-address))));
  exception(condition :: <condition>)
    condition-format(*standard-output*, "%s\r\n", condition);
    force-output(*standard-output*);
    #f
  end block
end function print-general-rep;

make(<command>, name: "Inspect Heap-Representation", 
     command: inspect-heap-rep, 
     summary: "Inspect named C symbol or address.");
make(<command>, name: "Print Heap-Representation", 
     command: print-heap-rep, 
     summary: "Print named C symbol or address.");
make(<command>, name: "Inspect General-Representation", 
     command: inspect-general-rep, 
     summary: "Inspect named C symbol or address.");
make(<command>, name: "Print General-Representation", 
     command: print-general-rep, 
     summary: "Print named C symbol or address.");

define method dump-object(o)
  let oc = o.object-class;
  format-out("%s at %=\r\n", oc.class-name, o.object-address);
  let non-dataword-slots 
    = choose(method(x) 
                 find-slot-offset(oc, x) ~= #"data-word"
             end, oc.class-all-slot-descriptors);
  let sorted-slots = sort(non-dataword-slots,
                          test: method(x, y) 
                                    find-slot-offset(oc, x) <
                                    find-slot-offset(oc, y) end);
  for(slot in sorted-slots)
    format-out("%= %s :: %s == %= (%=)\r\n", 
               find-slot-offset(oc, slot), 
               slot.slot-name | "(unnamed)", 
               slot.slot-type.debug-name,
               generic-slot-getter(o, slot),
               slot.slot-representation);
  end for;
end method dump-object;

define method debug-name(c :: <class>)
  c.class-name;
end method debug-name;

define method debug-name(c :: <union>)
  concatenate("type-union(",
              reduce1(method(x, y) concatenate(x, ", ", y) end,
                      map(debug-name, c.union-members)),
              ")");
  // XXX: missing the singletons...
end method debug-name;

define method debug-name(c :: <byte-character-type>)
  "<byte-character>"
end method debug-name;

define method generic-slot-getter(o :: <object>, slot)
//  if(~slot-initialized?(o, slot.slot-getter))
//    "<uninitialized-slot>"
//  else
  let offset = find-slot-offset(o.object-class, slot);
  select(slot.slot-representation)
    #"boolean-char" =>   
      if(pointer-deref(#"unsigned-char", o.object-address, 
                       offset) = 0)
        #f
      else
        #t
      end if;
    otherwise       =>   
      format-to-string("0x%x", 
                       pointer-deref(#"long", o.object-address, offset));
      
  end;
  //  end if;
end method generic-slot-getter;
