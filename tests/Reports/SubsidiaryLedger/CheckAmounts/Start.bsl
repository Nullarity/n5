Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );
checkTwoPeriods ( env );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "24EB4365#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Account", "10101" );
	p.Insert ( "BalancedAccount", "8111" );
	
	// *******************
	// Expenses
	// *******************
	
	expenses = new Array ();
	expenses.Add ( "_Expense1: " + id );
	expenses.Add ( "_Expense2: " + id );
	p.Insert ( "Expenses", expenses );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Expenses
	// *************************
	
	for each expense in Env.Expenses do
		Call ( "Catalogs.Expenses.Create", expense );
	enddo;

	// *************************
	// Create Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	records = p.Records;
	for each expense in Env.Expenses do
		row = Call ( "Documents.Entry.Create.Row" );
		row.AccountDr = Env.Account;
		row.AccountCr = Env.BalancedAccount;
		row.Amount = "5000";
		row.DimCr1 = expense;
		records.Add ( row );
	enddo;
	Call ( "Documents.Entry.Create", p );

	RegisterEnvironment ( id );

EndProcedure

Procedure checkTwoPeriods ( Env )

	OpenMenu ( "Accounting / Subsidiary Ledger" );
	form = With ( "Subsidiary Ledger*" );

	// ***********
	// Set filters
	// ***********

	settings = Get ( "#UserSettings" );

	if ( not settings.CurrentVisible () ) then
		Click ( "#CmdOpenSettings" );
	endif;

	GotoRow ( "#UserSettings", "Setting", "Account" );
	Put ( "#UserSettingsValue", Env.BalancedAccount, settings );
	
	GotoRow ( "#UserSettings", "Setting", "Expenses" );
	Pick ( "#UserSettingsComparisonType", "In List", settings );
	Choose ( "#UserSettingsValue", settings );
	
	for each expense in Env.Expenses do
		With ( "Value list" );
		Click ( "#Add" );
		
		Choose ( "#Value" );
		With ( "Select data type" );
		GotoRow ( "#TypeTree", "", "Expenses" );
		Click ( "#OK" );
		With ( "Expenses" );
		GotoRow ( "#List", "Description", expense );
		Click ( "#FormChoose" );
		With ( "Value list" );
	enddo;

	Click ( "#OK" );
	With ( form );
	Click ( "#GenerateReport" );
	Run ( "ThisYear" );
	
	// *********************************************
	// Move period forward and check initial balance
	// *********************************************

	GotoRow ( "#UserSettings", "Setting", "Period" );
	Choose ( "#UserSettingsValue", settings );
	With ( "Select period" );
	Click ( "#YearVariant" );
	GotoRow ( "#PeriodVariantTable", "Value", "Next year" );
	Click ( "#Select" );
	With ( form );
	Click ( "#GenerateReport" );
	Run ( "NextYear" );

EndProcedure
