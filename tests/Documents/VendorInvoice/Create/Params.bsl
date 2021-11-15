StandardProcessing = false;

p = new Structure ();
p.Insert ( "Date" );
p.Insert ( "Employee" );
p.Insert ( "Warehouse" );
p.Insert ( "Currency", __.LocalCurrency );
p.Insert ( "Rate", 1 );
p.Insert ( "Factor", 1 );
p.Insert ( "Terms" );
p.Insert ( "Expenses" );
p.Insert ( "ID" );
p.Insert ( "TaxGroup" );
p.Insert ( "Vendor" );
p.Insert ( "Items", new Array () );
p.Insert ( "Services", new Array () );
p.Insert ( "FixedAssets", new Array () );
p.Insert ( "IntangibleAssets", new Array () );
p.Insert ( "Accounts", new Array () );
p.Insert ( "ProducerPrice" );

return p;
