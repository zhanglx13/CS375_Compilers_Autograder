{ unit test 15 A[var const] }

program graph1(output);
type color = (red, white, blue);
var i, j: integer;
    aco: array[1..10, color] of color;
begin
   aco[i,white] := blue;
   aco[j,blue] := red
end.
