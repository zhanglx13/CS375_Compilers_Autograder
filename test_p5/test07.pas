{ unit test 07 new function}

program graph1(output);
type complex = record re, im: real end;
     color = (red, white, blue);
     pp = ^ person;
     ppX = ^ personX;
     person = record age       : integer;
                     friend    : pp;
                     location  : complex;
                     favorite  : color end;
     personX = record age      : integer;
                      friend   : pp;
                      location : complex;
                      favorite : color;
                      height   : real;
                      weight   : real end;
var joh, mry : pp;
    frd,trx  : ppX;
begin
   new(joh);
   new(mry);
   new(frd);
   new(trx)
end.
