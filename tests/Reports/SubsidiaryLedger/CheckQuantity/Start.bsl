Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );
checkTwoPeriods ( env );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "286FB90B#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Account", "2171" );
	p.Insert ( "BalancedAccount", "8111" );
	p.Insert ( "Date", Date ( 2018, 1, 1 ) );
	p.Insert ( "Warehouse", "Main" );
	p.Insert ( "Expenses", "_Expense1: " + id );
	
	// *******************
	// Items
	// *******************
	
	items = new Array ();
	items.Add ( "_Item1: " + id );
	items.Add ( "_Item2: " + id );
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
	p.Date = Env.Date;
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


	Click ( "#GenerateReport" );
	Run ( "NextYear" );

EndProcedure
