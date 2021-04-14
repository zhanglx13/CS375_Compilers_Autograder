{ unit test 03 symbol table instarray }

program graph1(output);
type complex = record re, im: real end;
     color = (red, white, blue);
     pp = ^ person;
     person = record age:      integer;
                     friend:   pp;
                     location: complex;
                     favorite: color;
                     salary:   real end;
     complexArr = array[1..10] of complex;
     colorArr2D = array[1..10, color] of color;
     personArr  = array[1..20] of person;
     complexArrX = array[2..6] of complex;
     colorArr2DX = array[2..6, color] of color;
     personArrX  = array[2..16] of person;
var i      : integer;
    ac     : complexArr;
    aco    : colorArr2D;
    people : personArr;
begin
   i := 1
end.
