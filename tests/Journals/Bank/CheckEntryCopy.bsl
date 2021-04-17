// - Open Bank journal
// - Create, save & close Entry
// - Copy entry and check memo field

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "286D0C01" );
env = getEnv ( id );
createEnv ( env );

// Open Bank
Commando ( "e1cib/list/InformationRegister.Bank" );
list = With ( "Bank" );

// Create Entry
Click ( "#FormCreateDocument" );
CurrentSource.ExecuteChoiceFromMenu ( env.Operation );
With ( "Entry (cr*" );
memoID = Call ( "Common.GetID" );
Put ( "#AccountDr", "0" );
Set ( "#Content", memoID );
Click ( "#FormWrite" );
Close ();

// Check current row
With ( list );
Click ( "#FormCopy" );
With ( "Entry (cr*" );
Check ( "#Content", memoID );

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Operation", "Bank Expense " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Operation
	// *************************
	
	p = Call ( "Catalogs.Operations.Create.Params" );
	p.Description = Env.Operation;
	p.Operation = "Bank Expense";
	Call ( "Catalogs.Operations.Create", p );
	
	RegisterEnvironment ( id );
	
EndProcedure