// Test filling Return from filters in list form:
// - Open List Form
// - Set Filters
// - Create Return
// - Check Attributes

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B8D1774" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Open List Form
// *************************

Commando("e1cib/list/Document.VendorReturn");

// *************************
// Set Filters
// *************************

With ( "Returns to Vendors" );
Put ( "#VendorFilter", Env.Vendor );
Put ( "#WarehouseFilter", Env.Warehouse );

// *************************
// Create Return
// *************************

Click ( "#FormCreate" );

// *************************
// Check Attributes
// *************************

With ( "Return to Vendor (cr*" );
Check ( "#Vendor", Env.Vendor );
Check ( "#Warehouse", Env.Warehouse );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
		
	RegisterEnvironment ( id );
	
EndProcedure