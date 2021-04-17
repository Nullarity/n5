// Test filling Return from filters in list form:
// - Open List Form
// - Set Filters
// - Create Return
// - Check Attributes

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6AAF5A" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Open List Form
// *************************

Commando("e1cib/list/Document.Return");

// *************************
// Set Filters
// *************************

With ( "Returns from Customers" );
Put ( "#CustomerFilter", Env.Customer );
Put ( "#WarehouseFilter", Env.Warehouse );

// *************************
// Create Return
// *************************

Click ( "#FormCreate" );

// *************************
// Check Attributes
// *************************

With ( "Return from Customer (cr*" );
Check ( "#Customer", Env.Customer );
Check ( "#Warehouse", Env.Warehouse );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
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
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
		
	RegisterEnvironment ( id );
	
EndProcedure
