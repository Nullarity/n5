date = CurrentDate ();
p = new Structure ();
p.Insert ( "Description", "_Bank: " + date );
p.Insert ( "Code", date );
return p;