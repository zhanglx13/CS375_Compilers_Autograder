{ unit test 13 A[var].B }

program graph1(output);
type complex = record re, im: real end;
     color = (red, white, blue);
     pp = ^ person;
     person = record age:      integer;
                     friend:   pp;
                     location: complex;
                     favorite: color;
                     salary:   real end;
var i, j, k, q: integer;
    ac: array[1..10] of complex;
    acX: array[2..5] of complex;
    people: array[1..20] of person;
    peopleX: array[2..5] of person;
begin
   ac[i].im := 4.5;
   people[j].salary := 100.0;
   acX[k].im := 5.4;
   peopleX[q].salary := 1357.0
end.
