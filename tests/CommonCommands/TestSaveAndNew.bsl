Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "275D41F1" );
env = getEnv ( id );
createEnv ( env );

Run ( "TestSaveAndNewItem", env );
Run ( "TestSaveAndNewCustomer", env );
Run ( "TestSaveAndNewVendor", env );
Run ( "TestSaveAndNewEmployee", env );
Run ( "TestSaveAndNewFixedAsset", env );
Run ( "TestSaveAndNewIntangibleAsset", env );
Run ( "TestSaveAndNewDepartment", env );
Run ( "TestSaveAndNewWarehouse", env );
Run ( "TestSaveAndNewUser" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Employee", "Employee " + ID );
	p.Insert ( "FixedAsset", "FixedAsset " + ID );
	p.Insert ( "IntangibleAsset", "IntangibleAsset " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Employee
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );
	
	// *************************
	// Create FixedAsset
	// *************************
	
	p = Call ( "Catalogs.FixedAssets.Create.Params" );
	p.Description = Env.FixedAsset;
	Call ( "Catalogs.FixedAssets.Create", p );
	
	// *************************
	// Create IntangibleAsset
	// *************************
	
	p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
	p.Description = Env.IntangibleAsset;
	Call ( "Catalogs.IntangibleAssets.Create", p );
	
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
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );

	RegisterEnvironment ( id );

EndProcedure
