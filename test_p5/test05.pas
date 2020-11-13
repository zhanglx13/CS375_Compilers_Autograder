{ unit test 05  label/goto}

program graph1(output);
label 1492, 1776;
var i, sum : integer;
begin
   1492:
        i := 0;
   1776:
        sum := i+1;
   if sum < 3 then goto 1776
end.
