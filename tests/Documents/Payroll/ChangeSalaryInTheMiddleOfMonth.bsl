Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "284AB796" );
env = getEnv ( id );
createEnv ( env );

// ********************
// Create a new Payroll
// ********************

Commando ( "e1cib/command/Document.Payroll.Create" );
form = With ( "Payroll (cr*" );
documentDate = Date ( Fetch ( "#DateStart" ) );
date = env.Date;
direction = ? ( documentDate < date, 1, -1 );
breaker = 1;

while ( true ) do
	dateStart = Date ( Fetch ( "#DateStart" ) );
	if ( dateStart = date ) then
		break;
	else
		Click ( ? ( direction = 1, "#NextPeriod", "#PreviousPeriod" ) );
	endif;
	breaker = breaker + 1;
enddo;


Click ( "#Fill" );
With ( "Payroll: Setup Filters" );
table = Get ( "#UserSettings" );
GotoRow ( table, "Setting", "Department" );
Put ( "#UserSettingsValue", env.Department, table );

Click ( "#FormFill" );
Pause ( __.Performance * 7 );

With ( form );

// Check calculation results
Check ( "#Compensations / Result [ 1 ]", 454.55 ); // For rate = 1000
Check ( "#Compensations / Result [ 2 ]", 818.18 ); // For rate = 1500
Check ( "#Compensations / Result [ 3 ]", 1000 ); // Rate has not been changed

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = Date ( 2017, 01, 01 );
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", date );
	p.Insert ( "TransferDate", Date ( 2017, 01, 16 ) );
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

	// *************************
	// Transfer
	// *************************
	
	transferDate = Format ( Env.TransferDate, "DLF=D" );
	Commando ( "e1cib/command/Document.EmployeesTransfer.Create" );
	form = With ( "Employees Transfer (cr*" );
	Set ( "#Date", transferDate );

	employee = Env.Employees [ 0 ].Name;
	Click ( "#EmployeesAdd" );
	With ( "Employee" );
	Put ( "#Employee", employee );
	Set ( "#Date", transferDate );
	Set ( "#Rate", Env.NewRate );
	Click ( "#FormOK" );
	With ( form );
	Click ( "#FormPostAndClose" );

	Call ( "Common.StampData", id );

EndProcedure
