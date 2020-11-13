{ unit test 07 new function}

program graph1(output);
type complex = record re, im: real end;
     color = (red, white, blue);
     pp = ^ person;
     person = record age:      integer;
                     friend:   pp;
                     location: complex;
                     favorite: color end;
var joh, mry, frd: pp;
begin
   new(joh);
   new(mry);
   new(frd)
end.
