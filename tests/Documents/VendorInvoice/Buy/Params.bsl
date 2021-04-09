StandardProcessing = false;

p = new Structure ();
p.Insert ( "Date" );
p.Insert ( "Vendor" );
p.Insert ( "Warehouse" );
p.Insert ( "Currency", __.LocalCurrency );
p.Insert ( "Rate", 1 );
p.Insert ( "Factor", 1 );
p.Insert ( "ContractCurrency", __.LocalCurrency );
p.Insert ( "ContractRate", 1 );
p.Insert ( "ContractFactor", 1 );
p.Insert ( "Terms" );
p.Insert ( "Expenses" );
p.Insert ( "Import", false );
p.Insert ( "ID" );

p.Insert ( "Items", new Array () );
p.Insert ( "Services", new Array () );

p.Insert ( "ServicesIntoItems", false );
p.Insert ( "ServicesIntoDocument" );
p.Insert ( "DateBeforeVendor", true );

return p;
