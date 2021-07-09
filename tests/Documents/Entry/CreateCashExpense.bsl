// Scenario:
// - Create a new Entry
// - Select Operation with Cash Expense type, simple variant
// - Select Individual
// - Save entry

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28482626" );
env = getEnv ( id );
createEnv ( env );

// Create a new Entry
Commando ( "e1cib/data/Document.Entry" );
form = With ( "Entry (cr*" );

// Set Operation
Put ( "#Operation", env.Operation );

// Set Individual
Put ( "#DimDr1", env.Individual );

// Set Location
Put ( "#DimCr1", env.Location );

// Set Currency
Put ( "#CurrencyCr", "CAD" );
Put ( "#CurrencyAmountCr", 100 );

// Post Document
Click ( "#FormPost" );

// Check Cash Voucher
Click ( "#Voucher" );
With ( "Cash Voucher" );
Check ( "#Receiver", env.Individual );
Check ( "#ID", "Passport: Series Xl, #1234567890, Issued By Some Office, Date 1/1/2015" );

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
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Operation
	// *************************

	p = Call ( "Catalogs.Operations.Create.Params" );
	p.Operation = "Cash Expense";
	p.Description = Env.Operation;
	p.Simple = true;
	p.AccountDr = "12800";
	p.AccountCr = "10400";
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

	RegisterEnvironment ( id );

EndProcedure

Procedure checkFields ()
	
	// Accounts should be readonly
	CheckState ( "#AccountDr", "ReadOnly" );
	CheckState ( "#AccountCr", "ReadOnly" );

	// Check debit dimensions
	Choose ( "#DimDr1" );
	Close ( "Items" );

	// Quantity debit should be enabled
	Set ( "#QuantityDr", 1 );

	// Credit dimension should be disabled
	CheckState ( "#DimCr1", "Enable", false );
	
EndProcedure