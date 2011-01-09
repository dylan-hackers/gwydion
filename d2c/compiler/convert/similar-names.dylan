module: lexenv
copyright: see below

//======================================================================
//
// Copyright (c) 2011  Gwydion Dylan Maintainers
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

define generic search-lexical-environment (lexenv :: <general-lexenv>, name :: <basic-name>,
    search-function :: <function>)
 => (res :: <search-results>);

define method search-lexical-environment (lexenv :: <general-lexenv>, name :: <basic-name>,
    search-function :: <function>)
 => (res :: <search-results>);
  let results = make(<search-results>, search-text: name);
  for (binding in lexenv.lexenv-bindings)
      add-search-result(results, id-name(binding.binding-name), search-function);
  end;
  results
end;

define method search-lexical-environment (lexenv :: <top-level-lexenv>, name :: <basic-name>,
    search-function :: <function>, #next search-my-bindings)
 => (res :: <search-results>);
  search-my-bindings() + search-variables(name, search-function);
end;

define method search-lexical-environment (lexenv :: <lexenv>, name :: <basic-name>, search-function :: <function>,
    #next search-my-bindings)
 => (res :: <search-results>);
  search-my-bindings() + search-lexical-environment(lexenv.lexenv-parent, name, search-function);
end;

