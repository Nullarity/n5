//	Create LVI Startup then LVI Transfer and test movements
//	1. Create Vendor Invoice
//	2. Create Startup based on VendorInvoice
//	3. Create LVI Transfer
//	4. Test movements

Call ( "Common.Init" );
CloseAll ();

StandardProcessing = false;

id = Call ( "Common.ScenarioID", "2C00A4A1" );
env = getEnv ( id );
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/list/Document.LVITransfer" );
With ();
p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = id;
Call ( "Common.Find", p );
Try
	Click ( "#FormChange" );
	form = With ();
	Try
		Click ( "#FormUndoPosting" );
	Except
	EndTry;
Except
	Click ( "#FormCreate" );
	form = With ();
EndTry;

Put ( "#Memo", id );

table = Activate ("#Items" );
Call ( "Table.Clear", table );

Click ( "#ItemsAdd" );
Set ( "#ItemsItem", env.LVI, table );
Set ( "#ItemsQuantity", 2, table );// must show error

table = Activate ("#Items" );
Put ( "#ItemsDepartmentReceiver", env.DepartmentReceiver );
Put ( "#ItemsDepartment", env.DepartmentSender );
Put ( "#ItemsEmployeeReceiver", env.EmployeeReceiver );
Put ( "#ItemsEmployee", env.EmployeeSender );

Click ( "#FormPost" );

try
	CheckErrors();
	Stop ( "Error message must be shown" );
except
endtry;

Click ( "OK", Forms.Get1C () ); // Closes 1C standard dialog

With ( form );
table = Activate ( "#Items" );
Set ( "#ItemsQuantity", 1, table );

With ( form );
Click ( "#FormPost" );

Click ( "#FormCopy" );
copy = "LVI Transfer (create)";
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
	p.Insert ( "LVI", "_LVI Transfer " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "DepartmentSender", "LVI Department sender " + ID );
	p.Insert ( "DepartmentReceiver", "LVI Department receiver " + ID );
	p.Insert ( "EmployeeSender", "LVI Employee sender " + ID );
	p.Insert ( "EmployeeReceiver", "LVI Employee receiver " + ID );
	p.Insert ( "Expense", "_Expense  " + ID );
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
	p.Description = Env.DepartmentSender;
	Call ( "Catalogs.Departments.Create", p );
	p.Description = Env.DepartmentReceiver;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Employee
	// *************************
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.EmployeeSender;
	Call ( "Catalogs.Employees.Create", p );
	p.Description = Env.EmployeeReceiver;
	Call ( "Catalogs.Employees.Create", p );
	
	// *************************
	// Create Items
	// *************************
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.LVI;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Expense
	// *************************
	Call ( "Catalogs.Expenses.Create", env.Expense );
	
	// *************************
	// Create Vendor Invoice
	// *************************
	Commando ( "e1cib/data/Document.VendorInvoice" );
	formVendorInvoice = With ();
	Put ( "#Vendor", Env.Vendor );
	Next ();
	Put ( "#Warehouse", Env.Warehouse );
	Next ();
	Put ( "#Date", "01/01/2018" );	
	
	table = Get ( "#ItemsTable" );
	Click ( "#ItemsTableAdd" );
	
	Put ( "#ItemsItem", env.LVI );
	Next ();
	
	Set ( "#ItemsQuantity", 1, table );
	Set ( "#ItemsPrice", 1000, table );
	
	Click ( "#FormPost" );
	// *************************
	// Create Startup
	// *************************
	Click ( "#FormDocumentStartupCreateBasedOn" );
	form = With ();
	Close ( formVendorInvoice );
	
	Click ( "#ShowPrices" );
	
	// LVI
	table = Activate ( "#Items" );
	Activate ( "#ItemsItem [ 1 ]", table );
	Click ( "#ItemsChange" );
	
	With ();
	Put ( "#Employee", env.EmployeeSender );
	Put ( "#ItemsExpense", env.Expense );
	Put ( "#Department", env.DepartmentSender );
	
	Put ( "#ResidualValue", 100 );
	Put ( "#ExpenseAccount", "7141" );
	Click ( "#FormOK" );
	
	With ( form );
	Put ( "#Memo", id );
	Put ( "#CostLimit", 200 );
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );
	
EndProcedure