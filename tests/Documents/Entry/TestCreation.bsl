Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A04S" );
env = getEnv ( id );
createEnv ( env );
createEntry ( env );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "LocalBankAccount", "local " + ID );
	p.Insert ( "CADBankAccount", "cad " + ID );
	p.Insert ( "Customer", "_Customer: " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Bank Accounts
	// *************************
	
	p = Call ( "Catalogs.BankAccounts.Create.Params" );
	p.Description = "_Bank: " + id;
	p.Company = __.Company;
	p.Currency = __.LocalCurrency;
	p.Description = Env.LocalBankAccount;
	Call ( "Catalogs.BankAccounts.Create", p );

	p.Currency = "CAD";
	p.Description = Env.CADBankAccount;
	Call ( "Catalogs.BankAccounts.Create", p );

	// *************************
	// Create Customer
	// *************************
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	p.Insert ( "Currency", __.LocalCurrency );
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	RegisterEnvironment ( id );

EndProcedure

Procedure createEntry ( Env )

	Commando ( "e1cib/data/Document.Entry" );
	form = With ( "Entry (cr*" );
	Click ( "#RecordsAdd" );
	With ( "Record" );
	Put ( "#AccountDr", "2431" );
	Put ( "#DimDr1", Env.CADBankAccount );
	Put ( "#AccountCr", "2431" );
	Put ( "#DimCr1", Env.LocalBankAccount );
	
	checkRecord ( Env );
	
	Click ( "#FormOK" );
	With ( form );
	Click ( "#RecordsEdit" );

	With ( "Record" );
	checkRecord ( Env );
	
	// Change to foreign currency and check accessibility
	Put ( "#CurrencyCr", "CAD" );
	CheckState ( "#CurrencyAmountCr, #RateCr, #FactorCr", "Enable" );

	// Change to non-currency account and check accessibility
	Put ( "#AccountCr", "0" );
	CheckState ( "#CurrencyCr, #CurrencyAmountCr, #RateCr, #FactorCr", "Enable", false );

	// Set back credit account and test reverse-calculation (Amount -> CurrencyCrAmount)
	Put ( "#AccountCr", "2431" );
	Put ( "#DimCr1", Env.LocalBankAccount );
	
	Set ( "#Amount", "500" );
	Next ();
	Check ( "#CurrencyAmountCr", "500" );
	
	// Set curreency amount and check calculations
	Put ( "#RateDr", "0.8000" );
	Set ( "#CurrencyAmountDr", "500" );
	Next ();
	Check ( "#CurrencyAmountCr", "400" );
	Check ( "#Amount", "400" );
	
	// Check Contractors
	Put ( "#AccountDr", "2212" );
	Put ( "#DimDr1", Env.Customer );
	Check ( "#DimDr2", "General" );
	Check ( "#CurrencyDr", __.LocalCurrency );

EndProcedure

Procedure checkRecord ( Env )

	Check ( "#CurrencyDr", "CAD" );
	CheckState ( "#CurrencyDr, #CurrencyAmountDr, #RateDr, #FactorDr, #CurrencyAmountDr", "Enable" );

	Check ( "#CurrencyCr", __.LocalCurrency );
	CheckState ( "#CurrencyCr", "Enable" );
	CheckState ( "#CurrencyAmountCr, #RateCr, #FactorCr, #CurrencyAmountCr", "Enable", false );

	Check ( "#AccountDr", "2431" );
	Check ( "#DimDr1", Env.CADBankAccount );
	Check ( "#AccountCr", "2431" );
	Check ( "#DimCr1", Env.LocalBankAccount );

EndProcedure
