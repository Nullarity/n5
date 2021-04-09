// Description:
// Set filters in LVI Write-off list form and create a new LVI Write-off.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();

an = AppName;

env = getEnv ();
createEnv ( env );

form = Call ( "Common.OpenList", Meta.Documents.LVIWriteoff );

Choose ( "#DepartmentFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Departments;
p.Search = env.Department;
Call ( "Common.Select", p );

With ( form );
department = Fetch ( "#DepartmentFilter" );
Click ( "#FormCreate" );

With ( "LVI Write Off (create)" );
Check ( "#Department", department );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "616786900#" );
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
