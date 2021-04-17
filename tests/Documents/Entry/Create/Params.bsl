StandardProcessing = false;

p = new Structure ();
p.Insert ( "Date", CurrentDate () );
p.Insert ( "Records", new Array () ); // Array of Documents.Entry.Create.Row
p.Insert ( "Company", "ABC Distributions" );
return p;
