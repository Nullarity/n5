//	Create LVI Startup and test print form
//	1. Create Vendor Invoice
//	2. Create Startup based on VendorInvoice
//	3. Test print form

Call ( "Common.Init" );
CloseAll ();

StandardProcessing = false;

id = Call ( "Common.ScenarioID", "2D1FA9E4" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/list/Document.Startup" );
With ();
Put ( "#WarehouseFilter", env.Warehouse );
try
	Click ( "#FormChange" );
	formMain = With ();
	Try
		Click ( "#FormUndoPosting" );
	Except
	EndTry;
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

fillStakeholders ( formMain, env.Employees );

Click ( "#FormPost" );

Run ( "PrintForm1" );

With ( formMain );

Run ( "PrintForm2" );

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
	employees = new Array ();
	dateStart = "01/01/2018";
	department = "Administration";
	compensation = "Compensation " + id;
	employees.Add ( newEmployee ( "_Approved: " + id, dateStart, department, "Director", compensation ) );
	employees.Add ( newEmployee ( "_Head: " + id, dateStart, department, "Manager", compensation ) );
	employees.Add ( newEmployee ( "_Member1: " + id, dateStart, department, "Accountant", compensation ) );
	employees.Add ( newEmployee ( "_Member2: " + id, dateStart, department, "Stockman", compensation ) );
	p.Insert ( "Employees", employees );
	p.Insert ( "Compensation", compensation );
	return p;
	
EndFunction

Function newEmployee ( Employee, DateStart, Department, Position, Compensation )
	
	p = Call ( "Documents.Hiring.Create.Row" );
	p.Employee = Employee;
	p.DateStart = DateStart;
	p.Department = Department;
	p.Position = Position;
	p.Compensation = Compensation;
	p.PutAll = true;
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
	// Create Employees, Positions
	// *************************
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );

	pPosition = Call ( "Catalogs.Positions.Create.Params" );
	for each row in env.Employees do
		p.Description = row.Employee;
		pPosition.Description = row.Position;
		Call ( "Catalogs.Employees.Create", p );
		Call ( "Catalogs.Positions.Create", pPosition );
	enddo;
	
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
	
	Set ( "#ItemsQuantity", 20, table );
	Set ( "#ItemsPrice", 1000, table );
	
	Click ( "#ItemsTableAdd" );
	
	Put ( "#ItemsItem", env.Item2 );
	Next ();
	
	Set ( "#ItemsQuantity", 20, table );
	Set ( "#ItemsPrice", 100, table );
	
	Click ( "#FormPostAndClose" );

	// Compensations
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Compensation;
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// Hiring
	
	p = Call ( "Documents.Hiring.Create.Params" );
	p.Employees = Env.Employees;
	Call ( "Documents.Hiring.Create", p );
	CloseAll ();
	
	RegisterEnvironment ( id );
	
EndProcedure

Procedure fillStakeholders ( Form, Employees )
	
	Activate ( "Stakeholders" );
	
	approved = Employees [ 0 ];
	head = Employees [ 1 ];

	setValue ( "#Approved", approved.Employee );
	Activate ( "#ApprovedPosition" );
	Check ( "#ApprovedPosition", approved.Position );

	setValue ( "#Head", head.Employee );
	Activate ( "#HeadPosition" );
	Check ( "#HeadPosition", head.Position );
	
	// *********************
	// Fill members
	// *********************
	
	table = Activate ( "#Members" );
	Call ( "Table.Clear", table );
	for i = 2 to 3 do
		member = Employees [ i ];

		Click ( "#MembersAdd" );
		setValue ( "#MembersMember", member.Employee );
		table.EndEditRow ();
		
		Check ( "#MembersPosition", member.Position, table );
	enddo;
	
EndProcedure

Procedure setValue ( Field, Value )

	form = CurrentSource;
	Choose ( Field );
	With ( "Select data type" );
	GotoRow ( "#TypeTree", "", "Employees" );
	Click ( "#OK" );
	With ( "Employees" );
	GotoRow ( "#List", "Description", Value );
	Click ( "#FormChoose" );
	CurrentSource = form;
	
EndProcedure