// - Create bank entry
// - Open Bank journal
// - Open that entry
// - Change it's amount
// - Save and close entry
// - Check if amount has changed in the list

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "260D636E" );
env = getEnv ( id );
createEnv ( env );

// Open Bank
Commando ( "e1cib/list/InformationRegister.Bank" );
list = With ( "Bank" );

// Open Entry
Click ( "#FormChange" );

// Change amount then Save&Close
With ( "Entry #*" );
amount = 1 + Fetch ( "#RecordAmount" );
Set ( "#RecordAmount", amount );
Click ( "#FormWrite" );
Close ();

// Check if new amount comes to the Bank journal
With ( list );
listAmount = Fetch ( "#Received", Get ( "#List" ) );
if ( Find ( listAmount, amount ) = 0 ) then
	Stop ( "Amount in the list is incorrect. Actual amount should be: " + amount );
endif;

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
