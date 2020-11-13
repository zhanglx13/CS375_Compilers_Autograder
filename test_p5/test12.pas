{ unit test 12 A[constant].B }

program graph1(output);
type complex = record re, im: real end;
     color = (red, white, blue);
     pp = ^ person;
     person = record age:      integer;
                     friend:   pp;
                     location: complex;
                     favorite: color;
                     salary:   real end;
var ac: array[1..10] of complex;
    people: array[1..20] of person;
begin
   ac[3].re := 3.4;
   ac[5].im := 4.5;
   people[13].age := 19;
   people[15].salary := 100.0
end.
