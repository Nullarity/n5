StandardProcessing = false;

p = new Structure ();
p.Insert ( "Date" );
p.Insert ( "Department" );
p.Insert ( "Responsible" );
p.Insert ( "Warehouse" ); // Can be empty if services only
p.Insert ( "Currency", __.LocalCurrency );
p.Insert ( "Rate", 1 );
p.Insert ( "Factor", 1 );
p.Insert ( "TaxGroup" ); // Can be empty
p.Insert ( "TaxCode" ); // Can be empty

p.Insert ( "Items", new Array () );
p.Insert ( "Services", new Array () );

return p;

