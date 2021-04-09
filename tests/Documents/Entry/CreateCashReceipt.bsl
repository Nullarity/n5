// Scenario:
// - Create a new Entry
// - Select Operation with Cash Receipt type, simple variant
// - Select Individual
// - Save entry

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28493B5A" );
env = getEnv ( id );
createEnv ( env );

// Create a new Entry
Commando ( "e1cib/data/Document.Entry" );
form = With ( "Entry (cr*" );

// Set Operation
Put ( "#Operation", env.Operation );

// Set Individual
Put ( "#DimCr1", env.Individual );

// Set Location
Put ( "#DimDr1", env.Location );

// Set Currency
Put ( "#CurrencyDr", "CAD" );
Put ( "#CurrencyAmountDr", 100 );

// Post Document
Click ( "#FormPost" );

// Check Cash Receipt
Click ( "#Receipt" );
With ( "Cash Receipt" );
Check ( "#Giver", env.Individual );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Operation", "Operation " + ID );
	p.Insert ( "Individual", "Individual " + ID );
	p.Insert ( "Location", "Location " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Operation
	// *************************

	p = Call ( "Catalogs.Operations.Create.Params" );
	p.Operation = "Cash Receipt";
	p.Description = Env.Operation;
	p.Simple = true;
	p.AccountDr = "10400";
	p.AccountCr = "12800";
	Call ( "Catalogs.Operations.Create", p );
	
	// *************************
	// Create Individual
	// *************************
	
	p = Call ( "Catalogs.Individuals.Create.Params" );
	p.Description = Env.Individual;
	p.IDType = "Passport";
	p.IDIssued = Date ( 2015, 1, 1 );
	p.IDIssuedBy = "Some Office";
	p.IDNumber = "1234567890";
	p.IDSeries = "XL";
	Call ( "Catalogs.Individuals.Create", p );
	
	// ***************
	// Create Location
	// ***************
	
	Call ( "Catalogs.PaymentLocations.Create", Env.Location );

	Call ( "Common.StampData", id );

EndProcedure

Procedure checkFields ()
	
	// Accounts should be readonly
	CheckState ( "#AccountCr", "ReadOnly" );
	CheckState ( "#AccountDr", "ReadOnly" );

	// Check debit dimensions
	Choose ( "#DimCr1" );
	Close ( "Items" );

	// Quantity debit should be enabled
	Set ( "#QuantityCr", 1 );

	// Credit dimension should be disabled
	CheckState ( "#DimDr1", "Enable", false );
	
EndProcedure