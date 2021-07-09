// Create a new Opening Balance
// Set currency account
// Check calculations
// Post the document

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2815F1E1" );
env = getEnv ( id );
createEnv ( env );

// Create document
Commando ( "e1cib/list/DocumentJournal.Balances" );
With ( "Opening Balances" );
Click ( "#FormCreateByParameterBalances" );
With ( "Opening Balances (cr*" );

Put ( "#Account", env.Account );
Put ( "#AccountCurrency", "CAD" );
Check ( "#AccountRate", 0.8 );
Set ( "#AccountCurrencyAmount", 100 );
Next ();
Check ( "#AccountAmount", 80 );
Set ( "#AccountAmount", 99 );

Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records:*" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer: " + ID );
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
	p.Code = Env.Account;
	p.Description = Env.ID;
	p.Type = "Active";
	p.Currency = true;
	Call ( "ChartsOfAccounts.General.Create", p );

	RegisterEnvironment ( id );

EndProcedure
