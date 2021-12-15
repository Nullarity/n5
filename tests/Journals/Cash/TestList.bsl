// Scenario:
// - Create Customer Payment
// - Open Journal
// - Filter by Currency & Location
// - Open created Customer Payment

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25BCBCB9" );
env = getEnv ( id );
createEnv ( env );

// ************
// Open Journal
// ************

Commando ( "e1cib/list/DocumentJournal.Cash" );
With ( "Petty Cash" );

// Check filters
Set ( "#CurrencyFilter", __.LocalCurrency );
Put ( "#LocationFilter", env.Location );
Next ();

// Check selection
Activate ( "#List" );
Click ( "#FormChange" );
With ( "Customer Payment *" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Location", "Location " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// ***************
	// Create Customer
	// ***************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );

	// ***************
	// Create Location
	// ***************
	
	Call ( "Catalogs.PaymentLocations.Create", Env.Location );

	// ***********************
	// Create Customer Payment
	// ***********************

	Commando ( "e1cib/command/Document.Payment.Create" );
	form = With ( "Customer Payment (cr*" );

	Put ( "#Customer", env.Customer );
	Pick ( "#Method", "Cash" );
	Pick ( "#Location", Env.Location );
	Set ( "#Amount", "300" );
	Click ( "#NewReceipt" );

	With ( "Cash Receipt" );
	Set ( "#Reason", "Reason" );
	Set ( "#Reference", "Reference" );
	Click ( "#FormOK" );
	With ( form );
	Click ( "#FormWrite" );
	Close ();
	
	RegisterEnvironment ( id );

EndProcedure
