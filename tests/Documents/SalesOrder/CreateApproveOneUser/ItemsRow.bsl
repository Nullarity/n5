StandardProcessing = false;

p = new Structure ();
p.Insert ( "Item" );
p.Insert ( "Quantity" );
p.Insert ( "Price" );
p.Insert ( "CountPackages", false );
p.Insert ( "Reservation", "None" );
p.Insert ( "UseQuantity", false );

return p;