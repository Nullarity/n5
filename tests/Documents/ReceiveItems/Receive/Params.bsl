StandardProcessing = false;

p = new Structure ();
p.Insert ( "Date" );
p.Insert ( "Warehouse" );
p.Insert ( "Account" );
p.Insert ( "Expenses" );

p.Insert ( "Items", new Array () );
p.Insert ( "IntangibleAssets", new Array () );

return p;