StandardProcessing = false;

env = getEnv ( _ );
createEnv ( env );

p = Call ( "Documents.VendorInvoice.Buy.Params" );
p.Date = Env.LastDate;
p.Vendor = Env.Vendor;
p.Warehouse = Env.Warehouse;

goods = new Array ();

row = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
row.Item = "_LVI1: " + Params.ID;
row.CountPackages = false;
row.CostMethod = "FIFO";
row.Quantity = "1";
row.Price = "1000";
goods.Add ( row );

row = Call ( "Documents.VendorInvoice.Buy.ItemsRow" );
row.Item = "_LVI2, countPkg: " + Params.ID;
row.CountPackages = true;
row.CostMethod = "FIFO";
row.Quantity = "1";
row.Price = "100";
goods.Add ( row );

p.Items = goods;
Call ( "Documents.VendorInvoice.Buy", p );

With ( "Vendor invoice*" );
Click ( "#FormDocumentStartupCreateBasedOn" );

formMain = With ( "LVI Startup (create)*" );

Set ( "#CostLimit", env.Limit.Limit );

Click ( "#ShowPrices" );

for i = 1 to 2 do
	With ( formMain );
	table = Activate ("#Items" );
	Activate ( "#ItemsItem [ " + i + " ]", table );
	Click ( "#ItemsChange" );

	form = With ( "LVI" );
	Choose ( "#Employee" );
	p = Call ( "Common.Select.Params" );
	p.Object = Meta.Catalogs.Employees;
	p.CreateScenario = "Catalogs.Employees.Create";
	p.Search = Env.Employee;
	Call ( "Common.Select", p );

	With ( form );
	Choose ( "#ItemsExpense" );
	p = Call ( "Common.Select.Params" );
	p.Object = Meta.Catalogs.Expenses;
	p.CreateScenario = "Catalogs.Expenses.Create";
	p.Search = env.Expense;
	Call ( "Common.Select", p );
	
	With ( form );
	Choose ( "#Department" );
	p = Call ( "Common.Select.Params" );
	p.Object = Meta.Catalogs.Departments;
	p.CreateScenario = "Catalogs.Departments.Create";
	p.Search = env.Department;
	par = Call ( "Catalogs.Departments.Create.Params" );
	par.Description = p.Search;
	p.CreationParams = par;
	Call ( "Common.Select", p );

	With ( form );
	Set ( "#ResidualValue", i * 100 );
	Set ( "#ExpenseAccount", "7141" );
	Click ( "#KeepOnBalance" );

	Click ( "#FormOK" );
enddo;

With ( formMain );

fillStakeholders ( formMain, env.Employees );

Click ( "#FormPost" );

if ( GetMessages ().Count () = 0 ) then
	Stop ( "Error message must be shown" );
endif;

Click ( "#FormCopy" );
copy = "LVI Startup (create*";
if ( not Waiting ( copy ) ) then
	Stop ( "The copy of document shoul be appeared" );
endif;
Close ( copy );

// ***********************************
// Procedures
// ***********************************

Function getEnv ( Params )
	
	id = Params.ID;
	env = new Structure ();
	env.Insert ( "ID", id );
	date = "06/02/2019";
	env.Insert ( "Date", date );
	env.Insert ( "LastDate", "06/01/2019" );
	env.Insert ( "Warehouse", "Warehouse: " + id );
	env.Insert ( "Department", Params.Department );
	env.Insert ( "Expense", Params.Expense );
	env.Insert ( "Employee", Params.Employee  );
	env.Insert ( "Limit", new Structure ( "Date, Limit", date, 100 ) );
	env.Insert ( "Vendor", "Vendor: " + id );
	employees = new Array ();
	dateStart = "01/01/2019";
	department = "Administration";
	compensation = "Compensation: " + id;
	employees.Add ( newEmployee ( "Approved: " + id, dateStart, department, "Director", compensation ) );
	employees.Add ( newEmployee ( "Head: " + id, dateStart, department, "Manager", compensation ) );
	employees.Add ( newEmployee ( "Member1: " + id, dateStart, department, "Accountant", compensation ) );
	employees.Add ( newEmployee ( "Member2: " + id, dateStart, department, "Stockman", compensation ) );
	env.Insert ( "Employees", employees );
	env.Insert ( "Compensation", compensation );
	return env;

EndFunction

Function newEmployee ( Employee, DateStart, Department, Position, Compensation )

 	p = Call ( "Documents.Hiring.Create.Row" );
	p.Employee = Employee;
	p.DateStart = DateStart;
	p.Department = Department;
	p.Position = Position;
	p.Compensation = Compensation;
	return p;

EndFunction

Procedure createEnv ( Env )

 	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	Call ( "Documents.Startup.TestCreation.LVILimit", Env.Limit );
	
	// Compensations
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Compensation;
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// Employees
	
	for each row in Env.Employees do	
		p = Call ( "Catalogs.Employees.Create.Params" );
		p.Description = row.Employee;
		Call ( "Catalogs.Employees.Create", p );
	enddo;
	
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




