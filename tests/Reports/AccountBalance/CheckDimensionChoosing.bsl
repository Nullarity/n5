Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );
checkContractSelection ( env );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "618657577#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "CustomerAccount", "11000" );
	p.Insert ( "Customer", "_Customer: " + id );
	p.Insert ( "Contract", "General" );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );

	RegisterEnvironment ( id );

EndProcedure

Procedure checkContractSelection ( Env )

	OpenMenu ( "Accounting / Account Balance" );
	With ( "Account Balance*" );

	settings = Get ( "#UserSettings" );

	if ( not settings.CurrentVisible () ) then
		Click ( "#CmdOpenSettings" );
	endif;

	// Set Account
	GotoRow ( "#UserSettings", "Setting", "Account" );
	Set ( "#UserSettingsValue", Env.CustomerAccount, settings );
	
	// Set Customer
	GotoRow ( "#UserSettings", "Setting", "Organizations" );
	Set ( "#UserSettingsValue", Env.Customer, settings );
	
	// Select Contract
	GotoRow ( "#UserSettings", "Setting", "Contracts" );
	Choose ( "#UserSettingsValue", settings );
	
	// Goto contract
	With ( "Contracts" );
	table = Get ( "#List" );
	GotoRow ( table, "Description", "General" );
	
	// No more contracts should be
	Click ( "#FormOutputList" );
	With ( "Export list" );
	Click ( "#Ok" );
	With ( "List" );
	CheckTemplate ( "" );
	
EndProcedure
