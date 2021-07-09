// - Hiring 2 employees
//  - Standard schedule with 3 holidays.
//  - First holiday is on Sunday
//  - Second holiday is on workday
//  - Third holiday is on workday in vacation period
// - Create standard payroll for January, February and March
// - Create vacation from the middle of April to May
// - Check Results

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B8A9996" );
env = getEnv ( id );
createEnv ( env );

// ********************
// Fill April Payroll
// ********************

Commando ( "e1cib/list/Document.Payroll" );
With ( "Payroll" );
GotoRow ( "#List", "Memo", id );
Click ( "#FormChange" );
form = With ( "Payroll #*" );

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
Click ( "#Ok", "Display list" );
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
	p.Insert ( "Holidays", "_Holidays " + ID );
	p.Insert ( "Schedule", "_Schedule " + ID );
	p.Insert ( "Employees", getEmployees ( p ) );
	p.Insert ( "MonthlyRate", "_Monthly " + ID );
	p.Insert ( "VacationCompensation", "_Vacation " + ID );
	
	// Two holidays in base period
	p.Insert ( "Holiday1", Date ( 2017, 01, 01 ) );
	p.Insert ( "Holiday2", Date ( 2017, 03, 31 ) );
	// One holiday in vacation period
	p.Insert ( "Holiday3", Date ( 2017, 05, 05 ) );
	
	// Vacation period
	p.Insert ( "StartVacation", "4/24/2017" );
	p.Insert ( "EndVacation", "5/5/2017" );

	return p;

EndFunction

Function getEmployees ( Env )

	id = Env.ID;
	date = Env.Date;
	dateStart = BegOfMonth ( date );
	dateEnd = Date ( 1, 1, 1 );
	
	employees = new Array ();
	employees.Add ( newEmployee ( "_Employee1 " + id, dateStart, dateEnd, 3000 ) );
	employees.Add ( newEmployee ( "_Employee2 " + id, dateStart, dateEnd, 3000 ) );
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
	// Create Holidays
	// *************************

	holidays = Env.Holidays;
	p = Call ( "Catalogs.Holidays.Create.Params" );
	p.Description = holidays;
	days = p.Days;
	holiday = Call ( "Catalogs.Holidays.Create.Day" );
	holiday.Day = Env.Holiday1;
	holiday.Title = "Some Holiday 1";
	days.Add ( holiday );
	holiday = Call ( "Catalogs.Holidays.Create.Day" );
	holiday.Day = Env.Holiday2;
	holiday.Title = "Some Holiday 2";
	days.Add ( holiday );
	holiday = Call ( "Catalogs.Holidays.Create.Day" );
	holiday.Day = Env.Holiday3;
	holiday.Title = "Some Holiday 3";
	days.Add ( holiday );
	Call ( "Catalogs.Holidays.Create", p );

	// *************************
	// Create Schedule
	// *************************

	p = Call ( "Catalogs.Schedules.Create.Params" );
	p.Description = Env.Schedule;
	p.Holidays = holidays;
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
	
	// *****************************************************
	// Create Payroll for January, February, March and April
	// *****************************************************
	
	periods = new Array ();
	periods.Add ( date );
	periods.Add ( AddMonth ( date, 1 ) );
	periods.Add ( AddMonth ( date, 2 ) );
	periods.Add ( AddMonth ( date, 3 ) );
	payrollCounter = periods.Count ();
	for each month in periods do
		payrollCounter = payrollCounter - 1;
		Commando ( "e1cib/data/Document.Payroll" );
		form = With ( "Payroll (cr*" );
		Put ( "#Period", "Month" );
		With ();
		Click ( "Yes" );
		With ( form );
		Put ( "#Period", "Month" );
		documentDate = Date ( Fetch ( "#DateStart" ) );
		direction = ? ( documentDate < month, 1, -1 );
		breaker = 1;
		while ( true ) do
			dateStart = Date ( Fetch ( "#DateStart" ) );
			if ( dateStart = month ) then
				break;
			else
				Click ( ? ( direction = 1, "#NextPeriod", "#PreviousPeriod" ) );
			endif;
			breaker = breaker + 1;
		enddo;
		if ( payrollCounter = 0 ) then
			Set ( "#Memo", id );
			Click ( "#JustSave" );
			Close ();
		else
			Click ( "#Fill" );
			With ( "Payroll: Setup Filters" );
			table = Get ( "#UserSettings" );
			GotoRow ( table, "Setting", "Department" );
			Put ( "#UserSettingsValue", env.Department, table );

			Click ( "#FormFill" );
			Pause ( __.Performance * 7 );

			With ( form );
			Click ( "#FormPostAndClose" );
		endif;
	enddo;

	// *****************************************************
	// Create Vacation
	// *****************************************************
	
	Commando ( "e1cib/command/Document.Vacation.Create" );
	With ( "Vacation (cr*" );
	
	for each employee in Env.Employees do
		Click ( "#EmployeesAdd" );
		Set ( "#EmployeesEmployee", employee.Name );
		Set ( "#EmployeesDateStart", Env.StartVacation );
		Set ( "#EmployeesDateEnd", Env.EndVacation );
		Put ( "#EmployeesCompensation", vacationCompensation );
	enddo;
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );

EndProcedure
