Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );
checkTwoPeriods ( env );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "286FB794#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Account", "10101" );
	p.Insert ( "Date", Date ( 2018, 1, 1 ) );
	p.Insert ( "BalancedAccount", "0000" );
	p.Insert ( "BankAccount", "_Bank account: " + id );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Bank Account
	// *************************
	
	p = Call ( "Catalogs.BankAccounts.Create.Params" );
	p.Description = Env.BankAccount;
	p.Company = __.Company;
	p.Currency = "CAD";
	Call ( "Catalogs.BankAccounts.Create", p );

	// *************************
	// Create Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = Env.Date;
	records = p.Records;
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = Env.Account;
	row.DimDr1 = Env.BankAccount;
	row.AccountCr = Env.BalancedAccount;
	row.CurrencyAmountDr = "1000";
	row.Amount = "800";
	records.Add ( row );
	Call ( "Documents.Entry.Create", p );

	Call ( "Common.StampData", id );

EndProcedure

Procedure checkTwoPeriods ( Env )

	OpenMenu ( "Accounting / Subsidiary Ledger" );
	form = With ( "Subsidiary Ledger*" );

	// ***********
	// Set filters
	// ***********
	
	p = Call ( "Common.Report.Params" );
	filters = new Array ();

	item = Call ( "Common.Report.Filter" );
	item.Period = true;
	item.Name = "Period";
	item.ValueFrom = Date ( 2018, 1, 1 );
	item.ValueTo = Date ( 2018, 1, 31 );
	filters.Add ( item );
	p.Filters = filters;

	Call ( "Common.Report.FillFilters", p );
	
	settings = Get ( "#UserSettings" );

	if ( not settings.CurrentVisible () ) then
		Click ( "#CmdOpenSettings" );
	endif;

	GotoRow ( "#UserSettings", "Setting", "Account" );
	Put ( "#UserSettingsValue", Env.Account, settings );
	
	GotoRow ( "#UserSettings", "Setting", "Bank Accounts" );
	Put ( "#UserSettingsValue", Env.BankAccount, settings );

	Click ( "#GenerateReport" );
	Run ( "ThisYear" );
	
	// *********************************************
	// Move period forward and check initial balance
	// *********************************************
	
	p = Call ( "Common.Report.Params" );
	filters = new Array ();

	item = Call ( "Common.Report.Filter" );
	item.Period = true;
	item.Name = "Period";
	item.ValueFrom = Date ( 2019, 1, 1 );
	item.ValueTo = Date ( 2019, 12, 31 );
	filters.Add ( item );
	p.Filters = filters;

	Call ( "Common.Report.FillFilters", p );

//	GotoRow ( "#UserSettings", "Setting", "Period" );
//	Choose ( "#UserSettingsValue", settings );
//	With ( "Select period" );
//	Click ( "#YearVariant" );
//	GotoRow ( "#PeriodVariantTable", "Value", "Next year" );
//	Click ( "#Select" );
//	With ( form );
	Click ( "#GenerateReport" );
	Run ( "NextYear" );

EndProcedure
