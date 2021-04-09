StandardProcessing = false;

p = new Structure ();
p.Insert ( "Company" ); // Can be empty
p.Insert ( "Description" );
p.Insert ( "Shipments", false );
p.Insert ( "Production", false );
p.Insert ( "Products" ); // Optional. Comma-separated string of production items
if ( AppName = "Cont5" ) then
	p.Insert ( "Division" );
endif; 

return p;
