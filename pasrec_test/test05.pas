program graph1(output);
label 1492, 1776;
type complex = record re, im: real end;
                  color = (red, white, blue);
                  pp = ^ person;
                  person = record age:      integer;
                              friend:   pp;
                              location: complex;
                              favorite: color;
                              salary:   real end;
var c,d: complex; i, sum: integer;
   ac: array[1..10] of complex;
   aco: array[1..10, color] of color;
   john, mary, fred, ptr: pp;
   people: array[1..20] of person;
begin
   john^.friend := mary
end.
