// Create a new Customer
// Create a new Payment
// Fill Payment and post
// Check records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0TM" );
env = getEnv ( id );
createEnv ( env );

// Create a new Payment
Commando ( "e1cib/data/Document.Payment" );
With ( "Customer Payment (cre*" );
Set ( "#Customer", env.Customer );
Set ( "#Amount", "100" );
Put ( "#AdvanceAccount", "11000" );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: *" );

CheckTemplate ( "#TabDoc" );

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
