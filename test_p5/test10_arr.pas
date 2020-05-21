{ pasrec.pas      program to test record operations      06 Aug 09 }

program graph1(output);
label 1492, 1776;
type complex = record er, mi: real end;
     color = (red, white, blue);
     pp = ^ person;
     person = record age:      integer;
                     friend:   pp;
                     favorite: color;
                     salary:   real end;
var c,d: complex; i, sum: integer;
    ac: array[1..10] of complex;
    aco: array[1..10, color] of color;
    john, mary, fred, ptr: pp;
    people: array[1..20] of person;
begin
   people[i].salary := ptr^.salary
end.
