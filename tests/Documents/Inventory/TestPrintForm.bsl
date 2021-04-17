Call ( "Common.Init" );
CloseAll ();
env = getEnv ();
createEnv ( env );

Call ( "Common.OpenList", Meta.Documents.Inventory );
With ( "Inventories" );
GotoRow ( "#List", "Memo", env.ID );
With ( "Inventories" );
Click ( "#FormDataProcessorInventoryInventory" );
With ( "Inventory: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "2B8A98B7#" );
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
	// Create Inventory
	// ***********************************
	Call ( "Documents.Inventory.TestCreation.Create", id );
	CloseAll ();

	Call ( "Common.StampData", id );

EndProcedure
