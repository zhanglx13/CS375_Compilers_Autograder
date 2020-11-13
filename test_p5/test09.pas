{ unit test 09 a^.b }

program graph1(output);
type complex = record re, im: real end;
     color = (red, white, blue);
     pp = ^ person;
     person = record age:      integer;
                     friend:   pp;
                     location: complex;
                     favorite: color;
                     salary:   real end;
var c: complex; sum: integer;
    john, mary, fred, ptr: pp;
begin
   john^.favorite := blue;
   john^.age := 19;
   john^.friend := mary;
   john^.salary := 40000.0;
   fred^.friend := nil;
   mary^.location := c;
   sum := sum + ptr^.age;
   ptr := ptr^.friend
end.
