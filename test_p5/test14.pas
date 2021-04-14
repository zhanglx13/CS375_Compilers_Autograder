{ unit test 14 A[const, const] }

program graph1(output);
type color = (red, white, blue);
var aco: array[1..10, color] of color;
    acoX: array[2..6, color] of color;
begin
   aco[4,white] := blue;
   aco[2,blue] := red;
   acoX[5,white] := blue;
   acoX[3,blue] := red
end.
