module: dylan-user

define library common-dylan
  use dylan, 
    export: { dylan };

  use table-extensions;
  use random;
  use transcendental,
     import: { transcendental => transcendentals },
     export: all;

  export
    common-dylan,
    common-extensions,
    streams-protocol,
    locators-protocol,
    simple-random,
    simple-io,
    byte-vector;
end library;

define module simple-io
  create format-out;
end module;

define module simple-random
  use random,
    import: { <random-state> => <random>, random },
    export: all;
end module;

define module byte-vector
  use extensions,
    export: {<byte>,
	     <byte-vector>};
end module;

define module common-extensions
  use dylan;
  use system, import: { copy-bytes }, export: { copy-bytes };
  use extensions,
    rename: {$not-supplied => $unsupplied,
             on-exit => register-application-exit-function},
    export: {$unsupplied,
             integer-length,
	     false-or,
	     one-of,
	     <format-string-condition>,
	     ignore,
	     key-exists?,
	     register-application-exit-function,
             <byte-character>};
  use %Hash-Tables,
    export: {remove-all-keys!};
  use table-extensions,
    export: {<string-table>};
  create
    <closable-object>,
    close,
    <stream>,
    true?,
    false?,
    position,
    split,
    fill-table!,
    find-element,
    condition-to-string,
    format-to-string;

  export
    /* Numerics */
    //integer-length,

    /* Unsupplied, unfound */
    //$unsupplied,
    supplied?,
    unsupplied?,
    unsupplied,
    $unfound,
    found?,
    unfound?,
    unfound,

    /* Collections */
    //<object-deque>,
    //<stretchy-sequence>,
    <stretchy-object-vector>,
    //concatenate!,
    //position,
    //remove-all-keys!,
    //difference,
    //fill-table!,
    //find-element,
    //key-exists?,

    /* Conditions */
    //<format-string-condition>,
    //condition-to-string,

    /* Debugging */
    //debug-message,

    /* Types */
    //false-or,
    //one-of,
    subclass,

    /* Ignoring */
    //ignore,
    ignorable,

    /* Converting to and from numbers */
    //float-to-string
    integer-to-string,
    number-to-string,
    string-to-integer;
    //string-to-float,

    /* Appliation runtime environment */
    //application-name,
    //application-filename,
    //application-arguments,
    //exit-application;
    //register-exit-application-function,

#if (~mindy)
  export
    \table-definer,
    \iterate,
    \when;

  export
    \%iterate-aux,              // ###
    \%iterate-param-helper,     // ###
    \%iterate-value-helper;     // ###
#endif
end module;

define module common-dylan
  use dylan,
    export: all;
  use extensions,
    import: { <general-integer> => <abstract-integer> },
    export: all;
  use common-extensions,
    export: all;
end module;
  
define module locators-protocol
  create <locator>;
  create supports-open-locator?,
         open-locator,
         supports-list-locator?,
         list-locator;
end module locators-protocol;

define module streams-protocol
  // Conditions
  create <stream-error>,
           stream-error-stream,
         <end-of-stream-error>,
           <incomplete-read-error>,
             stream-error-sequence,
             stream-error-count,
           <incomplete-write-error>,
             stream-error-count;
  // Opening streams
  create open-file-stream;
  // Reading from streams
  create read-element,
         unread-element,
         peek,
         read,
         read-into!,
         discard-input,
         stream-input-available?,
         stream-contents,
         stream-contents-as;
  // Writing to streams
  create write-element,
         write,
         force-output,
         wait-for-io-completion,
         synchronize-output,
         discard-output;
  // Querying streams
  create stream-open?,
         stream-element-type,
         stream-at-end?,
         stream-size;
  // Positioning streams
  create <positionable-stream>,
         stream-position,
         stream-position-setter,
         adjust-stream-position;
end module streams-protocol;

define module common-dylan-internals
  use common-dylan;
  use extensions;
  use cheap-io, import: { puts => write-console };
  use introspection, rename: { subclass-of => subclass-class };
  use simple-io;
  use locators-protocol;
  use streams-protocol;
end module common-dylan-internals;
