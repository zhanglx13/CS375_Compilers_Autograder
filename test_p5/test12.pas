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
    acX: array[2..6] of complex;
    people: array[1..20] of person;
    peopleX: array[2..16] of person;
begin
   ac[5].im := 4.5;
   people[15].salary := 100.0;
   acX[7].im := 5.4;
   peopleX[13].salary := 1234.0
end.
