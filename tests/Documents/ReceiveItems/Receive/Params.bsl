StandardProcessing = false;

p = new Structure ();
p.Insert ( "Date" );
p.Insert ( "Company" );
p.Insert ( "Warehouse" );
p.Insert ( "Account" );
p.Insert ( "Expenses" );
p.Insert ( "Memo" );

p.Insert ( "Items", new Array () );
p.Insert ( "IntangibleAssets", new Array () );

return p;