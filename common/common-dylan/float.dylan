Module: common-dylan-internals
Author:       Peter S. Housel
Copyright:    Original Code is Copyright 2003-2004 Gwydion Dylan Maintainers
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define constant $digits = "0123456789";

define constant $minimum-normalized-single-significand :: <extended-integer>
  = ash(#e1, float-digits(1.0s0) - 1);
define constant $minimum-normalized-double-significand :: <extended-integer>
  = ash(#e1, float-digits(1.0d0) - 1);
define constant $minimum-normalized-extended-significand :: <extended-integer>
  = ash(#e1, float-digits(1.0x0) - 1);

define method float-to-string
    (v :: <float>)
 => (string :: <byte-string>);
  let s :: <stretchy-vector> = make(<stretchy-vector>);
  let adds = curry(add!, s);
  
  let v = if (negative?(v)) add!(s, '-'); -v; else v end;

  if (zero?(v))
    do(adds, "0.0");
  elseif (v ~= v)
    do(adds, "{NaN}");
  elseif (v + v = v)
    do(adds, "{infinity}");
  else
    let (exponent :: <integer>, digits :: <list>) = float-decimal-digits(v);
    
    if (-3 <= exponent & exponent <= 0)
      do(adds, "0.");
      for (i from exponent below 0)
        add!(s, '0');
      end for;
      for (digit in digits)
        add!(s, $digits[as(<integer>, digit)]);
      end for;
    elseif (0 < exponent & exponent < 8)
      for (digit in digits, place from exponent by -1)
        if (place = 0)
          add!(s, '.');
        end;
        add!(s, $digits[as(<integer>, digit)]);
      finally
        for (i from place above 0 by -1)
          add!(s, '0');
        end;
        if (place >= 0)
          do(adds, ".0");
        end;
      end for;
    else
      for (digit in digits, first? = #t then #f)
        add!(s, $digits[as(<integer>, digit)]);
        if (first?)
          add!(s, '.')
        end;
      end;
      if (digits.size = 1)
        add!(s, '0');
      end;
      add!(s, 'e');
      do(adds, integer-to-string(exponent - 1));
    end if;
  end if;
  as(<byte-string>, s)
end method;

define not-inline method float-decimal-digits
    (v :: <single-float>,
     #key round-significant-digits: i :: false-or(<integer>),
          round-position: j :: false-or(<integer>))
 => (exponent :: <integer>, digits :: <list>);
  if (i | j)
    float-decimal-digits-fixed(v, i, j, $minimum-single-float-exponent,
                               $minimum-normalized-single-significand)
  else
    float-decimal-digits-free(v, $minimum-single-float-exponent,
                              $minimum-normalized-single-significand)
  end if;
end method;

define not-inline method float-decimal-digits
    (v :: <double-float>,
     #key round-significant-digits: i :: false-or(<integer>),
          round-position: j :: false-or(<integer>))
 => (exponent :: <integer>, digits :: <list>);
  if (i | j)
    float-decimal-digits-fixed(v, i, j, $minimum-double-float-exponent,
                               $minimum-normalized-double-significand)
  else
    float-decimal-digits-free(v, $minimum-double-float-exponent,
                              $minimum-normalized-double-significand)
  end if;
end method;

define not-inline method float-decimal-digits
    (v :: <extended-float>,
     #key round-significant-digits: i :: false-or(<integer>),
          round-position: j :: false-or(<integer>))
 => (exponent :: <integer>, digits :: <list>);
  if (i | j)
    float-decimal-digits-fixed(v, i, j, $minimum-extended-float-exponent,
                               $minimum-normalized-extended-significand)
  else
    float-decimal-digits-free(v, $minimum-extended-float-exponent,
                              $minimum-normalized-extended-significand)
  end if;
end method;

define inline-only method float-decimal-digits-free
    (v :: <float>,
     minimum-exponent :: <integer>,
     minimum-normalized-significand :: <extended-integer>)
 => (exponent :: <integer>, digits :: <list>);
  local
    // The following methods implement the free-format conversion
    // algorithm by Burger and Dybvig, as described in "Printing
    // Floating-Point Numbers Quickly and Accurately", in the 1996
    // ACM PLDI conference proceedings.
    // 
    // Set initial values according to Table I.
    //
    method initial
        (v :: <float>, f :: <extended-integer>, e :: <integer>)
     => (exponent :: <integer>, digits :: <list>);
      let round? = (even?(f));

      if (e >= 0)
        let be = ash(#e1, e);
        if (f ~= minimum-normalized-significand)
          scale(f * be * 2, #e2, be, be, 0, round?, round?, v);
        else
          scale(f * be * 4, #e4, be * 2, be, 0, round?, round?, v);
        end if;
      else
        if (e = minimum-exponent | f ~= minimum-normalized-significand)
          scale(f * 2, ash(#e1, 1 - e), #e1, #e1, 0, round?, round?, v);
        else
          scale(f * 4, ash(#e1, 2 - e), #e2, #e1, 0, round?, round?, v);
        end if;
      end if;
    end,

    // Scale to the appropriate power of 10 using an estimate of
    // the base-10 logarithm.
    //
    method scale
        (r :: <extended-integer>, s :: <extended-integer>,
         m+ :: <extended-integer>, m- :: <extended-integer>,
         k :: <integer>,
         low-ok? :: <boolean>, high-ok? :: <boolean>,
         v :: <float>)
     => (exponent :: <integer>, digits :: <list>);
      let log-estimate = ceiling(logn(v, 10) - 1d-10);
      if (log-estimate >= 0)
        fixup(r, s * #e10 ^ log-estimate, m+, m-, log-estimate,
              low-ok?, high-ok?);
      else
        let scale = #e10 ^ -log-estimate;
        fixup(r * scale, s, m+ * scale, m- * scale, log-estimate,
              low-ok?, high-ok?);
      end if;
    end,

    // Fix up the log estimate, which might be 1 too small.
    //
    method fixup
        (r :: <extended-integer>, s :: <extended-integer>,
         m+ :: <extended-integer>, m- :: <extended-integer>,
         k :: <integer>,
         low-ok? :: <boolean>, high-ok? :: <boolean>)
     => (exponent :: <integer>, digits :: <list>);
      if ((if (high-ok?) \>= else \> end)(r + m+, s)) // log estimate too low?
        values(k + 1, generate(r, s, m+, m-, low-ok?, high-ok?));
      else
        values(k, generate(r * 10, s, m+ * 10, m- * 10, low-ok?, high-ok?));
      end;
    end,

    // Digit generation loop
    //
    method generate
        (r :: <extended-integer>, s :: <extended-integer>,
         m+ :: <extended-integer>, m- :: <extended-integer>,
         low-ok? :: <boolean>, high-ok? :: <boolean>)
     => (digits :: <list>);
      let (d :: <extended-integer>, r :: <extended-integer>) = truncate/(r, s);

      let tc1 = (if (low-ok?) \<= else \< end)(r, m-);
      let tc2 = (if (high-ok?) \>= else \> end)(r + m+, s);

      if (~tc1)
        if (~tc2)
          pair(d, generate(r * 10, s, m+ * 10, m- * 10, low-ok?, high-ok?));
        else
          list(d + 1);
        end;
      else
        if (~tc2)
          list(d);
        elseif(r * 2 < s)
          list(d);
        else
          list(d + 1);
        end if;
      end if;
    end;

  let (f :: <extended-integer>, e :: <integer>, sign :: <integer>)
    = integer-decode-float(v);

  initial(v, f, e)
end method float-decimal-digits-free;

define inline-only method float-decimal-digits-fixed
    (v :: <float>, i :: false-or(<integer>), j :: false-or(<integer>),
     minimum-exponent :: <integer>,
     minimum-normalized-significand :: <extended-integer>)
 => (exponent :: <integer>, digits :: <list>);
  local
    // The following methods implement the fixed-format conversion
    // algorithm by Burger and Dybvig, as described in "Printing
    // Floating-Point Numbers Quickly and Accurately", in the 1996
    // ACM PLDI conference proceedings.
    // 
    // Set initial values according to Table I.  The high and low
    // limits due to the floating-point precision are compared with
    // the limits due to the requested rounding precision, and the larger
    // range is used.  (Since integer arithmetic is being used, we express
    // the limits in terms of the common denominator s).
    //
    method initial
        (v :: <float>, f :: <extended-integer>, e :: <integer>,
         j :: <integer>, k :: <integer>)
     => (exponent :: <integer>, digits :: <list>);
      let round? = (even?(f));

      if (e >= 0)
        let b^e = ash(#e1, e);
        if (f ~= minimum-normalized-significand)
          let limit = if (j < 0) #e0 else #e10 ^ j end;
          if (limit >= b^e)
            scale(f * b^e * 2, #e2, limit, limit, j, k, #t, #t);
          else
            scale(f * b^e * 2, #e2, b^e, b^e, j, k, round?, round?);
          end if;
        else
          let limit
            = if (j < 0) truncate/(2, #e10 ^ -j) else 2 * (#e10 ^ j) end;
          if (limit >= b^e * 2)
            scale(f * b^e * 4, #e4, limit, limit, j, k, #t, #t);
          elseif (limit >= b^e)
            scale(f * b^e * 4, #e4, b^e * 2, limit, j, k, round?, #t);
          else
            scale(f * b^e * 4, #e4, b^e * 2, b^e, j, k, round?, round?);
          end if;
        end if;
      else
        if (e = minimum-exponent | f ~= minimum-normalized-significand)
          let b^-e = ash(#e1, -e);
          let limit
            = if (j < 0) truncate/(b^-e, #e10 ^ -j) else b^-e * (#e10 ^ j) end;
          if (limit >= #e1)
            scale(f * 2, ash(#e1, 1 - e), limit, limit, j, k, #t, #t);
          else
            scale(f * 2, ash(#e1, 1 - e), #e1, #e1, j, k, round?, round?);
          end if;
        else
          let b^-e+1 = ash(#e1, 1 - e);
          let limit
            = if (j < 0) truncate/(b^-e+1, #e10 ^ -j)
              else b^-e+1 * (#e10 ^ j) end;
          if (limit >= #e2)
            scale(f * 4, ash(#e1, 2 - e), limit, limit, j, k, #t, #t);
          elseif (limit >= #e1)
            scale(f * 4, ash(#e1, 2 - e), #e2, limit, j, k, round?, #t);
          else
            scale(f * 4, ash(#e1, 2 - e), #e2, #e1, j, k, round?, round?);
          end if;
        end if;
      end if;
    end,

    // Scale to the appropriate power of 10 using an estimate of
    // the base-10 logarithm.
    //
    method scale
        (r :: <extended-integer>, s :: <extended-integer>,
         m+ :: <extended-integer>, m- :: <extended-integer>,
         j :: <integer>, k :: <integer>,
         low-ok? :: <boolean>, high-ok? :: <boolean>)
     => (exponent :: <integer>, digits :: <list>);
      if (k >= 0)
        fixup(r, s * #e10 ^ k, m+, m-, j, k, low-ok?, high-ok?);
      else
        let scale = #e10 ^ -k;
        fixup(r * scale, s, m+ * scale, m- * scale, j, k, low-ok?, high-ok?);
      end if;
    end,

    // Fix up the log estimate, which might be 1 too small.
    //
    method fixup
        (r :: <extended-integer>, s :: <extended-integer>,
         m+ :: <extended-integer>, m- :: <extended-integer>,
         j :: <integer>, k :: <integer>,
         low-ok? :: <boolean>, high-ok? :: <boolean>)
     => (exponent :: <integer>, digits :: <list>);
      if ((if (high-ok?) \>= else \> end)(r + m+, s)) // log estimate too low?
        values(k + 1,
               generate(r, s, m+, m-, j, k, low-ok?, high-ok?));
      else
        values(k,
               generate(r * 10, s, m+ * 10, m- * 10, j, k - 1,
                        low-ok?, high-ok?));
      end;
    end,

    // Digit generation loop
    //
    method generate
        (r :: <extended-integer>, s :: <extended-integer>,
         m+ :: <extended-integer>, m- :: <extended-integer>,
         j :: <integer>, k :: <integer>,
         low-ok? :: <boolean>, high-ok? :: <boolean>)
     => (digits :: <list>);
      let (d :: <extended-integer>, r :: <extended-integer>) = truncate/(r, s);

      let tc1 = (if (low-ok?) \<= else \< end)(r, m-);
      let tc2 = (if (high-ok?) \>= else \> end)(r + m+, s);

      if (~tc1)
        if (~tc2)
          pair(d, generate(r * 10, s, m+ * 10, m- * 10, j, k - 1,
                           low-ok?, high-ok?));
        else
          pair(d + 1, generate-trailing(r * 10, s, m+ * 10, m- * 10, j, k - 1,
                                        low-ok?, high-ok?));
        end;
      else
        if (~tc2)
          pair(d, generate-trailing(r * 10, s, m+ * 10, m- * 10, j, k - 1,
                                    low-ok?, high-ok?));
        elseif (k < j)
          list(0);
        elseif (r * 2 < s)
          pair(d, generate-trailing(r * 10, s, m+ * 10, m- * 10, j, k - 1,
                                    low-ok?, high-ok?));
        else
          pair(d + 1, generate-trailing(r * 10, s, m+ * 10, m- * 10, j, k - 1,
                                        low-ok?, high-ok?));
        end if;
      end if;
    end,

    // Trailing zero generation loop
    //
    method generate-trailing
        (r :: <extended-integer>, s :: <extended-integer>,
         m+ :: <extended-integer>, m- :: <extended-integer>,
         j :: <integer>, k :: <integer>,
         low-ok? :: <boolean>, high-ok? :: <boolean>)
     => (digits :: <list>);
      if (k < j)
        #()
      elseif ((if (high-ok?) \>= else \> end)(r + m+, s))
        list(0)
      else
        pair(0, generate-trailing(r * 10, s, m+ * 10, m- * 10, j, k - 1,
                                  low-ok?, high-ok?))
      end if;
    end;

  let (f :: <extended-integer>, e :: <integer>, sign :: <integer>)
    = integer-decode-float(v);
  let k = ceiling(logn(v, 10) - 1d-10);

  if (j)
    if (i)
      error("Only one of round-significant-digits: and round-position: "
              "may be specified");
    end;
    
    initial(v, f, e, j, k)
  else
    if (v + (10.0 ^ (k - i)) / 2 < 10.0 ^ k)
      initial(v, f, e, k - i, k)
    else
      initial(v, f, e, k + 1 - i, k + 1)
    end if;
  end if;
end method float-decimal-digits-fixed;



define method string-to-float
    (string :: <byte-string>,
     #key _start :: <integer> = 0, 
          end: _end :: <integer> = size(string),
          default-class :: subclass(<float>) = <double-float>)
 => (result :: <float>, next-key :: <integer>);
  local
    method integer-part
        (index :: <integer>, neg? :: <boolean>, mantissa :: <extended-integer>)
     => (result :: <float>, next-key :: <integer>);
      if(index >= _end)
        finish-float(index, neg?, mantissa, 0, #f, 0, default-class);
      else
        select(string[index])
          '0' => integer-part(index + 1, neg?, mantissa * 10 + 0);
          '1' => integer-part(index + 1, neg?, mantissa * 10 + 1);
          '2' => integer-part(index + 1, neg?, mantissa * 10 + 2);
          '3' => integer-part(index + 1, neg?, mantissa * 10 + 3);
          '4' => integer-part(index + 1, neg?, mantissa * 10 + 4);
          '5' => integer-part(index + 1, neg?, mantissa * 10 + 5);
          '6' => integer-part(index + 1, neg?, mantissa * 10 + 6);
          '7' => integer-part(index + 1, neg?, mantissa * 10 + 7);
          '8' => integer-part(index + 1, neg?, mantissa * 10 + 8);
          '9' => integer-part(index + 1, neg?, mantissa * 10 + 9);
            
          '.' => fraction-part(index + 1, neg?, mantissa, 0);

          'e', 'E' =>
            exponent-sign(index + 1, neg?, mantissa, 0, default-class);
          's', 'S' =>
            exponent-sign(index + 1, neg?, mantissa, 0, <single-float>);
          'd', 'D' =>
            exponent-sign(index + 1, neg?, mantissa, 0, <double-float>);
          'x', 'X' =>
            exponent-sign(index + 1, neg?, mantissa, 0, <extended-float>);
          
          otherwise =>
            finish-float(index, neg?, mantissa, 0, #f, 0, default-class);
        end select;
      end if;
    end,
    method fraction-part
        (index :: <integer>, neg? :: <boolean>, mantissa :: <extended-integer>,
         scale :: <integer>)
     => (result :: <float>, next-key :: <integer>);
      if(index >= _end)
        finish-float(index, neg?, mantissa, scale, #f, 0, default-class);
      else
        select(string[index])
          '0' => fraction-part(index + 1, neg?, mantissa * 10 + 0, scale + 1);
          '1' => fraction-part(index + 1, neg?, mantissa * 10 + 1, scale + 1);
          '2' => fraction-part(index + 1, neg?, mantissa * 10 + 2, scale + 1);
          '3' => fraction-part(index + 1, neg?, mantissa * 10 + 3, scale + 1);
          '4' => fraction-part(index + 1, neg?, mantissa * 10 + 4, scale + 1);
          '5' => fraction-part(index + 1, neg?, mantissa * 10 + 5, scale + 1);
          '6' => fraction-part(index + 1, neg?, mantissa * 10 + 6, scale + 1);
          '7' => fraction-part(index + 1, neg?, mantissa * 10 + 7, scale + 1);
          '8' => fraction-part(index + 1, neg?, mantissa * 10 + 8, scale + 1);
          '9' => fraction-part(index + 1, neg?, mantissa * 10 + 9, scale + 1);
      
          'e', 'E' =>
            exponent-sign(index + 1, neg?, mantissa, scale, default-class);
          's', 'S' =>
            exponent-sign(index + 1, neg?, mantissa, scale, <single-float>);
          'd', 'D' =>
            exponent-sign(index + 1, neg?, mantissa, scale, <double-float>);
          'x', 'X' =>
            exponent-sign(index + 1, neg?, mantissa, scale, <extended-float>);
          
          otherwise =>
            finish-float(index, neg?, mantissa, scale, #f, 0, default-class);
        end select;
      end if;
    end,
    method exponent-sign
        (index :: <integer>, neg? :: <boolean>, mantissa :: <extended-integer>,
         scale :: <integer>,
         class :: subclass(<float>))
     => (result :: <float>, next-key :: <integer>);
      if (index >= _end)
        error("unrecognized floating-point number");
      else
        select(string[index])
          '-' =>
            if (index + 1 >= _end)
              error("unrecognized floating-point number");
            else
              exponent-part(index + 1, neg?, mantissa, scale, #t, 0, class);
            end;
          '+' =>
            if (index + 1 >= _end)
              error("unrecognized floating-point number");
            else
              exponent-part(index + 1, neg?, mantissa, scale, #f, 0, class);
            end;

          '0' => exponent-part(index + 1, neg?, mantissa, scale, #f, 0, class);
          '1' => exponent-part(index + 1, neg?, mantissa, scale, #f, 1, class);
          '2' => exponent-part(index + 1, neg?, mantissa, scale, #f, 2, class);
          '3' => exponent-part(index + 1, neg?, mantissa, scale, #f, 3, class);
          '4' => exponent-part(index + 1, neg?, mantissa, scale, #f, 4, class);
          '5' => exponent-part(index + 1, neg?, mantissa, scale, #f, 5, class);
          '6' => exponent-part(index + 1, neg?, mantissa, scale, #f, 6, class);
          '7' => exponent-part(index + 1, neg?, mantissa, scale, #f, 7, class);
          '8' => exponent-part(index + 1, neg?, mantissa, scale, #f, 8, class);
          '9' => exponent-part(index + 1, neg?, mantissa, scale, #f, 9, class);

          otherwise =>
            finish-float(index, neg?, mantissa, scale, #f, 0, class);
        end select;
      end if;
    end,
    method exponent-part
        (index :: <integer>, neg? :: <boolean>, mantissa :: <extended-integer>,
         scale :: <integer>, eneg? :: <boolean>, exponent :: <integer>,
         class :: subclass(<float>))
     => (result :: <float>, next-key :: <integer>);
      if(index >= _end)
        finish-float(index, neg?, mantissa, scale, eneg?, exponent, class);
      else
        select(string[index])
          '0' => exponent-part(index + 1, neg?, mantissa, scale,
                               eneg?, exponent * 10 + 0, class);
          '1' => exponent-part(index + 1, neg?, mantissa, scale,
                               eneg?, exponent * 10 + 1, class);
          '2' => exponent-part(index + 1, neg?, mantissa, scale,
                               eneg?, exponent * 10 + 2, class);
          '3' => exponent-part(index + 1, neg?, mantissa, scale,
                               eneg?, exponent * 10 + 3, class);
          '4' => exponent-part(index + 1, neg?, mantissa, scale,
                               eneg?, exponent * 10 + 4, class);
          '5' => exponent-part(index + 1, neg?, mantissa, scale,
                               eneg?, exponent * 10 + 5, class);
          '6' => exponent-part(index + 1, neg?, mantissa, scale,
                               eneg?, exponent * 10 + 6, class);
          '7' => exponent-part(index + 1, neg?, mantissa, scale,
                               eneg?, exponent * 10 + 7, class);
          '8' => exponent-part(index + 1, neg?, mantissa, scale,
                               eneg?, exponent * 10 + 8, class);
          '9' => exponent-part(index + 1, neg?, mantissa, scale,
                               eneg?, exponent * 10 + 9, class);
          otherwise =>
            finish-float(index, neg?, mantissa, scale, eneg?, exponent, class);
        end select;
      end if;
    end,
    method finish-float
        (index :: <integer>, neg? :: <boolean>, mantissa :: <extended-integer>,
         scale :: <integer>, eneg? :: <boolean>, exponent :: <integer>,
         class :: subclass(<float>))
     => (result :: <float>, next-key :: <integer>);
      let exponent = if(eneg?) -exponent else exponent end;
      let bits
        = select(class)
            <single-float> => float-digits(1.0s0);
            <double-float> => float-digits(1.0d0);
            <extended-float> => float-digits(1.0x0);
          end;
      values(if(neg?)
               -bellerophon(mantissa, exponent - scale, class, bits);
             else
               bellerophon(mantissa, exponent - scale, class, bits);
             end, index);
    end,

    method bellerophon
        (f :: <extended-integer>,
         e :: <integer>,
         class :: subclass(<float>),
         bits :: <integer>)
     => (result :: <float>);
      if (zero?(f))
        make-float(class, #e0, 0);
      else
        algorithm-M(f, e, class, bits);
      end;
    end,

    // Implements Algorithm M from William Clinger's "How to Read Floating-
    // Point Numbers Accurately" in the 1990 ACM PLDI conference proceedings.
    //
    // ### Algorithm Bellerophon is much faster, need to implement it
    //
    method algorithm-M
        (f :: <extended-integer>,
         e :: <integer>,
         class :: subclass(<float>),
         bits :: <integer>)
     => (result :: <float>);
      let low = ash(#e1, bits - 1) - 1;
      let high = ash(#e1, bits) - 1;
      local
        method loop
            (u :: <extended-integer>, v :: <extended-integer>, k :: <integer>)
         => (result :: <float>);
          let x = floor/(u, v);
          if (low <= x & x < high)
            ratio-to-float(class, u, v, k);
          elseif (x < low)
            loop(u * 2, v, k - 1);
          else // x <= high
            loop(u, v * 2, k + 1);
          end if;
        end;
      if (negative?(e))
        loop(f, #e10 ^ -e, 0);
      else
        loop(f * #e10 ^ e, #e1, 0);
      end;
    end,
    method ratio-to-float
        (class :: subclass(<float>),
         u :: <extended-integer>, v :: <extended-integer>, k :: <integer>)
     => (result :: <float>);
      let (q, r) = floor/(u, v);
      let v-r = v - r;
      if (r < v-r)
        make-float(class, q, k);
      elseif (r > v-r)
        make-float(class, q + 1, k);
      elseif (even?(q))
        make-float(class, q, k);
      else
        make-float(class, q + 1, k);
      end if;
    end,
    method make-float
        (class :: subclass(<float>), q :: <extended-integer>, k :: <integer>)
     => (result :: <float>);
      scale-float(as(class, q), k);
    end method;

  if (_start >= _end)
    error("unrecognized floating-point number");
  elseif (string[_start] == '-')
    integer-part(_start + 1, #t, #e0);
  elseif (string[_start] == '+')
    integer-part(_start + 1, #f, #e0);
  else
    integer-part(_start, #f, #e0);
  end if;
end method;

