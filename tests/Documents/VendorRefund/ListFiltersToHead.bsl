// Test filling VendorRefund from filters in list form:
// - Open List Form
// - Set Filters
// - Create VendorRefund
// - Check Attributes

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A2BF9FC" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Open List Form
// *************************

Commando("e1cib/list/Document.VendorRefund");

// *************************
// Set Filters
// *************************

With ( "Refunds from Vendors" );
Set ( "#VendorFilter", Env.Vendor );

// *************************
// Create Refund
// *************************

Click ( "#FormCreate" );

// *************************
// Check Attributes
// *************************

With ( "Refund from Vendor (cr*" );
Check ( "#Vendor", Env.Vendor );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Vendor", "Vendor " + ID );
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
	Call ( "Catalogs.Organizations.CreateVendor", p );
		
	RegisterEnvironment ( id );
	
EndProcedure