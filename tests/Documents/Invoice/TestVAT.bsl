Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B670816" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Invoice
// *************************

Commando ( "e1cib/data/Document.Invoice" );
form = With ( "Invoice (cr*" );

Put ( "#Customer", env.Customer );
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

Put ( "#Department", Env.Department );

Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Invoice #*" );
Call ( "Common.CheckLogic", "#TabDoc" );

With ( form );
Click ( "#FormUndoPosting" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Item " + ID );
	p.Insert ( "Service", "Service " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Employee", "Employee " + ID );
	p.Insert ( "Expense", "Expense " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
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
	// Create Customer
	// *************************
	
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (cr*" );
	Click ( "#Customer" );
	Put ( "#Description", Env.Customer );
	Put ( "#VATUse", "Excluded from Price" );
	Click ( "#FormWriteAndClose" );
	
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
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Employee
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );
	
	// *************************
	// Create VendorInvoice
	// *************************
	
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
	Put ( "#ServicesAccount", "7141", table );
	Put ( "#ServicesExpense", env.Expense, table );

	Click ( "#FormPostAndClose" );

	Call ( "Common.StampData", id );

EndProcedure

