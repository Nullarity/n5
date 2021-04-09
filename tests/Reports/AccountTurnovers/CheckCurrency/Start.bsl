Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "286F5F9F" );

env = getEnv ( id );
createEnv ( env );
checkTwoPeriods ( env );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	isCont = Call ( "Common.AppIsCont" );
	p.Insert ( "IsCont", isCont );
	if ( isCont ) then
	    p.Insert ( "Account", "2432" );
		p.Insert ( "BalancedAccount", "0" );
		p.Insert ( "CashFlow", "_CashFlow " + ID );
	else
		p.Insert ( "Account", "10102" );
		p.Insert ( "BalancedAccount", "0000" );
	endif;	
	p.Insert ( "BankAccount", "_Bank account: " + ID );
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
	isCont = Env.IsCont;
	if ( isCont ) then
		// *************************
		// Create Cash Flows
		// *************************
		
		Call ( "Catalogs.CashFlow.Create", Env.CashFlow );
	endif;
	
	// *************************
	// Create Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	records = p.Records;
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = Env.Account;
	if ( isCont ) then
		row.DimDr1 = Env.CashFlow;
		row.DimDr2 = Env.BankAccount;
	else
	    row.DimDr1 = Env.BankAccount;
	endif;
	row.AccountCr = Env.BalancedAccount;
	row.CurrencyAmountDr = "1000";
	row.Amount = "10000";
	records.Add ( row );
	Call ( "Documents.Entry.Create", p );

	Call ( "Common.StampData", id );

EndProcedure

Procedure checkTwoPeriods ( Env )

	OpenMenu ( "Accounting / Account Turnovers" );
	form = With ( "Account Turnovers*" );

	// ***********
	// Set filters
	// ***********

	settings = Get ( "#UserSettings" );
	
	GotoRow ( "#UserSettings", "Setting", "Period" );
	Choose ( "#UserSettingsValue", settings );
	With ( "Select period" );
	Click ( "#YearVariant" );
	GotoRow ( "#PeriodVariantTable", "Value", "This year" );
	Click ( "#Select" );
	With ( form );

	if ( not settings.CurrentVisible () ) then
		Click ( "#CmdOpenSettings" );
	endif;
	
	GotoRow ( "#UserSettings", "Setting", "Account" );
	Put ( "#UserSettingsValue", Env.Account, settings );
	isCont = Env.IsCont;
	if ( isCont ) then
		GotoRow ( "#UserSettings", "Setting", "Cash Flows" );
		Put ( "#UserSettingsValue", Env.CashFlow, settings );
		
		GotoRow ( "#UserSettings", "Setting", "Show Analytics" );
		Put ( "#UserSettingsValue", "1, 2 level", settings );
	endif;
	
	GotoRow ( "#UserSettings", "Setting", "Bank Accounts" );
	Put ( "#UserSettingsValue", Env.BankAccount, settings );
	
	Click ( "#GenerateReport" );
	if ( isCont ) then
		Run ( "ThisYearCont" );
	else
		Run ( "ThisYear" );
	endif;	
	
	// *********************************************
	// Move period forward and check initial balance
	// *********************************************

	if ( isCont ) then
		GotoRow ( "#UserSettings", "Setting", "Cash Flows" );
		Click ( "#UserSettingsUse" );
	endif;
   
	GotoRow ( "#UserSettings", "Setting", "Period" );
	Choose ( "#UserSettingsValue", settings );
	With ( "Select period" );
	Click ( "#YearVariant" );
	GotoRow ( "#PeriodVariantTable", "Value", "Next year" );
	
	Click ( "#Select" );
	With ( form );
	Click ( "#GenerateReport" );
	if ( isCont ) then
		Run ( "NextYearCont" );
	else
		Run ( "NextYear" );
	endif;

EndProcedure
