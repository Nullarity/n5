Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "286F6062" );

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
		p.Insert ( "Account", "12100" );
		p.Insert ( "BalancedAccount", "8111" );
	endif;	
	p.Insert ( "Warehouse", "Main" );
	p.Insert ( "Expenses", "_Expense1: " + ID );
	
	// *******************
	// Items
	// *******************
	
	items = new Array ();
	items.Add ( "_Item1: " + ID );
	items.Add ( "_Item2: " + ID );
	p.Insert ( "Items", items );
	
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
	
	Call ( "Catalogs.Expenses.Create", Env.Expenses );

	// *************************
	// Create Items
	// *************************
	params = Call ( "Catalogs.Items.Create.Params" );
	for each item in Env.Items do
		params.Description = item;
		Call ( "Catalogs.Items.Create", params );
	enddo;

	// *************************
	// Create Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	records = p.Records;
	expense = Env.Expenses;
	for each item in Env.Items do
		row = Call ( "Documents.Entry.Create.Row" );
		row.AccountDr = Env.BalancedAccount;
		row.DimDr1 = expense;
		row.QuantityCr = "7";
		row.AccountCr = Env.Account;
		row.DimCr1 = item;
		row.Amount = "2000";
		records.Add ( row );
	enddo;
	Call ( "Documents.Entry.Create", p );

	RegisterEnvironment ( id );

EndProcedure

Procedure checkTwoPeriods ( Env )

	OpenMenu ( "Accounting / Account Turnovers" );
	form = With ( "Account Turnovers*" );

	// ***********
	// Set filters
	// ***********

	settings = Get ( "#UserSettings" );
	if ( not settings.CurrentVisible () ) then
		Click ( "#CmdOpenSettings" );
	endif;
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
	
	GotoRow ( "#UserSettings", "Setting", "Items" );
	Pick ( "#UserSettingsComparisonType", "In List", settings );
	Choose ( "#UserSettingsValue", settings );
	
	for each item in Env.Items do
		With ( "Value list" );
		Click ( "#Add" );
		
		Choose ( "#Value" );
		With ( "Select data type" );
		GotoRow ( "#TypeTree", "", "Items" );
		Click ( "#OK" );
		With ( "Items" );
		GotoRow ( "#List", "Description", item );
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
