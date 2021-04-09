Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "286F57BB" );
env = getEnv ( id );
createEnv ( env );

// ********************                                      //32.58
// Create a new Payroll
// ********************

Commando ( "e1cib/data/Document.Payroll" );
form = With ();

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
Click ( "#FormDocumentPayrollPayroll" );
Click ( "OK", Forms.Get1C () );
With ( "Payroll: Print" );

// Check overtime calculation
hourlyRate = Number ( Fetch ( "#TabDoc [ R10C18 ]" ) );
overtime = Number ( Fetch ( "#TabDoc [ R11C8 ]" ) ); // must be 8 hours
Check ( "#TabDoc [ R11C8 ]", 8 );
coef1 = 1.5;
coef2 = 2;
amount = Round ( hourlyRate * 4 * coef1 + hourlyRate * 4 * coef2, 2 );
Check ( "#TabDoc [ R11C11 ]", amount );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	//p.Insert ( "Date", CurrentDate () );
	p.Insert ( "Date", Date ( 2017, 1, 1 ) );
	p.Insert ( "Department", "_Department " + ID );
	p.Insert ( "Schedule", "_Schedule " + ID );
	p.Insert ( "Employees", getEmployees ( p ) );
	p.Insert ( "MonthlyRate", "_Monthly " + ID );
	return p;

EndFunction

Function getEmployees ( Env )

	id = Env.ID;
	date = Env.Date;
	dateStart = BegOfMonth ( date );
	dateEnd = Date ( 1, 1, 1 );
	
	employees = new Array ();
	employees.Add ( newEmployee ( "_Employee1 " + id, dateStart, dateEnd, 1000, 2 ) );
	employees.Add ( newEmployee ( "_Employee2 " + id, dateStart, dateEnd, 1000, 5 ) );
	return employees;

EndFunction

Function newEmployee ( Name, DateStart, DateEnd, Rate, Overtime )

	p = new Structure ( "Name, DateStart, DateEnd, Rate, Overtime" );
	p.Name = Name;
	p.DateStart = DateStart;
	p.DateEnd = DateEnd;
	p.Rate = Rate;
	p.Overtime = Overtime;
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
	
	mainCompensation = Env.MonthlyRate;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = mainCompensation;
	p.Method = "Monthly Rate";
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
	
	// ******************
	// Overtime: two days
	// ******************
	
	overtimeDays = Run ( "FirstMonday", BegOfMonth ( date ) );

	p = Call ( "Documents.Deviations.Create.Params" );
	employees = p.Employees;
	
	employee = Env.Employees [ 0 ].Name;
	
	// Monday
	row = Call ( "Documents.Deviations.Create.Row" );
	row.Employee = employee;
	row.Day = Format ( overtimeDays, "DLF=D" );
	row.Duration = 8;
	row.Time = "Absence";
	employees.Add ( row );
	
	// Tuesday
	overtimeDays = overtimeDays + 86400;
	row = Call ( "Documents.Deviations.Create.Row" );
	row.Employee = employee;
	row.Day = Format ( overtimeDays, "DLF=D" );
	row.Duration = 8;
	row.Time = "Overtime";
	employees.Add ( row );
	
	Call ( "Documents.Deviations.Create", p );

	Call ( "Common.StampData", id );

EndProcedure
