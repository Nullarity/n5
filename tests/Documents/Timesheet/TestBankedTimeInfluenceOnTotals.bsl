Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25E080AB" );
env = getEnv ( id );
createEnv ( env );

// ************************
// Find or Create Timesheet
// ************************

Commando ( "e1cib/list/Document.Timesheet" );
With ( "Timesheets" );
if ( GotoRow ( "#List", "Memo", env.ID ) ) then
	Click ( "#FormChange" );
	isNew = false;
else
	Commando ( "e1cib/data/Document.Timesheet" );
	isNew = true;
endif;

With ( "Timesheet *" );
table = Get ( "#OneWeek" );

// ************************
// Fill Timesheet
// ************************

if ( isNew ) then
	Put ( "#Employee", Env.Employee );
	Put ( "#Memo", Env.ID );
else
	Call ( "Table.Clear", table );
	Click ( "Yes", DialogsTitle );
endif;

// Add regular hours
Click ( "#OneWeekAdd" );
Set ( "#OneWeekCustomer", env.Customer );
Set ( "#OneWeekProject", env.Project );
Set ( "#OneWeekDay2", "8" );
Set ( "#OneWeekDay3", "8" );
Set ( "#OneWeekDay4", "8" );
Set ( "#OneWeekDay5", "6" );
Set ( "#OneWeekDay6", "8" );

// Add 2, 3 and -3 banked hours
Click ( "#OneWeekAdd" );
Put ( "#OneWeekCustomer", env.Customer );
Put ( "#OneWeekProject", env.Project );
Next ();
Put ( "#OneWeekTimeType", "Banked", table );
Put ( "#OneWeekDay2", "2", table );
Put ( "#OneWeekDay3", "-3", table );
Put ( "#OneWeekDay4", "3", table );

// Add 0 hours
Click ( "#OneWeekAdd" );
Put ( "#OneWeekCustomer", env.Customer );
Put ( "#OneWeekProject", env.Project );
Next ();
Put ( "#OneWeekTimeType", "Overtime", table );

// Add 2 banked used
Click ( "#OneWeekAdd" );
Put ( "#OneWeekCustomer", env.Customer );
Put ( "#OneWeekProject", env.Project );
Next ();
Put ( "#OneWeekTimeType", "Bank Used", table );
Put ( "#OneWeekDay5", "2", table );

Click ( "#FormWrite" );

// Print and check rows
Click ( "#FormDocumentTimesheetPrintTimesheet" );
With ( "Timesheet: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = CurrentDate ();
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", date );
	p.Insert ( "Banked", Call ( "Documents.Payroll.FirstMonday", BegOfMonth ( date ) ) );
	p.Insert ( "Department", "_Department " + ID );
	p.Insert ( "Schedule", "_Schedule " + ID );
	p.Insert ( "Employee", "Employee " + ID );
	p.Insert ( "Customer", "Client " + ID );
	p.Insert ( "Project", "Project " + ID );
	p.Insert ( "HourlyRate", "_Hourly " + ID );
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
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );

	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );

	// *************************
	// Create Compensation
	// *************************
	
	mainCompensation = Env.HourlyRate;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = mainCompensation;
	p.Method = "Hourly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );

	// *************************
	// Create Schedule
	// *************************

	p = Call ( "Catalogs.Schedules.Create.Params" );
	p.Description = Env.Schedule;
	p.TimesheetPeriod = "Week";
	Call ( "Catalogs.Schedules.Create", p );
	
	// *************************
	// Hiring
	// *************************
	
	date = Env.Date;
	monthStart = Format ( BegOfMonth ( date ), "DLF=D" );
	department = Env.Department;
	schedule = Env.schedule;
	params = Call ( "Documents.Hiring.Create.Params" );
	employees = params.Employees;

	p = Call ( "Documents.Hiring.Create.Row" );
	p.Employee = Env.Employee;
	p.DateStart = monthStart;
	p.Department = department;
	p.Position = "Manager";
	p.Rate = "1000";
	p.Compensation = mainCompensation;
	p.Schedule = schedule;

	employees.Add ( p );
	
	params.Date = date;
	Call ( "Documents.Hiring.Create", params );
	
	// *************************
	// Customer
	// *************************

	customer = Env.Customer;
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );

	// *************************
	// Project
	// *************************

	p = Call ( "Catalogs.Projects.Create.Params" );
	p.Customer = customer;
	p.Description = Env.Project;
	p.DateStart = monthStart;
	p = Call ( "Catalogs.Projects.Create", p );
	
	Call ( "Common.StampData", id );

EndProcedure
