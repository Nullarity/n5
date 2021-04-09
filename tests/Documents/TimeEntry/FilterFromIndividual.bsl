Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2868F448" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/list/Catalog.Employees" );
With ( "Employees" );
GotoRow ( "#List", "Description", env.FirstName );
Click ( "#FormChange" );
With ( "* (Individuals)" );
Click ( "Time Entries", GetLinks () ); 

With ( "Time Entries" );
CheckState ( "#EmployeeFilter", "Visible", false );

Click ( "#FormCreate" );
With ( "Time Record (cr*" );
Check ( "#Performer", env.FirstName );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "FirstName", ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Employee
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.FirstName;
	p.CreateUser = true;
	Call ( "Catalogs.Employees.Create", p );
	
	Call ( "Common.StampData", id );
	
EndProcedure
