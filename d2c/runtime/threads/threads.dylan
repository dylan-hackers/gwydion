module: threads

// dynamic-bind 
// shadow the given variables within a block we add

define macro dynamic-bind 
    { dynamic-bind (?var:name = ?val:expression)
        ?:body
      end }
     => { begin
            let old-value = ?var;
            block()
              ?var := ?val;
              ?body
            cleanup
              ?var := old-value;
            end
          end }
    { dynamic-bind (?var:name = ?val:expression, ?others:*)
        ?:body
      end }
     => { begin
            let old-value = ?var;
            block()
              ?var := ?val;
              dynamic-bind(?others) ?body end;
            cleanup
              ?var := old-value;
            end
          end }
    { dynamic-bind(?:name(?arg:expression) ?eq:token ?val:expression)
        ?:body
      end }
     => { ?name ## "-dynamic-binder"(?val,
                                     method() ?body end,
                                     ?arg) }
    { dynamic-bind(?:name(?arg:expression) ?eq:token ?val:expression,?others:*)
        ?:body
      end }
     => { ?name ## "-dynamic-binder"(?val,
                                     method()
                                         dynamic-bind(?others)
                                           ?body
                                         end;
                                     end,
                                     ?arg) }
end macro dynamic-bind;

// atomic-increment!
// increments without worrying about atomicity
// Since we don't need to worry about atomicity, we just increment

define macro atomic-increment!
    { atomic-increment!( ?to:expression ) } //- Danger of multiple evaluation
     => { ?to := ?to + 1 }
end macro atomic-increment!;
