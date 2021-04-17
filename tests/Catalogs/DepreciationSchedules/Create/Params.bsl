StandardProcessing = false;

p = new Structure ();
p.Insert ( "Description" );
for i = 1 to 12 do
	p.Insert ( "Rate" + i, 0 );
enddo;
return p;
