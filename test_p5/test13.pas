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
    people: array[1..20] of person;
begin
   ac[i].re := 3.4;
   ac[j].im := 4.5;
   people[k].age := 19;
   people[q].salary := 100.0
end.
