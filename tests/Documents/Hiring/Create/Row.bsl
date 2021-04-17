StandardProcessing = false;

p = new Structure ();
p.Insert ( "Employee" ); // If it is not found then will be created
p.Insert ( "DateStart" );
p.Insert ( "Duration", 0 ); // Can be empty
p.Insert ( "DateEnd" ); // Can be empty
p.Insert ( "Department" ); // If it is not found then will be created
p.Insert ( "Position" ); // If it is not found then will be created
p.Insert ( "Schedule" ); // Can be empty
p.Insert ( "Rate", 5000 );
p.Insert ( "Compensation" );
p.Insert ( "Expenses" );
p.Insert ( "RowsAdditions", new Array () ); // Documents.Hiring.Create.RowAdditional
p.Insert ( "Put", false );
p.Insert ( "PutAll", true );
return p;
