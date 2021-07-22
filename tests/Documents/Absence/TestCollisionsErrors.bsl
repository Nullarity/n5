// 1. Create document Absence
// 2. Try to add error rows
// 3. If Error messages are shown then test is complete

StandardProcessing = false;

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "275D48C4" );
env = getEnv ( id );
createEnv ( env );

// ********************
// Create a new Absence
// ********************

Commando ( "e1cib/command/Document.Absence.Create" );
form = With ( "Absence at Work (cr*" );
table = Get ( "#Employees" );
employee = env.Employees [ 0 ].Name;
Click ( "#EmployeesAdd" );
Put ( "#EmployeesEmployee", employee, table );
Put ( "#EmployeesDateStart", "01/01/2017", table );
Put ( "#EmployeesDateEnd", "01/10/2017", table );

Click ( "#FormPost" );
if ( FindMessages ( "Failed to post*" ).Count () = 0 ) then
	Stop ( " dialog box must be shown" );
endif;
Click ( "OK", Forms.Get1C () );
error = "Work hours for the " + employee + " is undefined. Check employee’s schedule for the following days: 1/1/2017, 1/7/2017, 1/8/2017";
if ( FindMessages ( _ ) [ 0 ] <> error ) then
	Stop ( "Error: " + error + " must be shown" );
endif;

Click ( "#EmployeesAdd" );
Put ( "#EmployeesEmployee", employee, table );
Put ( "#EmployeesDateStart", "01/01/2017", table );
Put ( "#EmployeesDateEnd", "01/10/2017", table );
Click ( "#FormPost" );
if ( FindMessages ( "Failed to post*" ).Count () = 0 ) then
	Stop ( " dialog box must be shown" );
endif;
Click ( "OK", Forms.Get1C () );
error = "In the line #1 (" + employee + ") incorrect periods have been found ";
if ( FindMessages ( _ ) [ 0 ] <> error ) then
	Stop ( "Error: " + error + " must be shown" );
endif;

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = Date ( 2017, 01, 01 );
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", date );
	p.Insert ( "Department", "_Department " + ID );
	p.Insert ( "MonthlyRate", "_Monthly " + ID );
	p.Insert ( "Rate", "1000" );
	p.Insert ( "NewRate", "1500" );
	p.Insert ( "Employees", getEmployees ( p ) );
	return p;

EndFunction

Function getEmployees ( Env )

	id = Env.ID;
	date = AddMonth ( Env.Date, -1 );
	dateStart = BegOfMonth ( date );
	dateEnd = Date ( 1, 1, 1 );
	rate = Env.Rate;
	
	employees = new Array ();
	employees.Add ( newEmployee ( "_Employee1 " + id, dateStart, dateEnd, rate ) );
	employees.Add ( newEmployee ( "_Employee2 " + id, dateStart, dateEnd, rate ) );
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
	if ( EnvironmentExists ( id ) ) then
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
		p.DateEnd = Format ( employee.DateEnd, "DLF=D" );
		p.Department = department;
		p.Position = "Manager";
		p.Rate = employee.Rate;
		p.Compensation = monthlyRate;
		params.Employees.Add ( p );
	enddo;
	params.Date = AddMonth ( Env.Date, -1 );
	Call ( "Documents.Hiring.Create", params );

	RegisterEnvironment ( id );

EndProcedure

