// Create credit entry for active account
// Generate report and check totals

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "26ABEC41" );
env = getEnv ( id );
createEnv ( env );

// Generate report and check totals
p = Call ( "Common.Report.Params" );
p.Path = "Accounting / Account Balance";
p.Title = "Account Balance*";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Name = "Account";
item.Value = env.Account;
filters.Add ( item );

p.Filters = filters;
With ( Call ( "Common.Report", p ) );

CheckTemplate ( "#Result" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Account", Right ( ID, 7 ) );
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
	p.Description = Env.ID;
	p.Type = "Active";
	Call ( "ChartsOfAccounts.General.Create", p );

	// ***********************************
	// Create Entry
	// ***********************************

	p = Call ( "Documents.Entry.Create.Params" );
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = "0";
	row.AccountCr = account;
	row.Amount = 100;
	p.Records.Add ( row );
	Call ( "Documents.Entry.Create", p );

	RegisterEnvironment ( id );

EndProcedure
