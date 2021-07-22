Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B8A8B23" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/data/Document.VendorInvoice" );
form = With ( "Vendor Invoice (cr*" );

Put ( "#Vendor", env.Vendor );
Put ( "#Warehouse", env.Warehouse );

// Items
table = Get ( "#ItemsTable" );
Click ( "#ItemsTableAdd" );

Put ( "#ItemsItem", env.Item, table );
Put ( "#ItemsQuantityPkg", 2, table );
Put ( "#ItemsPrice", 50, table );

// Services
table = Get ( "#Services" );
Click ( "#ServicesAdd" );

Put ( "#ServicesItem", env.Service, table );
Put ( "#ServicesQuantity", 2, table );
Put ( "#ServicesPrice", 50, table );
//Put ( "#ServicesAccount", "7141", table );
Put ( "#ServicesExpense", env.Expense, table );


// Accounts
table = Get ( "#Accounts" );
Click ( "#AccountsAdd" );

Put ( "#AccountsAccount", "2111", table );
Next ();
Put ( "#AccountsAmount", 100, table );
Next ();
Put ( "#AccountsVATCode", "20%", table );
Next ();
Put ( "#AccountsVATAccount", "5344" );

// FixedAssets
Click ( "#FixedAssetsAdd" );
With ( "Fixed Asset" );

Put ( "#Item", env.Fixed );
Put ( "#Amount", "100" );
Put ( "#Department", env.Department );
Put ( "#Employee", env.Employee );
Put ( "#VATAccount", "VATAccount" );
Click ( "#FormOK" );

With ( form );

// IntangibleAssets
Click ( "#IntangibleAssetsAdd" );
With ( "Intangible Asset" );

Put ( "#Item", env.Intangible );
Put ( "#Amount", "100" );
Put ( "#Department", env.Department );
Put ( "#Employee", env.Employee );
Put ( "#VATAccount", "VATAccount" );
Click ( "#FormOK" );

With ( form );

Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Vendor *" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Service", "Service " + ID );
	p.Insert ( "Fixed", "Fixed " + ID );
	p.Insert ( "Intangible", "Intangible " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Employee", "Employee " + ID );
	p.Insert ( "Expense", "Expense " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Expense
	// *************************
	
	Call ( "Catalogs.Expenses.Create", env.Expense );
	
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
	// Create Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Service;
	p.Service = true;
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

