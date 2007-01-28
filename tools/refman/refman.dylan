synopsis:  This code actually outputs the XML.
author:    Dustin Voss
copyright: © 2007 Dustin Voss
module:    refman

// tlf.method-tlf-parse.method-parameters in theory ought to get me method
// parameter names, but it isn't exported.

// The refman document as a whole.
define function refman (libraries :: <table>, targets :: <sequence>)
=> (refman :: <string>)
  let target-libraries = map(curry(element, libraries), targets);

  format-to-string(
  "<?xml version=\"1.0\" standalone=\"no\"?>"
  "\n<!DOCTYPE refman SYSTEM \"refman.dtd\">"
  "\n<refman>"
  "%s"
  "\n</refman>",
  reduce(concatenate, refman-head(), map(refman-library, target-libraries)));
end;


// The <head> tag.
define function refman-head () => (text :: <string>)
  "\n  <head>"
  "\n    <title></title>"
  "\n    <organization></organization>"
  "\n    <copyright></copyright>"
  "\n    <version></version>"
  "\n  </head>"
end;


// The <library> tag.
define function refman-library (the-library :: <library>) => (text :: <string>)
  let modules-text = "";

  do-exported-modules(the-library,
      method (name, the-module) => ()
        modules-text := concatenate(modules-text, refman-module(the-module))
      end);
  
  format-to-string(
  "\n  <library>"
  "\n    <name>%s</name>"
  "%s"
  "\n  </library>",
  as(<string>, the-library.library-name).xml-esc,
  modules-text);
end;


// The <module> tag.
define function refman-module (the-module :: <module>) => (text :: <string>)
  let entries-text = "";
  
  do-exported-variables(the-module,
      method (name, the-entry) => ()
        entries-text := concatenate(entries-text, refman-entry(the-entry))
      end);
      
  format-to-string(
  "\n    <module>"
  "\n      <name>%s</name>"
  "%s"
  "\n    </module>",
  as(<string>, the-module.module-name).xml-esc,
  entries-text);
end;


// The <entry> tag.
define function refman-entry (the-entry :: <variable>) => (text :: <string>)
  format-to-string(
  "\n      <entry>"
  "\n        <name>%s</name>"
  "%s"
  "\n        <description/>"
  "\n      </entry>",
  as(<string>, the-entry.variable-name).xml-esc,
  refman-entry-defn(the-entry.variable-definition));
end;


// Unhandled definitions.
define method refman-entry-defn (the-entry :: <definition>)
=> (text :: <string>)
  // Do nothing.
  "";
end;


// The <functiondef> tag.
define method refman-entry-defn (the-entry :: <function-definition>)
=> (text :: <string>)
  format-to-string(
  "\n        <functiondef>"
  "%s"
  "\n        </functiondef>",
  refman-func-params(the-entry)
  );
end;


// The <genericdef> tag.
define method refman-entry-defn (the-entry :: <generic-definition>)
=> (text :: <string>)
  let modifiers-text =
      if (the-entry.generic-defn-sealed?) "sealed" else "open" end;
  // let more-methods = map(refman-entry-defn, the-entry.generic-defn-methods));
  format-to-string(
  "\n        <genericdef>"
  "\n          <modifiers>%s</modifiers>"
  "%s"
  "\n        </genericdef>",
  modifiers-text, refman-func-params(the-entry)
  );
end;


// The <variabledef> tag.
define method refman-entry-defn (the-entry :: <variable-definition>)
=> (text :: <string>)
  format-to-string(
  "\n        <variabledef>"
  "\n          <type>%s</type>"
  "\n          <value>%s</value>"
  "\n        </variabledef>",
  disamb-type-from-ctype(the-entry, the-entry.defn-type),
  format-to-string("%s", the-entry.defn-init-value | "unknown").xml-esc
  );
end;


// The <constantdef> tag.
define method refman-entry-defn (the-entry :: <constant-definition>)
=> (text :: <string>)
  format-to-string(
  "\n        <constantdef>"
  "\n          <type>%s</type>"
  "\n          <value>%s</value>"
  "\n        </constantdef>",
  disamb-type-from-ctype(the-entry, the-entry.defn-type),
  format-to-string("%s", the-entry.ct-value | "unknown").xml-esc
  );
end;


// The <classdef> tag. Superclasses of a class are not accessible.
define method refman-entry-defn (the-entry :: <class-definition>)
=> (text :: <string>)
  let class-type = the-entry.class-defn-cclass;

  // Get modifiers.
  let modifiers-text = concatenate(
      if (class-type.abstract?) "abstract " else "concrete " end,
      if (class-type.primary?) "primary " else "free " end,
      if (class-type.sealed?) "sealed" else "open" end,
      if (class-type.functional?) " functional" else "" end);

  // Get superclasses.
  let superclasses-text = reduce(concatenate, "",
      map(curry(format-to-string, "%s "), class-type.direct-superclasses))
      .cdata;

  // Construct <keyword> tags.
  let <keyword>-text = "";
  for (keyword in class-type.keyword-infos)

    // <name> and <type> apply to all keywords.
    <keyword>-text := concatenate(<keyword>-text, format-to-string(
        "\n            <keyword>"
        "\n              <name>%s:</name>"
        "\n              <type>%s</type>"
        "\n              <description>",
        as(<string>, keyword.keyword-symbol).xml-esc,
        disamb-type-from-ctype(the-entry, keyword.keyword-type)));

    // Required and default need to reflected in the description.
    let description-text = "";
    if (keyword.keyword-required?)
      description-text := concatenate(description-text, "Required.");
    elseif (instance?(keyword.slot-init-value, <ct-value>))
      description-text := concatenate(description-text, format-to-string(
          "The default is %s.", keyword.slot-init-value).xml-esc);
    end if;

    // If there is a description, use <p> tag. <p> is not optional.
    unless (description-text.empty?)
      <keyword>-text := concatenate(<keyword>-text, format-to-string(
          "\n                <p>%s</p>", description-text));
    end unless;

    // Finish up.
    <keyword>-text := concatenate(<keyword>-text,
        "\n              </description>"
        "\n            </keyword>");
  end for;

  // Assemble parts.
  format-to-string(
  "\n        <classdef>"
  "\n          <modifiers>%s</modifiers>"
  "\n          <superclasses>%s</superclasses>"
  "\n          <keywords>"
  "%s"
  "\n          </keywords>"
  "\n        </classdef>",
  modifiers-text,
  superclasses-text,
  <keyword>-text
  );
end;

// No support for <typedef> or <exceptiondef>.

// The <macrodef> tag.
define method refman-entry-defn (the-entry :: <macro-definition>)
=> (text :: <string>)
  format-to-string(
  "\n        <macrodef>"
  "\n          %s"
  "\n        </macrodef>",
  the-entry.definition-kind
  );
end;


// The <ins>, <outs>, and <raises> tags.
define method refman-func-params (the-entry :: <function-definition>)
=> (text :: <string>)
  let sig = the-entry.function-defn-signature;

  // Construct <in> tags from any req'd parameters.
  let <in>-list = sig.specializers;
  let <in>-types = map(curry(disamb-type-from-ctype, the-entry), <in>-list);
  let <in>-text = reduce(concatenate, "", 
      map(curry(format-to-string,
          "\n            <in>"
          "\n              <name>arg</name>"
          "\n              <type>%s</type>"
          "\n              <description/>"
          "\n            </in>"), <in>-types));
  
  // Construct <rest-in> tag if necessary.
  let <rest-in>-text =
      if (sig.rest-type)
        format-to-string(
            "\n            <rest-in>"
            "\n              <name>more</name>"
            "\n              <type>%s</type>"
            "\n              <description/>"
            "\n            </rest-in>",
            disamb-type-from-ctype(the-entry, sig.rest-type));
      else
        ""
      end if;
  
  // Construct <keyword-in> tags.
  let <keyword-in>-text = "";
  if (sig.key-infos)
    for (keyword in sig.key-infos)

      // <name> and <type> apply to all keywords.
      <keyword-in>-text := concatenate(<keyword-in>-text, format-to-string(
          "\n            <keyword-in>"
          "\n              <name>%s</name>"
          "\n              <type>%s</type>"
          "\n              <description>",
          as(<string>, keyword.key-name).xml-esc,
          disamb-type-from-ctype(the-entry, keyword.key-type)));
      
      // Required and default need to reflected in the description.
      let description-text = "";
      if (keyword.required?)
        description-text := concatenate(description-text, "Required.");
      elseif (keyword.key-default)
        description-text := concatenate(description-text, format-to-string(
            "The default is %s.", keyword.key-default).xml-esc);
      end if;
      
      // If there is a description, use <p> tag. <p> is not optional.
      unless (description-text.empty?)
        <keyword-in>-text := concatenate(<keyword-in>-text, format-to-string(
            "\n                <p>%s</p>", description-text));
      end unless;
    
      // Finish up.
      <keyword-in>-text := concatenate(<keyword-in>-text,
          "\n              </description>"
          "\n            </keyword-in>");
    end for;
  end if;
  
  // Construct <all-keys> tag.
  let <all-keys>-text =
      if (sig.all-keys?)
        "\n            <all-keys/>"
      else
        ""
      end if;
        
  // Construct <out> tags.
  let <out>-list = sig.returns.positional-types;
  let <out>-types = map(curry(disamb-type-from-ctype, the-entry), <out>-list);
  let <out>-text = reduce(concatenate, "", 
      map(curry(format-to-string,
          "\n            <out>"
          "\n              <name>val</name>"
          "\n              <type>%s</type>"
          "\n              <description/>"
          "\n            </out>"), <out>-types));

  // Construct <rest-out> tag if necessary.
  let <rest-out>-type = sig.returns.rest-value-type;
  let <rest-out>-text =
      if (<rest-out>-type ~== empty-ctype())
        format-to-string(
            "\n            <rest-out>"
            "\n              <name>more</name>"
            "\n              <type>%s</type>"
            "\n              <description/>"
            "\n            </rest-out>",
            disamb-type-from-ctype(the-entry, <rest-out>-type));
      else
        ""
      end if;

  // Assemble tag block. No GD support for <raises> tags.
  format-to-string(
  "\n          <ins>"
  "%s"
  "%s"
  "%s"
  "%s"
  "\n          </ins>"
  "\n          <outs>"
  "%s"
  "%s"
  "\n          </outs>",
  <in>-text, <rest-in>-text, <keyword-in>-text, <all-keys>-text,
  <out>-text, <rest-out>-text);
end;


// Wrap a string in XML's CDATA.
define function cdata (raw :: <string>) => (wrapped :: <string>)
  concatenate("<![CDATA[", raw, "]]>");
end;


// Escape special XML characters.
define function xml-esc (raw :: <string>) => (escaped :: <string>)
  let escaped = substring-replace(raw, "&", "&amp;");
  escaped := substring-replace(escaped, "<", "&lt;");
  escaped := substring-replace(escaped, ">", "&gt;");
end;


// Convert a <ctype> to text and add any library/module specifiers necessary.
define function disamb-type-from-ctype
   (the-entry :: <definition>, ctype :: <ctype>)
=> (text :: <string>)
  // I use format-to-string here to textify ctype.
  let location-string = format-to-string("%s", ctype);
  if (instance?(ctype, <defined-cclass>))

    // Location of current definition.
    let this-module = the-entry.defn-module;
    let this-library = this-module.module-home;
  
    // Location of type.
    let type-var = find-variable(ctype.class-defn.defn-name);
    let type-module = type-var.variable-home;
    let type-library = type-module.module-home;
  
    // Disambiguate like OD does: don't specify library/module if the same.
    // Also, use the DRM's "dylan:dylan" instead of "Dylan-Viscera:Dylan".
    if (type-module ~= this-module)
      location-string := concatenate(location-string, ":",
          if (type-module ~= $Dylan-Module)
            as(<string>, type-module.module-name);
          else
            "dylan";
          end);
    end if;
    if (type-library ~= this-library)
      location-string := concatenate(location-string, ":",
          if (type-library ~= $Dylan-Library)
            as(<string>, type-library.library-name);
          else
            "dylan";
          end);
    end if;
  end if;

  location-string.cdata;
end;


// Get the module of a definition.
define method defn-module (defn :: <definition>) => (module :: <module>)
  defn.defn-name.any-name-module;
end;

define method any-name-module (name :: <basic-name>) => (module :: <module>)
  name.name-module;
end;

define method any-name-module (name :: <method-name>) => (module :: <module>)
  name.method-name-generic-function.name-module;
end;

