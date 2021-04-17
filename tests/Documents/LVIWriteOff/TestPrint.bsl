//	Create LVI Startup then LVI WriteOff and test print form
//	1. Create Vendor Invoice
//	2. Create Startup based on VendorInvoice
//	3. Create LVI WriteOff
//	4. Fill Stakeholders
//	5. Test print form

Call ( "Common.Init" );
CloseAll ();

StandardProcessing = false;

id = Call ( "Common.ScenarioID", "2C04578C" );
env = getEnv ( id );
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/list/Document.LVIWriteOff" );
list = With ();
Put ( "#DepartmentFilter", env.Department );
Try
	Click ( "#FormChange" );
	form = With ();
	Try
		Click ( "#FormUndoPosting" );
	Except
	EndTry;
Except
	With ( list );
	Click ( "#FormCreate" );
	form = With ();
EndTry;

Put ( "#Memo", id );

Call ( "Common.CheckCurrency", form );

Put ( "#ExpenseAccount", "7141" );
Put ( "#Department", env.Department );
if ( Fetch ( "#ShowPrices" ) = "No" ) then
	Click ( "#ShowPrices" );
endif;

table = Activate ( "#Items" );
Call ( "Table.Clear", table );

Click ( "#ItemsAdd" );

Try
	Put ( "#ItemsExpenseAccount", "7141", table );
Except
	Click ( "#ItemsShowDetails" );
EndTry;

Put ( "#ItemsItem", env.LVI, table );
Next ();
Put ( "#ItemsQuantity", 2, table );// must show error
Next ();
Put ( "#ItemsAmount", 100, table );
Put ( "#ItemsExpenseAccount", "7141", table );
Next ();
Put ( "#ItemsEmployee", env.Employee, table );
Put ( "#ItemsDim1", env.Expense, table );

fillStakeholders ( form, env.Employees );

With ( form );
Click ( "#FormPost" );

try
	CheckErrors();
	Stop ( "Error message must be shown" );
except
endtry;

Click ( "OK", Forms.Get1C () ); // Closes 1C standard dialog

With ( form );
table = Activate ("#Items" );
Put ( "#ItemsQuantity", 1, table );
Put ( "#ItemsAmount", 100, table );

With ( form );
Click ( "#FormPost" );

Click ( "#FormCopy" );
copy = "LVI Write Off (create)";
if ( not Waiting ( copy ) ) then
	Stop ( "The copy of document shoul be appeared" );
endif;
Close ( copy );

With ( form );
Run ( "OV_8" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "LVI", "_LVI " + ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	p.Insert ( "Warehouse", "Warehouse " + ID );
	p.Insert ( "Department", "LVI Department " + ID );
	p.Insert ( "Employee", "LVI Employee " + ID );
	p.Insert ( "Expense", "_Expense  " + ID );
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
	// Create Employee
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
	Put ( "#Employee", env.Employee );
	Put ( "#ItemsExpense", env.Expense );
	Put ( "#Department", env.Department );
	
	Put ( "#ResidualValue", 100 );
	Put ( "#ExpenseAccount", "7141" );
	Click ( "#FormOK" );
	
	With ( form );
	Put ( "#Memo", id );
	Put ( "#CostLimit", 200 );
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
