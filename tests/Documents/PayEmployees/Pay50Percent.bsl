﻿Call ( "Common.Init" );
CloseAll ();


id = Call ( "Common.ScenarioID", "28CE4438" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create a new PayEmployees
// *************************

Commando ( "e1cib/data/Document.PayEmployees" );
form = With ( "Pay Employees (cr*" );

Click ( "#Fill" );
With ( "Pay: Setup Filters" );
table = Get ( "#UserSettings" );
GotoRow ( table, "Setting", "Department" );
Put ( "#UserSettingsValue", env.Department, table );
GotoRow ( table, "Setting", "Payment Percent" );
Put ( "#UserSettingsValue", 50, table );

Click ( "#FormFill" );
Pause ( __.Performance * 7 );

With ( form );

// Check results
Check ( "#Totals / Amount [ 1 ]", 5000 );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = CurrentDate ();
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", date );
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
	employees.Add ( newEmployee ( "_Employee1 " + id, dateStart, dateEnd, 10000 ) );
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

	// ********************
	// Create a new Payroll
	// ********************

	Commando ( "e1cib/data/Document.Payroll" );
	form = With ( "Payroll (cr*" );

	dateStart = BegOfMonth ( Fetch ( "#DateStart" ) );
	begOfMonthDate = BegOfMonth ( date );
	if ( dateStart <> begOfMonthDate ) then
		if ( dateStart > begOfMonthDate ) then
			button = "#PreviousPeriod";
		else
			button = "#NextPeriod";
		endif;
		while ( BegOfMonth ( Fetch ( "#DateStart" ) ) <> begOfMonthDate ) do
			Click ( button );	
		enddo;
	endif;
	
	Click ( "#Fill" );
	With ( "Payroll: Setup Filters" );
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Department" );
	Put ( "#UserSettingsValue", env.Department, table );

	Click ( "#FormFill" );
	Pause ( __.Performance * 7 );

	With ( form );
	Set ( "#Date", date );
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );

EndProcedure
