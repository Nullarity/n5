//	Create Internal Order and test print form
//	1. Internal Order
//	2. Test print form

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A4DE9C4" );
env = getEnv ( id );
createEnv ( env );

form = Commando ( "e1cib/list/Document.InternalOrder" );
Put ( "#DepartmentFilter", env.Department );
Put ( "#WarehouseFilter", env.Warehouse );
Click ( "#FormDocumentInternalOrderInternalOrder" );
With ();
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item1", "Item1: " + ID );
	p.Insert ( "Item2", "Item2: " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Employee", "Employee " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Employee
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );

	// *************************
	// Create Items
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item1;
	Call ( "Catalogs.Items.Create", p );
	
	p.Description = Env.Item2;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Internal Order
	// *************************
	
	form = Commando ( "e1cib/data/Document.InternalOrder" );

	Put ( "#Responsible", Env.Employee );
	Put ( "#Department", Env.Department );
	Put ( "#Warehouse", Env.Warehouse );
	
	table = Get ( "#ItemsTable" );
	
	Click ( "#ItemsTableAdd" );
	Put ( "#ItemsItem", env.Item1, table );
	Put ( "#ItemsQuantity", 1, table );
	Put ( "#ItemsPrice", 1000, table );
	
	Click ( "#ItemsTableAdd" );
	Put ( "#ItemsItem", env.Item2, table );
	Put ( "#ItemsQuantity", 1, table );
	Put ( "#ItemsPrice", 100, table );
	
	Click ( "#FormWrite" );
	Close ( form );

	RegisterEnvironment ( id );
	
EndProcedure