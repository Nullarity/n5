// Test filling Refund from filters in list form:
// - Open List Form
// - Set Filters
// - Create Refund
// - Check Attributes

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6AAF3D" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Open List Form
// *************************

Commando("e1cib/list/Document.Refund");

// *************************
// Set Filters
// *************************

With ( "Refunds to Customers" );
Put ( "#CustomerFilter", Env.Customer );

// *************************
// Create Refund
// *************************

Click ( "#FormCreate" );

// *************************
// Check Attributes
// *************************

With ( "Refund to Customer (cr*" );
Check ( "#Customer", Env.Customer );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
		
	RegisterEnvironment ( id );
	
EndProcedure