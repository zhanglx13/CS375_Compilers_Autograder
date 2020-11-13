{ unit test 10 a^.b.c }

program graph1(output);
type complex = record re, im: real end;
     color = (red, white, blue);
     pp = ^ person;
     person = record age:      integer;
                     friend:   pp;
                     location: complex;
                     favorite: color;
                     salary:   real end;
var john: pp;
begin
   john^.location.re := 3;
   john^.location.im := 4.5
end.
