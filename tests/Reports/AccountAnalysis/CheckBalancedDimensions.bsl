Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );
openReport ( env );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "618400660" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Account", "10101" );
	p.Insert ( "BalancedAccount", "8111" );
	
	// *******************
	// Expenses
	// *******************
	expenses = new Array ();
	expenses.Add ( "_Expense1: " + id + "#" );
	expenses.Add ( "_Expense2: " + id + "#" );
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

Procedure openReport ( Env )

	OpenMenu ( "Accounting / Account Analysis" );
	With ( "Account Analysis*" );

	settings = Get ( "#UserSettings" );

	if ( not settings.CurrentVisible () ) then
		Click ( "#CmdOpenSettings" );
	endif;

	GotoRow ( "#UserSettings", "Setting", "Account" );
	Set ( "#UserSettingsValue", Env.Account, settings );

	GotoRow ( "#UserSettings", "Setting", "Show Balanced Analytics" );
	Set ( "#UserSettingsValue", "1 level", settings );
	
	Click ( "#GenerateReport" );
	
EndProcedure