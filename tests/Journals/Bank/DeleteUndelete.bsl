// - Create bank entry
// - Open Bank journal
// - Delete and Undelete that entry

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "260C24BD" );
env = getEnv ( id );
createEnv ( env );

// Open Bank
Commando ( "e1cib/list/InformationRegister.Bank" );
list = With ( "Bank" );

// Delete
Click ( "#FormDelete" );
if ( App.FindObject ( , "Mark * for deletion" ) = undefined ) then
	Stop ( "Mark for deletion dialog box should be shown" );
endif;
Click ( "Yes", DialogsTitle );

// Undelete
Click ( "#FormDelete" );
if ( App.FindObject ( , "Clear * deletion mark" ) = undefined ) then
	Stop ( "Clear deletion mark dialog box should be shown" );
endif;
Click ( "Yes", DialogsTitle );

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
