// Create a Offbalance Account
// Post the document

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "272B0F0B" );
env = getEnv ( id );
createEnv ( env );

// Create document
Commando ( "e1cib/list/DocumentJournal.Balances" );
With ( "Opening Balances" );
Click ( "#FormCreateByParameterBalances" );
With ( "Opening Balances (cr*" );

Put ( "#Account", env.Account );
Set ( "#AccountAmount", "100" );
Click ( "#FormPost" );

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
	p.Code = Env.Account;
	p.Description = Env.ID;
	p.Type = "Active";
	p.Offbalance = true;
	Call ( "ChartsOfAccounts.General.Create", p );

	RegisterEnvironment ( id );

EndProcedure

