Call ( "Common.Init" );
CloseAll ();
env = getEnv ();
createEnv ( env );

Call ( "Common.OpenList", Meta.Documents.IntangibleAssetsCommissioning );
With ( "Intangible Assets Commissionings" );
GotoRow ( "#List", "Memo", env.ID );
Click ( "#FormChange" );
With ( "Intangible Assets Commissioning*" );
Click ( "#FormDataProcessorAN1AN1" );
With ( "Form AN-1: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "25657FC7#" );
	env = new Structure ();
	env.Insert ( "ID", id );
	env.Insert ( "Date", CurrentDate () );
	return env;

EndFunction

Procedure createEnv ( Env )

 	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// ***********************************
	// Create IntangibleAssetsCommissioning
	// ***********************************
	Call ( "Documents.IntangibleAssetsCommissioning.TestCreation.Create", id );
	CloseAll ();

	Call ( "Common.StampData", id );

EndProcedure