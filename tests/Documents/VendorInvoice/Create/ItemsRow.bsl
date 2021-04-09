StandardProcessing = false;

p = new Structure ();
p.Insert ( "Item" );
p.Insert ( "Quantity" );
p.Insert ( "Price" );
p.Insert ( "Account" ); // can be empty
if ( AppName = "Cont5" ) then
	p.Insert ( "Social", false );
	p.Insert ( "ProducerPrice", 0 );
endif;


return p;

