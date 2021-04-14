{ unit test 15 A[var const] }

program graph1(output);
type color = (red, white, blue);
var i, j: integer;
    aco: array[1..10, color] of color;
    acoX: array[2..6, color] of color;
begin
   aco[i,white] := blue;
   aco[j,blue] := red;
   acoX[j,white] := blue;
   acoX[i,blue] := red
end.
