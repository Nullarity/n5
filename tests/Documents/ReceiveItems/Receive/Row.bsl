StandardProcessing = false;

p = new Structure ();
p.Insert ( "Item" );
p.Insert ( "Quantity" );
p.Insert ( "Price" );
p.Insert ( "CountPackages", false );
p.Insert ( "Account" ); // can be empty
p.Insert ( "UseItemsQuantityPkg", false );
return p;