// Description:
// Set filters in Customs Declaration list form and create a new Customs Declaration.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B8A8889" );
env = getEnv ( id );
createEnv ( env );

form = Commando ( "e1cib/list/Document.CustomsDeclaration" );
Put ( "#CustomsFilter", env.Customs );
Click ( "#FormCreate" );
With ( "Customs Declaration (create)" );
Check ( "#Customs", env.Customs );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	env = new Structure ();
	env.Insert ( "ID", ID );
	env.Insert ( "Customs", "Customs: " + ID );
	return env;

EndFunction

Procedure createEnv ( Env )

    id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// ***********************
	// Create Customs
	// ***********************

	Call ( "Catalogs.Organizations.CreateVendor", Env.Customs );
	
	Call ( "Common.StampData", id );

EndProcedure

