module: redirect-io

// Condition-Format and Condition-Force-Output methods.
//
// Condition-Format and Condition-Force-Output are generic functions that are
// called by the condition system to service its output needs.  We supply
// method on <stream>s that call the <stream> specific functions.
//
define method condition-format
    (stream :: <stream>, string :: <string>, #rest args) => ();
  apply(format, stream, string, args);
end method condition-format;

//
define method condition-force-output
    (stream :: <stream>) => ();
  force-output(stream);
end method condition-force-output;
