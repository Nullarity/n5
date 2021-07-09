Call ( "Common.Init" );
CloseAll ();
env = getEnv ();
createEnv ( env );

Call ( "Common.OpenList", Meta.Documents.AssetsInventory );
With ( "Assets Inventories" );
GotoRow ( "#List", "Memo", env.ID );
Click ( "#FormChange" );
With ( "Assets Inventory*" );
Click ( "#FormDataProcessorInventoryAssetsINV1" );
With ( "Inventory List: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "2BD8DE04" );
	env = new Structure ();
	env.Insert ( "ID", id );
	env.Insert ( "Date", CurrentDate () );
	return env;

EndFunction

Procedure createEnv ( Env )

 	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// ***********************************
	// Create AssetsInventory
	// ***********************************
	Call ( "Documents.AssetsInventory.TestCreation.Create", id );
	CloseAll ();

	RegisterEnvironment ( id );

EndProcedure