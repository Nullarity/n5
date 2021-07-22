Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A3E234A" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/data/Document.ReceiveItems" );
form = With ( "Receive Items (cr*" );

Put ( "#Warehouse", env.Warehouse );
Put ( "#Account", "5211" );
Put ( "#Dim1", env.Vendor );
Put ( "#VATUse", "Included in Price" );

// Items
table = Get ( "#Items" );
Click ( "#ItemsAdd" );

Put ( "#ItemsItem", env.Item, table );
Put ( "#ItemsQuantityPkg", 2, table );
Put ( "#ItemsPrice", 50, table );

// FixedAssets
Click ( "#FixedAssetsAdd" );
With ( "Fixed Asset" );

Put ( "#Item", env.Fixed );
Put ( "#Amount", "100" );
Put ( "#Department", env.Department );
Put ( "#Employee", env.Employee );
Click ( "#FormOK" );

With ( form );

// IntangibleAssets
Click ( "#IntangibleAssetsAdd" );
With ( "Intangible Asset" );

Put ( "#Item", env.Intangible );
Put ( "#Amount", "100" );
Put ( "#Department", env.Department );
Put ( "#Employee", env.Employee );
Click ( "#FormOK" );

With ( form );

Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Receive *" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Fixed", "Fixed " + ID );
	p.Insert ( "Intangible", "Intangible " + ID );
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
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Fixed asset
	// *************************
	
	p = Call ( "Catalogs.FixedAssets.Create.Params" );
	p.Description = Env.Fixed;
	Call ( "Catalogs.FixedAssets.Create", p );
	
	// *************************
	// Create Intangible asset
	// *************************
	
	p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
	p.Description = Env.Intangible;
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
	// Create Employee
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );

	RegisterEnvironment ( id );

EndProcedure

