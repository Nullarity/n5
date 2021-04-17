Call ( "Common.Init" );
CloseAll ();

env = getEnv ( "25E04041#" );
createEnv ( env );

Call ( "Common.OpenList", Meta.Documents.Commissioning );

Clear ( "#DepartmentFilter" );
Clear ( "#WarehouseFilter" );

p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = env.id;
Call ( "Common.Find", p );
form = With ( "Commissionings" );

Click ( "#FormDataProcessorMF1MF1" );
With ( "Form MF-1: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );


// ***********************************
// Procedures
// ***********************************

Function getEnv ( ID )

	env = new Structure ();
	env.Insert ( "ID", ID );
	env.Insert ( "Date", CurrentDate () );
	return env;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// ***********************************
	// Create Commissioning 
	// ***********************************
	Call ( "Documents.Commissioning.TestCreation.Create", id );
	
	Call ( "Common.StampData", id );

EndProcedure

