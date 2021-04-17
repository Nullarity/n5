// Description:
// Set filters in LVI Inventory list form and create a new LVI Inventory.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();

an = AppName;

env = getEnv ();
createEnv ( env );

form = Call ( "Common.OpenList", Meta.Documents.LVIInventory );

Choose ( "#DepartmentFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Departments;
p.Search = env.Department;
Call ( "Common.Select", p );

With ( form );
department = Fetch ( "#DepartmentFilter" );
Click ( "#FormCreate" );

With ( "LVI Inventory (create)" );
Check ( "#Department", department );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "24E9B4D0#" );
	env = new Structure ();
	env.Insert ( "ID", id );
	env.Insert ( "Department", "Department" + id );
	return env;

EndFunction

Procedure createEnv ( Env )

    id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// ***********************
	// Create Department
	// ***********************

	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
		
	Call ( "Common.StampData", id );

EndProcedure
