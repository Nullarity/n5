// - Create bank entry
// - Open Bank journal
// - Post and Unpost that entry

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2609CEC5" );
env = getEnv ( id );
createEnv ( env );

// Open Bank
Commando ( "e1cib/list/InformationRegister.Bank" );
list = With ( "Bank" );

 // Post Entry
Click ( "#ListContextMenuPost" );
Click ( "#ListContextMenuUndoPosting" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Operation", "Operation: " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Operation Type
	// *************************
	
	p = Call ( "Catalogs.Operations.Create.Params" );
	p.Operation = "Bank Receipt";
	p.Description = Env.Operation;
	p.Simple = true;
	Call ( "Catalogs.Operations.Create", p );
	
	// *************************
	// Create Entry
	// *************************
	
	Commando ( "e1cib/command/Document.Entry.Create" );
	With ( "Entry (cr*" );
	Put ( "#Operation", Env.Operation );
	Put ( "#AccountDr", "0" );
	Put ( "#AccountCr", "0" );
	Set ( "#RecordAmount", 300 );
	Click ( "#FormWrite" );
	Close ();

	RegisterEnvironment ( id );

EndProcedure
