module: pr7231
use-libraries: common-dylan, io
use-modules: dylan, common-dylan, streams, standard-io, simple-io


///define abstract class <organization> (<object>)
define concrete class <organization> (<object>)
  class slot number :: <integer>, init-function: curry(\+, 40, 2);
  class slot number2 :: <integer> = curry(\+, 40, 2)();
end class <organization>;


begin
  format-out("HEY\n");
  let o = make(<organization>);
  format-out("number: %=, number2: %=\n", o.number, o.number2);
  force-output(*standard-output*);
end;

