StandardProcessing = false;

p = new Structure ();
p.Insert ( "Date", CurrentDate () );
p.Insert ( "Employees", new Array () ); // Array of Documents.Hiring.Create.Row
p.Insert ( "Memo", "" );
p.Insert ( "Company" );
return p;