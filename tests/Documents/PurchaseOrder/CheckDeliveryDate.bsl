// Create Vendor
// Set Delivery Days = 10 days
// Create Purchase Order
// Check if Delivery Date becomes 10 days after current date

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27085991" );
env = getEnv ( id );
createEnv ( env );

// Create Purchase Order
Commando("e1cib/data/Document.PurchaseOrder");
With("Purchase Order (cr*");
Put ("#Vendor", env.Vendor);

// Check if Delivery Date becomes 10 from current date
deliveryDate = BegOfDay ( CurrentDate () + 86400 * env.Delivery );
Check("#DeliveryDate", deliveryDate);

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Delivery", 10 );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	p.Delivery = Env.Delivery;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	RegisterEnvironment ( id );
	
EndProcedure
