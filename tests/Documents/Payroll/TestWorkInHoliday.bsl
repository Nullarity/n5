Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28D235E2" );
env = getEnv ( id );
createEnv ( env );

// ********************
// Create a new Payroll
// ********************

Commando ( "e1cib/data/Document.Payroll" );
form = With ( "Payroll (cr*" );

Click ( "#Fill" );
settingsForm = With ( "Payroll: Setup Filters" );
table = Get ( "#UserSettings" );

// Change filling period
GotoRow ( table, "Setting", "Period" );
Choose ( "#UserSettingsValue", table );

With ( "Select period" );
Set ( "#DateBegin", Format ( BegOfMonth ( env.Date ), "DLF=D" ) );
Set ( "#DateEnd", Format ( EndOfMonth ( env.Date ), "DLF=D" ) );
Click ( "#Select" );

// Set Department
With ( settingsForm );
Next ();
GotoRow ( table, "Setting", "Department" );
Put ( "#UserSettingsValue", env.Department, table );

Click ( "#FormFill" );
Pause ( __.Performance * 7 );

With ( form );
Click ( "#FormDocumentPayrollPayroll" );
Click ( "OK", "1?:*" );
With ( "Payroll: Print" );

// Check overtime calculation
hourlyRate = Number ( Fetch ( "#TabDoc [ R10C18 ]" ) );
holidays = Number ( Fetch ( "#TabDoc [ R11C8 ]" ) ); // must be 4 hours
Check ( "#TabDoc [ R11C8 ]", 4 );
coef = 2;
amount = Round ( hourlyRate * 4 * coef, 2 );
Check ( "#TabDoc [ R11C11 ]", amount );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = CurrentDate ();
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", date );
	p.Insert ( "Holidays", "Holidays " + ID );
	p.Insert ( "HolidayDay", Run ( "FirstMonday", BegOfMonth ( date ) ) );
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
	// Create Holidays
	// *************************

	holiday = Call ( "Catalogs.Holidays.Create.Day" );
	holiday.Day = Env.HolidayDay;
	holiday.Title = "Some Holiday";
	p = Call ( "Catalogs.Holidays.Create.Params" );
	p.Description = Env.Holidays;
	p.Days.Add ( holiday );
	Call ( "Catalogs.Holidays.Create", p );
	
	// *************************
	// Create Schedule
	// *************************

	p = Call ( "Catalogs.Schedules.Create.Params" );
	p.Description = Env.Schedule;
	p.Holidays = Env.Holidays;
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
	// Work in Holiday
	// ******************
	
	p = Call ( "Documents.Deviations.Create.Params" );
	employees = p.Employees;
	
	row = Call ( "Documents.Deviations.Create.Row" );
	row.Employee = Env.Employees [ 0 ].Name;
	row.Day = Format ( Env.HolidayDay, "DLF=D" );
	row.Duration = 4;
	row.Time = "Holiday";
	employees.Add ( row );
	
	Call ( "Documents.Deviations.Create", p );

	Call ( "Common.StampData", id );

EndProcedure
