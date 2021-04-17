Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );
openReport ( env );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "286E490D#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "ReportAccount", "10100" );
	p.Insert ( "Account", "10101" );
	p.Insert ( "BankAccount", "_Internal: " + id );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Bank Account
	// *************************
	p = Call ( "Catalogs.BankAccounts.Create.Params" );
	p.Company = __.Company;
	p.Description = Env.BankAccount;
	Call ( "Catalogs.BankAccounts.Create", p );
	
	// *************************
	// Create Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	records = p.Records;
	row = Call ( "Documents.Entry.Create.Row" );
	account = Env.Account;
	row.AccountDr = account;
	row.AccountCr = account;
	row.Amount = "150";
	bankAccount = Env.BankAccount;
	row.DimDr1 = bankAccount;
	row.DimCr1 = bankAccount;
	records.Add ( row );
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
	Set ( "#UserSettingsValue", Env.ReportAccount, settings );

	GotoRow ( "#UserSettings", "Setting", "Bank Accounts" );
	Set ( "#UserSettingsValue", Env.BankAccount, settings );
	
	Click ( "#GenerateReport" );
	
	CheckTemplate ( "#Result" );
	
EndProcedure