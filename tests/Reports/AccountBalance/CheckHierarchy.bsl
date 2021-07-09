Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );
openReport ( env );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "617709369" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Account", "10100" );
	p.Insert ( "SubordinatedAccount", "10101" );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	records = p.Records;
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = Env.SubordinatedAccount;
	row.AccountCr = "0";
	row.Amount = "6759";
	records.Add ( row );
	Call ( "Documents.Entry.Create", p );

	RegisterEnvironment ( id );

EndProcedure

Procedure openReport ( Env )

	OpenMenu ( "Accounting / Account Balance" );
	With ( "Account Balance*" );

	settings = Get ( "#UserSettings" );

	if ( not settings.CurrentVisible () ) then
		Click ( "#CmdOpenSettings" );
	endif;

	GotoRow ( "#UserSettings", "Setting", "Account" );
	Set ( "#UserSettingsValue", Env.Account, settings );

	Click ( "#GenerateReport" );
	CheckTemplate ( "#Result" );
	
EndProcedure