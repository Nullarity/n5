
Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/list/Document.ExpenseReport" );
form = With ( "Expense Reports" );

Put ( "#EmployeeFilter", env.Employee );
Put ( "#WarehouseFilter", env.Warehouse );

Click ( "#FormCreate" );

With ( "Expense Report (create)" );
Check ( "#Employee", env.Employee );
Check ( "#Warehouse", env.Warehouse );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "254A1FF4#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Employee", "_Employee: " + id );
	p.Insert ( "Warehouse", "_Warehouse: " + id );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Warehouse
	// *************************
	Call ( "Catalogs.Warehouses.Create", Env.Warehouse );

	// *************************
	// Create Employee
	// *************************
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );

	RegisterEnvironment ( id );

EndProcedure


