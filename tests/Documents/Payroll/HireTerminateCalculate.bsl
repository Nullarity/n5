// Hire Employee
// Terminate in the middle of the month
// Calculate his salary

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "284AB954" );
env = getEnv ( id );
createEnv ( env );

// Create payroll
Commando ( "e1cib/data/Document.Payroll" );
form = With ( "Payroll (cr*" );

// Open Filling options
Click ( "#Fill" );
settingsForm = With ( "Payroll: Setup Filters" );
table = Get ( "#UserSettings" );

// Change filling period
GotoRow ( table, "Setting", "Period" );
Choose ( "#UserSettingsValue", table );

With ( "Select period" );
Set ( "#DateEnd", Format ( EndOfMonth ( env.Date ), "DLF=D" ) );
Click ( "#Select" );

// Set department
With ( settingsForm );
Next ();
GotoRow ( table, "Setting", "Department" );
Put ( "#UserSettingsValue", env.Department, table );

// Fill
Click ( "#FormFill" );
Pause ( __.Performance * 7 );
With ( form );

// Get work hours
hours = workHours ( BegOfMonth ( env.Date ), env.HalfMonth, env.Schedule );
totalHours = hours + workHours ( env.HalfMonth + 86400, EndOfMonth ( env.Date ), env.Schedule );

// Calc compensations manually
rate = env.Rate;
amount = Int ( ( rate / totalHours ) * hours );
calculatedAmount = Int ( Fetch ( "#Compensations / #CompensationsResult [ 1 ]" ) );
if ( amount <> calculatedAmount ) then
	Stop ( "Compensation for half month should be " + amount + " instead of " + calculatedAmount );
endif;

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = CurrentDate ();
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", date );
	p.Insert ( "HalfMonth", BegOfMonth ( date ) + 14 * 86400 );
	p.Insert ( "Department", "_Department " + ID );
	p.Insert ( "Schedule", "_Schedule " + ID );
	p.Insert ( "Rate", 1000 );
	p.Insert ( "Employees", getEmployees ( p ) );
	p.Insert ( "MonthlyRate", "_Monthly " + ID );
	return p;

EndFunction

Function getEmployees ( Env )

	id = Env.ID;
	date = Env.Date;
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
	Call ( "Catalogs.Schedules.Create", p );
	
	// *************************
	// Hiring
	// *************************
	
	department = Env.Department;
	schedule = Env.schedule;
	params = Call ( "Documents.Hiring.Create.Params" );
	employees = params.Employees;
	for each employee in Env.Employees do
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
	
	// ********************
	// Terminate
	// ********************
	Commando ( "e1cib/data/Document.Termination" );
	With ( "Termination (cr*" );
	Set ( "#Date", Format ( Env.HalfMonth, "DLF=D" ) );
	for each employee in Env.Employees do
		Click ( "#EmployeesAdd" );
		Put ( "#EmployeesEmployee", employee.Name );
	enddo;
	Click ( "#FormPostAndClose" );

	RegisterEnvironment ( id );

EndProcedure

Function workHours ( DateStart, DateEnd, Schedule )

	p = Call ( "Catalogs.Schedules.WorkHours.Params" );
	p.DateStart = DateStart;
	p.DateEnd = DateEnd;
	p.Schedule = Schedule;
	hours = Call ( "Catalogs.Schedules.WorkHours", p );
	return hours;

EndFunction
