module: pr7231

define abstract class <organization> (<object>)
  class slot number :: <integer>, init-function: curry(\+, 40, 2);
end class <organization>;
