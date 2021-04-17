StandardProcessing = false;

p = new Structure ();
p.Insert ( "Date" );
p.Insert ( "Warehouse" );
p.Insert ( "Account" );
p.Insert ( "Expenses" );
p.Insert ( "ID" );
p.Insert ( "Post", false );

p.Insert ( "Items", new Array () );
p.Insert ( "FixedAssets", new Array () );
p.Insert ( "IntangibleAssets", new Array () );

return p;