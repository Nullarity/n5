Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A01Z" );
env = getEnv ( id );
createEnv ( env );

// ********************
// Open Employees
// ********************

Commando ( "e1cib/list/Catalog.Employees" );
form = With ( "Employees" );
Put ( "#DepartmentFilter", env.Department );
p = Call ( "Common.Find.Params" );
p.Where = "Description";
p.What = env.Employee;
Call ( "Common.Find", p );
Click ( "#FormChange" );
empForm = With ( env.Employee + "*" );
Close ( empForm );

With ( form );
Pick ( "#StatusFilter", "Terminated" );
table = Activate ( "#List" );
if ( Call ( "Table.Count", table ) > 0 ) then
	Stop ( "Must be 0 rows!" );
endif;
With ( form );
Pick ( "#StatusFilter", "Current" );
p = Call ( "Common.Find.Params" );
p.Where = "Description";
p.What = env.Employee;
Call ( "Common.Find", p );
Click ( "#FormChange" );
empForm = With ( env.Employee + "*" );
Close ( empForm );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	date = BegOfMonth ( CurrentDate () );
	p.Insert ( "DateStart", date );
	p.Insert ( "DateEnd", AddMonth ( date, 3 ) );
	p.Insert ( "Department", "_Department " + ID );
	p.Insert ( "Employee", "_Employee " + id );
	p.Insert ( "Expenses", "Expenses " + id );
	p.Insert ( "Employees", getEmployees ( p ) );
	p.Insert ( "MonthlyRate", "_Monthly " + ID );
	return p;

EndFunction

Function getEmployees ( Env )

	id = Env.ID;
	
	employees = new Array ();
	employees.Add ( newEmployee ( env.Employee, Env.DateStart, Env.DateEnd, 1000 ) );
	return employees;

EndFunction

Function newEmployee ( Name, DateStart, DateEnd, Rate )

	p = new Structure ( "Name, DateStart, DateEnd, Rate" );
	p.Name = Name;
	p.DateStart = DateStart;
	p.DateEnd = DateEnd;
	p.Rate = Rate;
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Employees
	// *************************
	
	for each employee in Env.Employees do
		p = Call ( "Catalogs.Employees.Create.Params" );
		p.Description = employee.Name;
		Call ( "Catalogs.Employees.Create", p );
	enddo;

	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Expenses
	// *************************
	
	expense = "Expense " + id;
	Call ( "Catalogs.Expenses.Create", expense );
	
	p = Call ( "Catalogs.ExpenseMethods.Create.Params" );
	expenses = Env.Expenses;
	p.Description = expenses;
	p.Account = "8111";
	p.Expense = expense;
	Call ( "Catalogs.ExpenseMethods.Create", p );

	// *************************
	// Create Compensation
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.MonthlyRate;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );

	// *************************
	// Hiring
	// *************************
	
	department = Env.Department;
	monthlyRate = Env.MonthlyRate;
	params = Call ( "Documents.Hiring.Create.Params" );
	for each employee in Env.Employees do
		p = Call ( "Documents.Hiring.Create.Row" );
		p.Employee = employee.Name;
		p.DateStart = Format ( employee.DateStart, "DLF=D" );
		//p.DateEnd = Format ( employee.DateEnd, "DLF=D" );
		p.Department = department;
		p.Position = "Manager";
		p.Rate = employee.Rate;
		p.Expenses = expenses;
		p.Compensation = monthlyRate;
		params.Employees.Add ( p );
	enddo;
	params.Date = Env.DateStart;
	Call ( "Documents.Hiring.Create", params );

	Call ( "Common.StampData", id );

EndProcedure
