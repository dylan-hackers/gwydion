module: search

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

// This code comes from Wikipedia.
define method levenshtein-distance
 (s :: <byte-string>, t :: <byte-string>,
  #key insert-cost: insert-cost :: <integer> = 1,
       delete-cost: delete-cost :: <integer> = 1,
       substitution-cost: substitution-cost :: <integer> = 1
 ) => (distance :: <integer>);
  // for all i and j, d[i,j] will hold the Levenshtein distance between
  // the first i characters of s and the first j characters of t;
  // note that d has (m+1)x(n+1) values
  let m = s.size;
  let n = t.size;
  let d = make(<array>, dimensions: list(m + 1, n + 1));

  for (i from 0 to m)
    d[i, 0] := i // the distance of any first string to an empty second string
  end for;
  for (j from 0 to n)
    d[0, j] := j // the distance of any second string to an empty first string
  end for;

  for (j from 1 to n)
    for (i from 1 to m)
      if (s[i - 1] = t[j - 1])
        d[i, j] := d[i - 1, j - 1];  // no operation required
      else
        d[i, j] := min(d[i - 1, j] + delete-cost,
                       d[i,     j - 1] + insert-cost,
                       d[i - 1, j - 1] + substitution-cost);
      end if;
    end for;
  end for;

  d[m, n]
end method;

define generic similar-name-search(name1, name2) => (weight :: <integer>);

define method similar-name-search(name1 :: <basic-name>, name2 :: <symbol>)
 => (weight :: <integer>);
  levenshtein-distance(as(<byte-string>, name1.name-symbol), as(<byte-string>, name2));
end method;

define method similar-name-search(name1 :: <basic-name>, name2 :: <basic-name>)
 => (weight :: <integer>);
  levenshtein-distance(as(<byte-string>, name1.name-symbol), as(<byte-string>, name2.name-symbol));
end method;

define class <search-results> (<object>)
  constant slot search-text :: <basic-name>, required-init-keyword: search-text:;
  sealed slot result-list :: <stretchy-vector> = make(<stretchy-vector>);
end class;

define sealed domain make(singleton(<search-results>));
define sealed domain initialize(<search-results>);

define class <search-result> (<object>)
  constant slot name :: <symbol>, required-init-keyword: name:;
  slot weight :: false-or(<integer>), init-value: #f, init-keyword: weight:;
end class;

define sealed domain make(singleton(<search-result>));
define sealed domain initialize(<search-result>);

define method print-object(sr :: <search-results>, stream :: <stream>) => ();
  pprint-fields
    (sr, stream,
     search-text: sr.search-text.name-symbol,
     results: sr.result-list);
end method;

define method print-object(sr :: <search-result>, stream :: <stream>) => ();
  pprint-fields
    (sr, stream,
     name: sr.name,
     weight: sr.weight);
end method;

define method \+(s1 :: <search-results>, s2 :: <search-results>) => s3 :: <search-results>;
  let s3 = make(<search-results>, search-text: s1.search-text);
  s3.result-list := concatenate(s1.result-list, s2.result-list);
  s3;
end method;

define method \<(s :: <search-result>, t :: <search-result>)
 => (res :: <boolean>);
  s.weight < t.weight;
end method;

define method closest-search-result(results :: <search-results>,
    #key max-weight :: <integer> = 5)
 => name :: false-or(<symbol>);
  block (return)
    unless (results.result-list.empty?)
      let sorted = sort!(results.result-list);
      if (sorted[0].weight <= max-weight)
        return(sorted[0].name);
      end if;
    end unless;
    #f;
  end block;
end method;

define method ordered-search-results(results :: <search-results>)
 => (names :: <vector>);
  let sorted = sort!(results.result-list);
  sorted;
end method;

define method add-search-result(results :: <search-results>, name :: <symbol>,
    search-function :: <function>)
 => ();
  let weight = search-function(results.search-text, name);
  if (weight)
    let search-result = make(<search-result>, name: name, weight: weight);
    add!(results.result-list, search-result);
  end if;
end method;

define method add-search-result(results :: <search-results>, name :: <basic-name>,
    search-function :: <function>)
 => ();
  let weight = search-function(results.search-text, name);
  if (weight)
    let search-result = make(<search-result>, name: name.name-symbol, weight: weight);
    add!(results.result-list, search-result);
  end if;
end method;
