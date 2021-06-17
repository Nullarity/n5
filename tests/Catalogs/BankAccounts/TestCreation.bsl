Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );
createBankAccount ( env );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "272AF853#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "AccountNumber", "1234567890" );
	p.Insert ( "Bank", "_Bank: " + id );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Bank
	// *************************
	
	p = Call ( "Catalogs.Banks.Create.Params" );
	p.Description = Env.Bank;
	p.Code = id;
	Call ( "Catalogs.Banks.Create", p );

	Call ( "Common.StampData", id );

EndProcedure

Procedure createBankAccount ( Env )

	Commando("e1cib/list/Catalog.Companies");
	With ( "Companies" );

	GotoRow ( "#List", "Description", __.Company );
	Click ( "#FormChange" );
	With ( __.Company + " *" );
	Click ( "Bank Accounts", GetLinks () );
	With ( "Bank Accounts" );

	Click ( "#FormCreate" );
	With ( "Bank Accounts (cre*" );

	Check ( "#Owner", __.Company );
	Check ( "#Currency", __.LocalCurrency );
	
	Set ( "#Bank", Env.Bank );
	Set ( "#AccountNumber", Env.AccountNumber );
	Next ();
	
	Check ( "#Description", Env.Bank + ", " + Env.AccountNumber );
	
	Click ( "#FormWriteAndClose" );
	
EndProcedure
