// - Open Bank journal
// - Create, save & close Entry
// - Check if current row gets focus correctly

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
Set ( "#Content", memoID );
Click ( "#FormWrite" );
Close ();

// Check current row
With ( list );
Check ( "Memo", memoID, Get ( "#List" ) );

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