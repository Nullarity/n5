// Create Account
// Create Entry
// Open Transactions by that account
// Select areas in different ways
// Check results

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "286F6A0B" );
env = getEnv ( id );
createEnv ( env );

// Open report
Commando ( "e1cib/app/Report.Transactions" );
With ( "Transactions*" );

// Hide User Settings
if ( Get ( "#UserSettings" ).CurrentVisible () ) then
	Click ( "#CmdOpenSettings" );
endif;

// Set filters
period = "#_0";
Clear ( period );
account = "#_1";
Put ( account, Env.Account );
Click ( "#GenerateReport" );

// Select & check area #1
tabDoc = Get ( "#Result" );
tabDoc.SetCurrentArea ( "R7C7:R12C11" ); // See Amounts on Template tab
Pause ( 1 );
Check ( "#TotalInfo", "Avg: 333.19   Count: 4   Sum: 999.57" );

// Select & check area #2
tabDoc.SetCurrentArea ( "R7C10:R12C13" );
Pause ( 1 );
Check ( "#TotalInfo", "Avg: -667.03   Count: 5   Sum: -2,001.09" );

// Select & check area #3
tabDoc.SetCurrentArea ( "R6" );
Pause ( 1 );
Check ( "#TotalInfo", "Avg: 0   Count: 2   Sum: 0" );

// Select & check area #4
tabDoc.SetCurrentArea ( "R6C12:R13C13" );
Pause ( 1 );
Check ( "#TotalInfo", "Avg: -1,375.6275   Count: 7   Sum: -5,502.51" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Account", Right ( ID, 6 ) );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Account
	// *************************
	
	p = Call ( "ChartsOfAccounts.General.Create.Params" );
	account = Env.Account;
	p.Code = account;
	p.Description = account;
	Call ( "ChartsOfAccounts.General.Create", p );

	// *************************
	// Create Entry
	// *************************
	p = Call ( "Documents.Entry.Create.Params" );
	records = p.Records;
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = "0";
	row.AccountCr = account;
	row.Amount = 1500.33;
	records.Add ( row );
	
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = account;
	row.AccountCr = "0";
	row.Amount = -500.76;
	records.Add ( row );
	Call ( "Documents.Entry.Create", p );

	RegisterEnvironment ( id );

EndProcedure
