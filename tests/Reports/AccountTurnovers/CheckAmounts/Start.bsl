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
	if ( Call ( "Common.AppIsCont" ) ) then
		p.Insert ( "Account", "2171" );
		p.Insert ( "BalancedAccount", "7141" );
	else
		p.Insert ( "Account", "10102" );
		p.Insert ( "BalancedAccount", "8111" );
	endif;
	
	// *******************
	// Expenses
	// *******************
	
	expenses = new Array ();
	expenses.Add ( "_Expense1: " + ID );
	expenses.Add ( "_Expense2: " + ID );
	p.Insert ( "Expenses", expenses );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
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
	Set ( "#UserSettingsValue", Env.BalancedAccount, settings );
	
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
