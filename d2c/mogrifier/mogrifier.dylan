module: mogrifier
synopsis: customizable machine-code processor/emitter
author: gabor@mac.com
copyright: 


define generic compile-function(f :: <function>)
 => compiled :: <function>;


define method compile-function(f :: <function>)
 => compiled :: <function>;
  format-out("Hello, world from mogrifier!\n");
  
  // get hold of the function entry point
  // and follow it
  follow(600,
         as(<statically-typed-pointer>,
              call-out("GENERAL_ENTRY", ptr:, ptr:, f.object-address)));
  
  
  let h = 4.9;
  let g = 8.7;
  if (h + g < 12)
     map
  else
     f
  end;
end method compile-function;


define function follow(instructions :: <integer>, p :: <statically-typed-pointer>)
  for (instruction-counter from 0 below instructions)
    let instruction-word = unsigned-long-at(p, offset: instruction-counter * 4);
//    format-out("value is: %d\n", instruction, instruction-word);
    format-out("[%d] mnemonics is: %s\n", instruction-counter, powerpc-disassemble(instruction-word));
    format-out("[%d] branches: %=\n", instruction-counter, branch-target(instruction-counter,
                                                                         make(<powerpc-instruction>, instruction-word: instruction-word)));
    force-output(*standard-output*);
  end for;
end;


define function primary-from-instruction-word(instruction-word :: <integer>)
 => primary :: <primary-field>;
  let primary = ash(instruction-word, -26);
  primary >= 0 & primary | primary + #x40;
end;


define function powerpc-disassemble(instruction :: <integer>, #key simplify :: <boolean> = #t)
 => mnemonics :: <string>;
  let primary = ash(instruction, -26);
  let primary = primary >= 0 & primary | primary + #x40;
  powerpc-disassemble-subcode(simplify, primary, instruction.instruction-mask-subcode, logand(instruction, #x3FFFFFF));
end;


//
// Class <instruction>
//

define abstract class <instruction>(<object>)
end;

define generic disassemble(instr :: <instruction>)
 => mnemonics :: <string>;


//
// Class <powerpc-instruction>
//

define functional class <powerpc-instruction>(<instruction>)
  constant slot instruction-word :: <integer>,
    required-init-keyword: instruction-word:;
end;

define method disassemble(instr :: <powerpc-instruction>)
 => mnemonics :: <byte-string>;
  powerpc-disassemble(instr.instruction-word);
end;

//
// class-for-instruction-subcode
//
// Given a primary and subcode number, returns a class that can be given to \make
//
define generic class-for-instruction-subcode(primary :: <primary-field>, key :: <subcode-field>)
 => class :: subclass(<powerpc-instruction>);

//
// branch-target
//
// Provide information whether the instruction branches away
//
define generic branch-target
  (instruction-counter :: <integer>, instruction :: <powerpc-instruction>)
=> location :: <object>;

define method branch-target
  (instruction-counter :: <integer>, instruction :: <powerpc-instruction>)
=> location :: <object>;
end;

//
// return-target
//
// Provide information whether the instruction records a return address
//
define generic return-target
  (instruction-counter :: <integer>, instruction :: <powerpc-instruction>)
=> (return-storage :: <object>, return-to :: false-or(<integer>));

define method return-target
  (instruction-counter :: <integer>, instruction :: <powerpc-instruction>)
=> (return-storage :: <object>, return-to :: false-or(<integer>));
end;

define method class-for-instruction-subcode(primary :: <primary-field>, key :: <subcode-field>)
 => class :: singleton(<powerpc-instruction>);
  <powerpc-instruction>
end;



define method make(class == <powerpc-instruction>, #rest args, #key instruction-word :: <integer>)
 => instruction :: <powerpc-instruction>;
  let primary = ash(instruction-word, -26);
  let primary = primary >= 0 & primary | primary + #x40;
  let subcode = instruction-word.instruction-mask-subcode;
  
    format-out("%d, %s\n", primary, class-for-instruction-subcode(primary, subcode)); // ####
  apply(next-method, class-for-instruction-subcode(primary, subcode), args);
end;

//
// Class <powerpc-branch-instruction>
//

define functional class <powerpc-branch-instruction>(<powerpc-instruction>)
end;

define generic branch-target-subcode
  (instruction-counter :: <integer>, primary :: <primary-field>, subcode :: <subcode-field>, secondary :: <integer>)
=> location :: <object>;

define method branch-target
  (instruction-counter :: <integer>, instruction :: <powerpc-branch-instruction>)
=> location :: <object>;
  let instruction-word = instruction.instruction-word;
  branch-target-subcode(instruction-counter,
                        primary-from-instruction-word(instruction-word),
                        instruction-mask-subcode(instruction-word),
                        instruction-word)
end;



define generic return-target-subcode
  (instruction-counter :: <integer>, primary :: <primary-field>, subcode :: <subcode-field>, secondary :: <integer>)
=> (return-storage :: <object>, return-to :: false-or(<integer>));

define method return-target
  (instruction-counter :: <integer>, instruction :: <powerpc-branch-instruction>)
=> (return-storage :: <object>, return-to :: false-or(<integer>));
  let instruction-word = instruction.instruction-word;
  return-target-subcode(instruction-counter,
                        primary-from-instruction-word(instruction-word),
                        instruction-mask-subcode(instruction-word),
                        instruction-word)
end;

//
// Limited types
//

// BUG (PR#1414) !! define constant <primary-field> = limited(<integer>, min: 0, max: 63);
define constant <primary-field> = <integer>;
// BUG!! define constant <subcode-field> = limited(<integer>, min: 0, max: 1023);
define constant <subcode-field> = <integer>;

//
// Disassembler generics
//

define generic powerpc-disassemble-subcode
  (simplify :: <boolean>,
   primary :: <primary-field>,
   subcode :: <subcode-field>,
   secondary :: <integer>)
 => mnemo :: <string>;



define method powerpc-disassemble-subcode
  (simplify :: <boolean>,
   primary :: <primary-field>,
   subcode :: <subcode-field>,
   secondary :: <integer>)
 => mnemonics :: <string>;
  format-out("unknown primary: %d, key: %d\n", primary, subcode);
  "???"
end;

define macro instruction-definer
  
  { define updatable instruction ?:name(?primary:expression; S, A, d) ?meta:* end }
  =>
  {
    define instruction ?name(?primary; S, A, d) ?meta end;
    define instruction ?name ## "u"(?primary + 1; S, A, d) ?meta end
  }

  { define instruction ?:name(?primary:expression; ?key:expression; OE; ?form) end }
  =>
  { define method powerpc-disassemble-subcode(simplify :: <boolean>, primary == ?primary, subcode :: one-of(?key, ?key + 512), secondary :: <integer>)
     => mnemonics :: <string>;
      concatenate(?"name", ?form)
    end;
  }

  { define instruction ?:name(?primary:expression; ?key:expression; ?form) end }
  =>
  { define method powerpc-disassemble-subcode(simplify :: <boolean>, primary == ?primary, subcode == ?key, secondary :: <integer>)
     => mnemonics :: <string>;
      concatenate(?"name", ?form)
    end;
  }

  { define instruction ?:name(?primary:expression; ?key:expression; ?rest:*) branch ?branch-stuff:*; ?more:* end }
  =>
  {
    define instruction ?name(?primary; ?key; ?rest) ?more end;
    define branch instruction (?primary, singleton(?key); ?branch-stuff) end;
  }

  { define instruction ?:name(?primary:expression; ?key:expression; ?rest:*) return ?return-stuff:*; ?more:* end }
  =>
  {
    define instruction ?name(?primary; ?key; ?rest) ?more end;
    define returnable instruction (?primary, singleton(?key); ?return-stuff) end;
  }

  { define instruction ?:name(?primary:expression; ?key:expression; ?rest:*) simplify ?simplification-stuff:*; ?more:* end }
  =>
  {
    define instruction ?name(?primary; ?key; ?rest) ?more end;
    define simplifiable instruction (?primary, singleton(?key); ?simplification-stuff) end;
  }

  { define instruction ?:name(?primary:expression; ?rest:*) ?simp:* end }
  =>
  { define instruction ?"name"(?primary; ?rest) ?simp end }

  { define instruction ?:expression(?primary:expression; ?form) end }
  =>
  { define method powerpc-disassemble-subcode(simplify :: <boolean>, primary == ?primary, subcode :: <subcode-field>, secondary :: <integer>)
     => mnemonics :: <string>;
      concatenate(?expression, ?form)
    end;
  }
  
  { define branch instruction (?primary:expression, ?key-type:expression; ?branches) end }
  =>
  {
    define method class-for-instruction-subcode(primary == ?primary, subcode :: ?key-type)
     => class :: singleton(<powerpc-branch-instruction>);
      <powerpc-branch-instruction>
    end;
    define method branch-target-subcode(instruction-counter :: <integer>, primary == ?primary, subcode :: ?key-type, secondary :: <integer>)
     => location :: <object>;
      case
        ?branches;
      end case
    end;
  }
  
  { define returnable instruction (?primary:expression, ?key-type:expression; ?returns) end }
  =>
  {
    define method return-target-subcode(instruction-counter :: <integer>, primary == ?primary, subcode :: ?key-type, secondary :: <integer>)
     => (return-storage :: <object>, return-to :: false-or(<integer>));
      case
        ?returns;
      end case
    end;
  }
  
  { define instruction ?:expression(?primary:expression; ?rest:*) branch ?branch-stuff:*; ?more:* end }
  =>
  {
    define instruction ?expression(?primary; ?rest) ?more end;
    define branch instruction (?primary, <subcode-field>; ?branch-stuff) end;
  }
  
  { define instruction ?:expression(?primary:expression; ?rest:*) return ?return-stuff:*; ?more:* end }
  =>
  {
    define instruction ?expression(?primary; ?rest) ?more end;
    define returnable instruction (?primary, <subcode-field>; ?return-stuff) end;
  }
  
  { define simplifiable instruction (?primary:expression, ?key-type:expression; ?simplifications) end }
  =>
  {
    define method powerpc-disassemble-subcode(simplify == #t, primary == ?primary, subcode :: ?key-type, secondary :: <integer>, #next next-method)
     => mnemonics :: <string>;
      case
        ?simplifications;
        otherwise
          => next-method();
      end case
    end;
  }
  
  { define instruction ?:expression(?primary:expression; ?rest:*) simplify ?simplification-stuff:*; ?more:* end }
  =>
  {
    define instruction ?expression(?primary; ?rest) ?more end;
    define simplifiable instruction (?primary, <subcode-field>; ?simplification-stuff) end;
  }
  
  form:
    { BO, BI, LK } => { secondary.instruction-field-LK, " ", secondary.instruction-field-BO, ",", secondary.instruction-field-BI }
    { BO, BI, BD, ?absolute-type-branch } => { ?absolute-type-branch, " ", secondary.instruction-field-BO, ",", secondary.instruction-field-BI, ",", secondary.instruction-field-BD }
    { LI, ?absolute-type-branch } => { ?absolute-type-branch, " ", secondary.instruction-field-LI }
    { S, A, d } => { " ", secondary.instruction-field-S, ",", secondary.instruction-field-SIMM, "(", secondary.instruction-field-A, ")" }
    { crfD, L, A, SIMM } => { " ", secondary.instruction-field-crfD, ",", secondary.instruction-field-L, ",", secondary.instruction-field-A, ",", secondary.instruction-field-SIMM }
    { crfD, L, A, UIMM } => { " ", secondary.instruction-field-crfD, ",", secondary.instruction-field-L, ",", secondary.instruction-field-A, ",", secondary.instruction-field-UIMM }
    { crfD, L, A, B } => { " ", secondary.instruction-field-crfD, ",", secondary.instruction-field-L, ",", secondary.instruction-field-A, ",", secondary.instruction-field-B }
    { crbD, crbA, crbB } => { " ", secondary.instruction-field-crfD, ",", secondary.instruction-field-crbA, ",", instruction-field-crbB }
    { S, A, B, Rc } => { secondary.instruction-field-Rc, " ", secondary.instruction-field-A, ",", secondary.instruction-field-S, ",", secondary.instruction-field-B }
    { D, A, SIMM } => { " ", secondary.instruction-field-D, ",", secondary.instruction-field-A, ",", secondary.instruction-field-SIMM }
    { D, A, UIMM } => { " ", secondary.instruction-field-D, ",", secondary.instruction-field-A, ",", secondary.instruction-field-UIMM }
    { S, A, UIMM } => { " ", secondary.instruction-field-A, ",", secondary.instruction-field-S, ",", secondary.instruction-field-UIMM }
    { D, A, B } => { " ", secondary.instruction-field-D, ",", secondary.instruction-field-A, ",", secondary.instruction-field-B }
    { D, A, B, Rc } => { secondary.instruction-field-OE, secondary.instruction-field-Rc, " ", secondary.instruction-field-D, ",", secondary.instruction-field-A, ",", secondary.instruction-field-B }
    { D } => { " ", secondary.instruction-field-D }
    { S, A, SH, Rc } => { secondary.instruction-field-Rc, " ", secondary.instruction-field-A, ",", secondary.instruction-field-S, ",", secondary.instruction-field-SH }
    { S, A, SH, MB, ME, Rc } => { secondary.instruction-field-Rc, " ", secondary.instruction-field-A, ",", secondary.instruction-field-S, ",", secondary.instruction-field-SH, ",", secondary.instruction-field-MB, ",", secondary.instruction-field-ME }
    { S, spr } => { " ", secondary.instruction-field-spr, ",", secondary.instruction-field-S }
    { D, spr } => { " ", secondary.instruction-field-D, ",", secondary.instruction-field-spr }
    { S, A, Rc } => { secondary.instruction-field-Rc, " ", secondary.instruction-field-A, ",", secondary.instruction-field-S }

    // simplified forms:
    { crfD, A, B } => { " ", secondary.instruction-field-crfD, ",", secondary.instruction-field-A, ",", secondary.instruction-field-B }
    { A, B } => { " ", secondary.instruction-field-A, ",", secondary.instruction-field-B }
    { crfD, A, SIMM } => { " ", secondary.instruction-field-crfD, ",", secondary.instruction-field-A, ",", secondary.instruction-field-SIMM }
    { crfD, A, UIMM } => { " ", secondary.instruction-field-crfD, ",", secondary.instruction-field-A, ",", secondary.instruction-field-UIMM }
    { A, SIMM } => { " ", secondary.instruction-field-A, ",", secondary.instruction-field-SIMM }
    { A, UIMM } => { " ", secondary.instruction-field-A, ",", secondary.instruction-field-UIMM }
    { BD, ?absolute-type-branch } => { ?absolute-type-branch, ",", secondary.instruction-field-BD }
    { LK } => { secondary.instruction-field-LK }
    { cr, BD, ?absolute-type-branch } => { ?absolute-type-branch, " ", secondary.instruction-field-cr, secondary.instruction-field-BD }

  absolute-type-branch:
    { AA, LK } => { secondary.instruction-field-LK, secondary.instruction-field-AA }


  returns:
    { } => { }
    { ?return, ... } => { ?return; ... }

  return:
    { flagged ?flag => LR ?equals:token ?return-target } => { (?flag) => values(LR: ?return-target) }

  return-target:
    { PC ?plus:token ?:expression } => { (instruction-counter ?plus ?expression) }
    
  branches:
    { } => { }
    { ?branch, ... } => { ?branch; ... }

  branch:
    { flagged ?flag => ?target } => { (?flag) => ?target }
    { flagged ?flag => ?:expression } => { (?flag) => ?expression }
    { unflagged ?flag => ?target } => { (~?flag) => ?target }
    { unflagged ?flag => ?:expression } => { (~?flag) => ?expression }
    { LR } => { #t => #"LR" }
    { CTR } => { #t => #"CTR" }

  target:
    { PC ?plus:token ?field } => { (instruction-counter ?plus (?field * 4)) }
    { ?field } => { (?field) }

  simplifications:
    { } => { }
    { ?simplification, ... } => { ?simplification; ... }

  simplification:
    { field ?field-a ?:token field ?field-b => ?:name(?form) } => { (?field-a ?token ?field-b) => concatenate(?"name", ?form) }
    { field ?field ?:token ?:expression => ?:name(?form) } => { (?field ?token ?expression) => concatenate(?"name", ?form) }
    { flagged ?flag => ?:name(?form) } => { (?flag) => concatenate(?"name", ?form) }
    { unflagged ?flag => ?:name(?form) } => { (~?flag) => concatenate(?"name", ?form) }
    { [?conditions] => ?:name(?form) } => { (?conditions) => concatenate(?"name", ?form) }
    { [?conditions] => ?:name } => { (?conditions) => ?"name" }

  conditions:
    { (?condition) ?:token ... } => { (?condition) ?token ... }
    { [?conditions] ?:token ... } => { (?conditions) ?token ... }
    { (?condition) } => { (?condition) }
    { [?conditions] } => { (?conditions) }

  condition:
    { field ?field-a ?equals:token field ?field-b } => { (?field-a ?equals ?field-b) }
    { field ?field ?equals:token ?:expression } => { (?field ?equals ?expression) }
    { flagged ?flag } => { (?flag) }
    { unflagged ?flag } => { (~?flag) }

  condition-a:
    { ?condition } => { ?condition }

  condition-b:
    { ?condition } => { ?condition }

  field-a:
    { ?field } => { ?field }

  field-b:
    { ?field } => { ?field }

  field:
    { S } => { secondary.instruction-mask-S }
    { B } => { secondary.instruction-mask-B }
    { A } => { secondary.instruction-mask-A }
    { crfD } => { secondary.instruction-mask-crfD }
    { BO } => { secondary.instruction-mask-BO }
    { BI } => { secondary.instruction-mask-BI }
    { BD } => { secondary.instruction-mask-BD }
    { UIMM } => { secondary.instruction-mask-UIMM }
    { LI } => { secondary.instruction-mask-LI }

  flag:
    { L } => { (secondary.instruction-mask-L == 1) }
    { LK } => { (secondary.instruction-mask-LK == 1) }
    { AA } => { (secondary.instruction-mask-AA == 1) }
    { ALWAYS } => { (secondary.instruction-mask-ALWAYS == 1) }
    { TRUE } => { (secondary.instruction-mask-TRUE == 1) }
    { KEEP } => { (secondary.instruction-mask-KEEP == 1) }
    { STOP } => { (secondary.instruction-mask-STOP == 1) }
    { lt } => { (secondary.instruction-mask-lt == 1) }
    { gt } => { (secondary.instruction-mask-gt == 1) }
    { eq } => { (secondary.instruction-mask-eq == 1) }

end macro instruction-definer;


define macro instruction-field-definer

  { define mask-only instruction-field ?:name(?formatter:expression; ?from:expression, ?to:expression) end }
  =>
  {
    define mask-only instruction-field ?name(?from, ?to) end;
  }

  { define mask-only instruction-field ?:name(?from:expression, ?to:expression) end }
  =>
  {
    define inline function "instruction-mask-" ## ?name(secondary :: <integer>)
     => ?name :: <integer>;
      instruction-mask(secondary, ?from, ?to);
    end;
  }

  { define instruction-field ?:name(?formatter:expression; ?from:expression, ?to:expression) end }
  =>
  {
    define mask-only instruction-field ?name(?formatter; ?from, ?to) end;
    
    define function "instruction-field-" ## ?name(secondary :: <integer>)
     => ?name :: <string>;
      format-to-string(?formatter, instruction-mask(secondary, ?from, ?to))
    end;
  }

  { define ?adjectives:* instruction-field ?:name(?formatter:expression; ?bit:expression) end }
  =>
  {
    define ?adjectives instruction-field ?name(?formatter; ?bit, ?bit) end
  }

  { define ?adjectives:* instruction-field ?:name(?all:*) end }
  =>
  {
    define ?adjectives instruction-field ?name("%d"; ?all) end
  }

  { define instruction-field ?:name(?from:expression, ?to:expression) ?:body end }
  =>
  {
    define mask-only instruction-field ?name(?from, ?to) end;

    define function "instruction-field-" ## ?name(secondary :: <integer>)
     => ?name :: <string>;
      let ?name = instruction-mask(secondary, ?from, ?to);
      ?body
    end;
  }

  { define instruction-field ?:name(?bit:expression) ?:body end }
  =>
  {
    define instruction-field ?name(?bit, ?bit) ?body end
  }

end macro;


define mask-only instruction-field subcode(21, 30) end;
define instruction-field BO(6, 10) end;
define instruction-field BI(11, 15) end;
define instruction-field L(10) end;
define instruction-field S("r%d"; 6, 10) end;
define instruction-field D("r%d"; 6, 10) end;
define instruction-field A("r%d"; 11, 15) end;
define instruction-field B("r%d"; 16, 20) end;
define instruction-field crfD("cr%d"; 6, 8) end;
define instruction-field crfS("cr%d"; 11, 13) end;
define instruction-field crbD(6, 8) end;
define instruction-field crbA(11, 15) end;
define instruction-field crbB(16, 20) end;
define instruction-field SH(16, 20) end;
define instruction-field MB(21, 25) end;
define instruction-field ME(26, 30) end;
define instruction-field UIMM(16, 31) end;
define mask-only instruction-field LI(6, 29) end; // SIGNED!!! ######
define mask-only instruction-field BD(16, 29) end; // SIGNED!!!
//define mask-only instruction-field AA(30) end;

// BO flags:
define mask-only instruction-field ALWAYS(6) end;
define mask-only instruction-field TRUE(7) end;
define mask-only instruction-field KEEP(8) end;
define mask-only instruction-field STOP(9) end;
define mask-only instruction-field TAKE(10) end;

// BI flags:
/*
define mask-only instruction-field lt(14, 15) end;
define mask-only instruction-field gt(14, 15) end;
define mask-only instruction-field eq(14, 15) end;
*/

define inline function instruction-mask-lt(secondary :: <integer>)
 => lt :: <integer>;
  instruction-mask(secondary, 14, 15) == 0
  & 1
  | 0
end;

define inline function instruction-mask-gt(secondary :: <integer>)
 => gt :: <integer>;
  instruction-mask(secondary, 14, 15) == 1
  & 1
  | 0
end;

define inline function instruction-mask-eq(secondary :: <integer>)
 => eq :: <integer>;
  instruction-mask(secondary, 14, 15) == 2
  & 1
  | 0
end;


define inline function instruction-field-spr(secondary :: <integer>)
 => spr :: <string>;
  let spr = 32 * instruction-mask(secondary, 16, 20) + instruction-mask(secondary, 11, 15);
  format-to-string("%d", spr)
end;

define inline function instruction-field-SIMM(secondary :: <integer>)
 => SIMM :: <string>;
  let sign = instruction-mask(secondary, 16, 16);
  let d = instruction-mask(secondary, 17, 31);
  let d = sign == 1 & d - ash(1, 15) | d;
  format-to-string("%d", d)
end;

define inline function instruction-field-BD(secondary :: <integer>)
 => bd :: <string>;
  let aa = instruction-mask(secondary, 30, 30);
  let sign = instruction-mask(secondary, 16, 16);
  let bd = instruction-mask(secondary, 17, 29);
  let bd = sign == 1 & bd - ash(1, 13) | bd;
  let bd = 4 * bd;

  if (aa = 1)
    format-to-string("%d", bd)
  else
    format-to-string("$%s%d", bd < 0 & "" | "+", bd)
  end;
end;

define instruction-field AA(30)
  AA == 1
  & "a"
  | ""
end;

define inline function instruction-field-LI(secondary :: <integer>)
 => li :: <string>;
  let aa = instruction-mask(secondary, 30, 30);
  let sign = instruction-mask(secondary, 6, 6);
  let li = instruction-mask(secondary, 7, 29);
  let li = sign == 1 & li - ash(1, 23) | li;
  let li = 4 * li;
  if (aa = 1)
    format-to-string("%d", li)
  else
    format-to-string("$%s%d", li < 0 & "" | "+", li)
  end;
end;

define instruction-field LK(31)
  LK == 1
  & "l"
  | ""
end;

define instruction-field Rc(31)
  Rc == 1
  & "."
  | ""
end;

define instruction-field OE(21)
  OE == 1
  & "O"
  | ""
end;

define instruction-field cr(11, 13)
  cr == 0
  & ""
  | format-to-string("cr%d,", cr)
end;



define constant instruction-position = limited(<integer>, min: 0, max: 31);

define inline function instruction-mask(secondary :: <integer>, start :: instruction-position, stop :: instruction-position)
 => masked :: <integer>;
  logand(ash(secondary, stop - 31), ash(1, stop - start + 1) - 1)
end;


// BO field flags
// 1 2 3 4 5
//
// 1: always flag (makes cond (2) irrelevant)
// 2: true flag
// 3: keep flag (0 if decrement CTR)
// 4: end flag (1 if CTR decremented to zero)
// 5: predict flag



define instruction addis(15; D, A, SIMM) end;
define instruction addi(14; D, A, SIMM) end;
define instruction addic(12; D, A, SIMM) end;
define instruction "addic."(13; D, A, SIMM) end;
define instruction mulli(7; D, A, SIMM) end;

//define instruction (; D, A, UIMM) end;

define instruction or(31; 444; S, A, B, Rc)
  simplify field S = field B
    => mr(S, A, Rc)
end;

define instruction ori(24; S, A, UIMM)
  simplify [(field S = 0) & (field A = 0) & (field UIMM = 0)]
    => nop;
end;

define instruction oris(25; S, A, UIMM) end;

define instruction xor(31; 316; S, A, B, Rc) end;
define instruction lwarx(31; 20; D, A, B) end;

define instruction subfic(8; D, A, SIMM) end;
define instruction subf(31; 40; OE; D, A, B, Rc) end;
define instruction subfc(31; 8; OE; D, A, B, Rc) end;
define instruction subfe(31; 136; OE; D, A, B, Rc) end;


define instruction mulld(31; 233; OE; D, A, B, Rc) end;
define instruction mullw(31; 235; OE; D, A, B, Rc) end;
define instruction divd(31; 489; OE; D, A, B, Rc) end;
define instruction divdu(31; 457; OE; D, A, B, Rc) end;
define instruction divw(31; 491; OE; D, A, B, Rc) end;
define instruction divwu(31; 459; OE; D, A, B, Rc) end;
define instruction add(31; 266; OE; D, A, B, Rc) end;
define instruction addc(31; 10; OE; D, A, B, Rc) end;
define instruction adde(31; 138; OE; D, A, B, Rc) end;

define instruction mfcr(31; 19; D) end;

define instruction bc(16; BO, BI, BD, AA, LK)
  simplify
   [(field BI = 0) & [(field BO = #b01100) | (field BO = #b01101)]]
    => bt(BD, AA, LK), // ### use below method too
   [(flagged lt) & (flagged KEEP) & (flagged TRUE)]
    => blt(cr, BD, AA, LK),
   [(flagged lt) & (flagged KEEP) & (unflagged TRUE)]
    => bnl(cr, BD, AA, LK),
   [(flagged gt) & (flagged KEEP) & (flagged TRUE)]
    => bgt(cr, BD, AA, LK),
   [(flagged gt) & (flagged KEEP) & (unflagged TRUE)]
    => bng(cr, BD, AA, LK),
   [(flagged eq) & (flagged KEEP) & (flagged TRUE)]
    => beq(cr, BD, AA, LK),
   [(flagged eq) & (flagged KEEP) & (unflagged TRUE)]
    => bne(cr, BD, AA, LK);
  branch
   flagged AA
    => BD,
   unflagged AA
    => PC + BD;
  return flagged LK => LR = PC + 4;
end;

define instruction b(18; LI, AA, LK)
  branch flagged AA
    => LI,
   unflagged AA
    => PC + LI;
  return flagged LK => LR = PC + 4;
end;

define instruction bclr(19; 16; BO, BI, LK)
  simplify [(flagged ALWAYS) & (flagged KEEP) & (field BI = 0)]
    => blr(LK);
  branch LR;
  return flagged LK => LR = PC + 4;
end;

define instruction bcctr(19; 528; BO, BI, LK)
  simplify [(flagged ALWAYS) & (flagged KEEP) & (field BI = 0)]
    => bctr(LK);
  branch CTR;
  return flagged LK => LR = PC + 4;
end;

define instruction stmw(47; S, A, d) end;
define updatable instruction stw(36; S, A, d) end;
define updatable instruction sth(44; S, A, d) end;
define updatable instruction stfs(52; S, A, d) end;
define updatable instruction stfd(54; S, A, d) end;
define updatable instruction stb(38; S, A, d) end;
define updatable instruction lwz(32; S, A, d) end;
define instruction lmw(46; S, A, d) end;
define updatable instruction lhz(40; S, A, d) end;
define updatable instruction lha(42; S, A, d) end;
define updatable instruction lfs(48; S, A, d) end;
define updatable instruction lfd(50; S, A, d) end;
define updatable instruction lbz(34; S, A, d) end;
define instruction srawi(31; 824; S, A, SH, Rc) end;
define instruction mtspr(31; 467; S, spr) end;
define instruction mfspr(31; 339; D, spr) end;

define instruction cmp(31; 0; crfD, L, A, B)
  simplify [(field crfD = 0) & (unflagged L)]
    => cmpw(A, B),
   unflagged L
    => cmpw(crfD, A, B);
end;

define instruction cmpi(11; crfD, L, A, SIMM)
  simplify [(field crfD = 0) & (unflagged L)]
    => cmpwi(A, SIMM),
   unflagged L
    => cmpwi(crfD, A, SIMM);
end;

define instruction cmpl(31; 32; crfD, L, A, B)
  simplify [(field crfD = 0) & (unflagged L)]
    => cmplw(A, B),
   unflagged L
    => cmplw(crfD, A, B);
end;

define instruction cmpli(10; crfD, L, A, UIMM)
  simplify [(field crfD = 0) & (unflagged L)]
    => cmplwi(A, UIMM),
   unflagged L
    => cmplwi(crfD, A, UIMM);
end;

define instruction crand(19; 257; crbD, crbA, crbB) end;
define instruction crandc(19; 129; crbD, crbA, crbB) end;
define instruction creqv(19; 289; crbD, crbA, crbB) end;
define instruction crnand(19; 225; crbD, crbA, crbB) end;
define instruction crnor(19; 33; crbD, crbA, crbB) end;
define instruction cror(19; 449; crbD, crbA, crbB) end;
define instruction crorc(19; 417; crbD, crbA, crbB) end;
define instruction crxor(19; 193; crbD, crbA, crbB) end;

define instruction rlwinm(21; S, A, SH, MB, ME, Rc) end;
define instruction extsb(31; 954; S, A, Rc) end;
define instruction extsh(31; 922; S, A, Rc) end;
define instruction extsw(31; 986; S, A, Rc) end; // 64 bit


define function main(name, arguments)
  format-out("Hello, world!\n");
  
//  compile-function(map);
  compile-function(follow);
  exit-application(0);
end function main;

// Invoke our main() function.
main(application-name(), application-arguments());


//------------------------------------------------
// Further thoughts
//------------------------------------------------
/*

define instruction cmpl(31; 32; crfD, L, A, B)
  simplify [(field crfD = 0) & (unflagged L)]
    => cmplw(A, B),
   unflagged L
    => cmplw(crfD, A, B);
   implement primitive #"fixnum-="(A, B) => crfD(eq),
     primitive #"fixnum-<"(A, B) => crfD(lt),
     primitive #"fixnum-<"(B, A) => crfD(gt);
   affect crfD
end;


*/

