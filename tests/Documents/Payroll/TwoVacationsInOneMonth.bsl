Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2852ADF9" );
env = getEnv ( id );
createEnv ( env );

// **************
// Create Payroll
// **************

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

// ********************
// Check Results
// ********************

Activate ( "#Compensations" );
Click ( "#CompensationsOutputList" );
Click ( "#Ok", "Export list" );
With ( "List" );
CheckTemplate ( "" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = Date ( 2017, 01, 01 );
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", date );
	p.Insert ( "Department", "_Department " + ID );
	p.Insert ( "Schedule", "_Schedule " + ID );
	p.Insert ( "Employees", getEmployees ( p ) );
	p.Insert ( "MonthlyRate", "_Monthly " + ID );
	p.Insert ( "VacationCompensation", "_Vacation " + ID );
	
	// Vacation periods
	p.Insert ( "StartVacation1", "1/1/2017" );
	p.Insert ( "EndVacation1", "1/5/2017" );

	p.Insert ( "StartVacation2", "1/15/2017" );
	p.Insert ( "EndVacation2", "1/25/2017" );

	return p;

EndFunction

Function getEmployees ( Env )

	id = Env.ID;
	date = Env.Date;
	dateStart = BegOfMonth ( date );
	dateEnd = Date ( 1, 1, 1 );
	
	employees = new Array ();
	employees.Add ( newEmployee ( "_Employee1 " + id, dateStart, dateEnd, 3000 ) );
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
	
	mainCompensation = Env.MonthlyRate;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = mainCompensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );

	// ****************************
	// Create Vacation Compensation
	// ****************************
	
	vacationCompensation = Env.VacationCompensation;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = vacationCompensation;
	p.Method = "Vacation";
	p.Base.Add ( mainCompensation );
	Call ( "CalculationTypes.Compensations.Create", p );

	// *************************
	// Create Schedule
	// *************************

	p = Call ( "Catalogs.Schedules.Create.Params" );
	p.Description = Env.Schedule;
	p.Year = "2017";
	Call ( "Catalogs.Schedules.Create", p );
	
	// *************************
	// Hiring
	// *************************
	
	department = Env.Department;
	schedule = Env.schedule;
	params = Call ( "Documents.Hiring.Create.Params" );
	employees = params.Employees;
	for each employee in Env.Employees do
		// Main compensation
		p = Call ( "Documents.Hiring.Create.Row" );
		p.Employee = employee.Name;
		p.DateStart = Format ( employee.DateStart, "DLF=D" );
		p.DateEnd = Format ( employee.DateEnd, "DLF=D" );
		p.Department = department;
		p.Position = "Manager";
		p.Rate = employee.Rate;
		p.Compensation = mainCompensation;
		p.Schedule = schedule;

		employees.Add ( p );
	enddo;
	
	date = Env.Date;
	params.Date = date;
	Call ( "Documents.Hiring.Create", params );
	
	// ****************
	// Create Vacations
	// ****************
	
	for i = 1 to 2 do
		Commando ( "e1cib/command/Document.Vacation.Create" );
		With ( "Vacation (cr*" );
		
		for each employee in Env.Employees do
			Click ( "#EmployeesAdd" );
			Set ( "#EmployeesEmployee", employee.Name );
			Set ( "#EmployeesDateStart", Env [ "StartVacation" + i ] );
			Set ( "#EmployeesDateEnd", Env [ "EndVacation" + i ] );
			Put ( "#EmployeesCompensation", vacationCompensation );
		enddo;
		Click ( "#FormPostAndClose" );
	enddo;
	
	RegisterEnvironment ( id );

EndProcedure
