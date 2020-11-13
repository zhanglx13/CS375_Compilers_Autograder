{ unit test 08  a.b}

program graph1(output);
type complex = record er, mi: real end;
var c,d: complex;
begin
   c.er := 1.0;
   c.mi := 1;
   d.mi := c.mi
end.
