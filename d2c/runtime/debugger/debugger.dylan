module: debugger

define class <interactive-debugger> (<debugger>)
end class <interactive-debugger>;

define method invoke-debugger
    (debugger :: <debugger>, condition :: <condition>)
    => (#rest values);
  condition-format(*standard-output*, "%s\r\n", condition);
  force-output(*standard-output*);
  run-command-processor()
end method invoke-debugger;

*debugger* := make(<interactive-debugger>);
