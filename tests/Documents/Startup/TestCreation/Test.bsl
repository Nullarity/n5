//	Create LVI Startup and test movements
//	1. Create Vendor Invoice
//	2. Create Startup based on VendorInvoice
//	3. Test movements

Call ( "Common.Init" );
CloseAll ();

StandardProcessing = false;

id = Call ( "Common.ScenarioID", "27BE917D" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/list/Document.Startup" );
With ();
Put ( "#WarehouseFilter", env.Warehouse );
try
	Click ( "#FormChange" );
	formMain = With ();
	try
		Click ( "#FormUndoPosting" );
	except
	endtry;	
except
	// Create Startup by Vendor invoice
	Commando ( "e1cib/list/Document.VendorInvoice" );
	With ();
	Put ( "#WarehouseFilter", env.Warehouse );
	Click ( "#FormDocumentStartupCreateBasedOn" );
	formMain = With ();
endtry;

Click ( "#ShowPrices" );
Put ( "#CostLimit", 200 );

// Item1
table = Activate ( "#Items" );
Activate ( "#ItemsItem [ 1 ]", table );
Click ( "#ItemsChange" );

With ();
Put ( "#Employee", env.Employee );
Put ( "#ItemsExpense", env.Expense );
Put ( "#Department", env.Department );

Put ( "#ResidualValue", 100 );
Put ( "#ExpenseAccount", "7141" );
Click ( "#FormOK" );

//Item2 KeepOnBalance
With ( formMain );

Activate ( "#ItemsItem [ 2 ]", table );
Click ( "#ItemsChange" );

With ();
Put ( "#Employee", env.Employee );
Put ( "#ItemsExpense", env.Expense );
Put ( "#Department", env.Department );

Put ( "#ResidualValue", 200 );
Put ( "#ExpenseAccount", "7141" );
if ( Fetch ( "#KeepOnBalance" ) = "No" ) then
	Click ( "#KeepOnBalance" );
endif;

Click ( "#FormOK" );

With ( formMain );

Click ( "#FormPost" );

if ( GetMessages ().Count () = 0 ) then
	Stop ( "Error message must be shown" );
endif;

// Test copy
Click ( "#FormCopy" );
copy = "LVI Startup (create*";
if ( not Waiting ( copy ) ) then
	Stop ( "The copy of document shoul be appeared" );
endif;
Close ( copy );

Run ( "Logic" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item1", "LVI1: " + ID );
	p.Insert ( "Item2", "LVI2: " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Department", "Department " + ID );
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
	// Create Vendor
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Organizations" );
	form = With ( "Organizations (create)" );
	Put ( "#Description", Env.Vendor );
	Click ( "#Vendor" );
	Click ( "#FormWriteAndClose" );
	
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
	// Create Items
	// *************************
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item1;
	Call ( "Catalogs.Items.Create", p );
	
	p.Description = Env.Item2;
	p.CountPackages = true;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Expense
	// *************************
	Call ( "Catalogs.Expenses.Create", env.Expense );
	
	// *************************
	// Create Vendor Invoice
	// *************************
	Commando ( "e1cib/data/Document.VendorInvoice" );
	With ();
	Put ( "#Vendor", Env.Vendor );
	Next ();
	Put ( "#Warehouse", Env.Warehouse );
	Next ();
	Put ( "#Date", "01/01/2018" );	
	
	table = Get ( "#ItemsTable" );
	Click ( "#ItemsTableAdd" );
	
	Put ( "#ItemsItem", env.Item1 );
	Next ();
	
	Set ( "#ItemsQuantity", 1, table );
	Set ( "#ItemsPrice", 1000, table );
	
	Click ( "#ItemsTableAdd" );
	
	Put ( "#ItemsItem", env.Item2 );
	Next ();
	
	Set ( "#ItemsQuantity", 1, table );
	Set ( "#ItemsPrice", 100, table );
	
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );
	
EndProcedure
