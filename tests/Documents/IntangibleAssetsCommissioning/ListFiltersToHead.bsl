// Description:
// Set filters in document list form and create a new document.
// Checks the automatic header filling process

Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

Commando ( "e1cib/list/Document.IntangibleAssetsCommissioning" );
With ( "Intangible Assets Commissionings" );

Set ( "#DepartmentFilter", Env.Department );
Set ( "#WarehouseFilter", Env.Warehouse );

Click ( "#FormCreate" );
With ( "Intangible Assets Commissioning (create)" );
Check ( "#Warehouse", Env.Warehouse );
Check ( "#Department", Env.Department );

// ****************************
// Procedures
// ****************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "618613281#" );
	env = new Structure ();
	env.Insert ( "ID", id );
	env.Insert ( "Warehouse", "_Warehouse " + id );
	env.Insert ( "Department", "_Department " + id );
	return env;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	Call ( "Catalogs.Warehouses.Create", Env.Warehouse );
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	RegisterEnvironment ( id );

EndProcedure