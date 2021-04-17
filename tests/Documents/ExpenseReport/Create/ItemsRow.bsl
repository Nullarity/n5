StandardProcessing = false;

p = new Structure ();
p.Insert ( "Item" );
p.Insert ( "Quantity" );
p.Insert ( "Price" );
p.Insert ( "Account" ); // can be empty
p.Insert ( "Date" );
p.Insert ( "Number" );
if ( AppName = "c5" ) then
	p.Insert ( "Social", false );
	p.Insert ( "ProducerPrice", 0 );
endif;

return p;

