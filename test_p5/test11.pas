{ unit test 11 a^.b^.c }

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
   john^.friend^.age := 23;
   john^.friend^.salary := 1200.0;
   john^.friend^.location.im := 5.4;
   john^.friend^.friend^.location.re := 97
end.
