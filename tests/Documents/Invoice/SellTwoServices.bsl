// Create Service
// Create Customer
// Create Invoice and sell that service twice

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "267817BB" );
env = getEnv ( id );
createEnv ( env );

// Create an Invoice
Commando ( "e1cib/data/Document.Invoice" );
With ( "Invoice (cr*" );
Put ( "#Customer", env.Customer );

service = env.Service;
Click ( "#ServicesAdd" );
Put ( "#ServicesItem", service );
Set ( "#ServicesQuantity", 1 );
Set ( "#ServicesPrice", 5 );

Click ( "#ServicesAdd" );
Put ( "#ServicesItem", service );
Set ( "#ServicesQuantity", 1 );
Set ( "#ServicesPrice", 5 );

// Post
Click ( "#FormPost" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Service ", "Service " + ID );
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

	// *************************
	// Create Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );

	RegisterEnvironment ( id );

EndProcedure
