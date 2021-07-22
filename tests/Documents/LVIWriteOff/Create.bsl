
MainWindow.ExecuteCommand ( "e1cib/list/Document.LVIWriteOff" );
form = With ( "LVI Write Offs" );
Click ( "Create", form.GetCommandBar () );
form = With ( "LVI Write Off (create)*" );
Set ( "!AmortizationAccount", "2141" );

date = CurrentDate ();

employees = hireEmployees ( date, BegOfYear ( date ) );
fillStakeholders ( form, employees );

Call ( "Common.CheckCurrency", form );

Set ( "#ExpenseAccount", "7141" );
Choose ( "#Department" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Departments;
p.CreateScenario = "Catalogs.Departments.Create";
p.Search = _.DepartmentSender;
par = Call ( "Catalogs.Departments.Create.Params" );
par.Description = p.Search;
par.Company = "ABC Distributions";
p.CreationParams = par;
Call ( "Common.Select", p );

Click ( "!ShowPrices" );

Click ( "!ItemsShowDetails" );
table = Activate ("#Items" );
table.EndEditRow ();
Set ( "#ItemsItem", _.LVI, table );
Set ( "#ItemsQuantity", 2, table );// must show error

Set ( "#ItemsAccount", "2132", table );

Set ( "#ItemsAmount", _.ResidualValue, table );
Set ( "#ItemsExpenseAccount", "7141", table );

Choose ( "#ItemsEmployee", table );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Employees;
p.CreateScenario = "Catalogs.Employees.Create";
p.Search = _.EmployeeSender;
Call ( "Common.Select", p );

Choose ( "#ItemsDim1", table );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Expenses;
p.CreateScenario = "Catalogs.Expenses.Create";
p.Search = _.Expense;
Call ( "Common.Select", p );

With ( form );
Click ( "#FormPost" );

if ( GetMessages ().Count () = 0 ) then
	Stop ( "Error message must be shown" );
endif;

Click ( "OK", Forms.Get1C () ); // Closes 1C standard dialog

With ( form );
table = Activate ("#Items" );
Set ( "#ItemsQuantity", 1, table );
Set ( "#ItemsAmount", _.ResidualValue, table );

With ( form );
Click ( "#FormPost" );

Click ( "#FormCopy" );
copy = "LVI Write Off (create)";
if ( not Waiting ( copy ) ) then
	Stop ( "The copy of document shoul be appeared" );
endif;
Close ( copy );

// ***********************************
// Procedures                                 
// ***********************************

Function hireEmployees ( Date, DateStart )

    p = Call ( "Documents.Hiring.Create.Params" );
	employees = new Array ();
	id = Call ( "Common.ScenarioID", "616789453#" );
	employees.Add ( newEmployee ( "_Approved: " + id, DateStart, "Administration", "Director" ) );
	employees.Add ( newEmployee ( "_Head: " + id, DateStart, "Administration", "Manager" ) );
	employees.Add ( newEmployee ( "_Member1: " + id, DateStart, "Administration", "Accountant" ) );
	employees.Add ( newEmployee ( "_Member2: " + id, DateStart, "Administration", "Stockman" ) );
	p.Employees = employees;
	p.Insert ( "App" );
	if ( not RegisterEnvironment ( id ) ) then
		Call ( "Documents.Hiring.Create", p );
		RegisterEnvironment ( id );
	endif;
	return employees;

EndFunction

Function newEmployee ( Employee, DateStart, Department, Position )

 	p = Call ( "Documents.Hiring.Create.Row" );
	p.Insert ( "Employee", Employee );
	p.Insert ( "DateStart", DateStart );
	p.Insert ( "Department", Department );
	p.Insert ( "Position", Position );
	return p;

EndFunction

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
