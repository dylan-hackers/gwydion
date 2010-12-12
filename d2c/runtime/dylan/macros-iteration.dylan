copyright: see below
module: dylan-viscera

//======================================================================
//
// Copyright (c) 1995 - 1997  Carnegie Mellon University
// Copyright (c) 1998 - 2004  Gwydion Dylan Maintainers
// All rights reserved.
// 
// Use and copying of this software and preparation of derivative
// works based on this software are permitted, including commercial
// use, provided that the following conditions are observed:
// 
// 1. This copyright notice must be retained in full on any copies
//    and on appropriate parts of any derivative works.
// 2. Documentation (paper or online) accompanying any system that
//    incorporates this software, or any part of it, must acknowledge
//    the contribution of the Gwydion Project at Carnegie Mellon
//    University, and the Gwydion Dylan Maintainers.
// 
// This software is made available "as is".  Neither the authors nor
// Carnegie Mellon University make any warranty about the software,
// its performance, or its conformity to any specification.
// 
// Bug reports should be sent to <gd-bugs@gwydiondylan.org>; questions,
// comments and suggestions are welcome at <gd-hackers@gwydiondylan.org>.
// Also, see http://www.gwydiondylan.org/ for updates and documentation. 
//
//======================================================================

// outlined-forward-iteration-protocol-definer -- internal macro
//
// Defines a specialized outlined forward iteration protocol method
// on a collection class.
//

define macro outlined-forward-iteration-protocol-definer
  { define ?adjectives:* outlined-forward-iteration-protocol ?class:name }
    => { define ?adjectives method forward-iteration-protocol (array :: ?class)
          => (initial-state :: <integer>,
              limit :: <integer>,
              next-state :: <function>,
              finished-state? :: <function>,
              current-key :: <function>,
              current-element :: <function>,
              current-element-setter :: <function>,
              copy-state :: <function>);
           values(0,
                  array.size,
                  method (array :: ?class, state :: <integer>)
                   => new-state :: <integer>;
                    state + 1;
                  end,
                  method (array :: ?class, state :: <integer>,
                          limit :: <integer>)
                   => done? :: <boolean>;
                    // We use >= instead of == so that the constraint propagation
                    // stuff can tell that state is < limit if this returns #f.
                    state >= limit;
                  end,
                  method (array :: ?class, state :: <integer>)
                   => key :: <integer>;
                    state;
                  end,
                  method (array :: ?class, state :: <integer>)
                   => element :: <object>;
                    element(array, state);
                  end,
                  method (new-value :: <object>, array :: ?class,
                          state :: <integer>)
                   => new-value :: <object>;
                    element(array, state) := new-value;
                  end,
                  method (array :: ?class, state :: <integer>)
                   => state-copy :: <integer>;
                    state;
                  end);
         end; }
end macro;


// outlined-backward-iteration-protocol-definer -- internal macro
//
// Defines a specialized outlined backward iteration protocol method
// on a collection class.
//

define macro outlined-backward-iteration-protocol-definer
  { define ?adjectives:* outlined-backward-iteration-protocol ?class:name }
    => { define ?adjectives method backward-iteration-protocol (array :: ?class)
          => (initial-state :: <integer>,
              limit :: <integer>,
              next-state :: <function>,
              finished-state? :: <function>,
              current-key :: <function>,
              current-element :: <function>,
              current-element-setter :: <function>,
              copy-state :: <function>);
           values(array.size - 1,
                  -1,
                  method (array :: ?class, state :: <integer>)
                   => next-state :: <integer>;
                    state - 1;
                  end,
                  method (array :: ?class, state :: <integer>,
                          limit :: <integer>)
                   => done :: <boolean>;
                    state == limit;
                  end,
                  method (array :: ?class, state :: <integer>)
                   => key :: <integer>;
                    state;
                  end,
                  method (array :: ?class, state :: <integer>)
                   => element :: <object>;
                    element(array, state);
                  end,
                  method (new-value :: <object>, array :: ?class,
                          state :: <integer>)
                   => new-value :: <object>;
                    element(array, state) := new-value;
                  end,
                  method (array :: ?class, state :: <integer>)
                   => state-copy :: <integer>;
                    state;
                  end);
         end; }
end macro;
