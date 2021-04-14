{ unit test 02 symbol table instrec}

program graph1(output);
type complex = record re, im: real end;
     pp = ^ person;
     person = record age:      integer;
                     friend:   pp;
                     location: complex;
                     salary:   real end;
    complexX = record re, im, dummy: real end;
    personX = record age          : integer;
                     friend       : pp;
                     location     : complexX;
                     salary       : real;
                     height       : integer;
                     weight       : integer;
                     birthMonth   : integer  end;
var c, d                  : complex;
    i                     : integer;
    john, mary, fred, ptr : pp;
    you, he, she, me      : person;
begin
   i := 1
end.
