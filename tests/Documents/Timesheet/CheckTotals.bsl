// Scenario:
// - Hire an employee, billing period: one week
// - Create project
// - Open timesheets
// - Create, fill, save & close timesheet
// - Check totals from the list

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2867D2FB" );
env = getEnv ( id );
createEnv ( env );

// ************************************
// Create, fill, save & close timesheet
// ************************************

Commando ( "e1cib/list/Document.Timesheet" );
list = With ( "Timesheets" );
Click ( "#FormCreate" );
With ( "Timesheet (cr*" );

Put ( "#Employee", env.Employee );

// Regular time
table = Get ( "#OneWeek" );
Click ( "#OneWeekAdd" );
table.EndEditRow ();
Put ( "#OneWeekCustomer", __.Company, table );
Put ( "#OneWeekProject", env.Project, table );
Set ( "#OneWeekDay2", "8", table ); // Monday
Set ( "#OneWeekDay3", "8", table ); // Tuesday
Set ( "#OneWeekDay4", "8", table ); // Wednesday
Set ( "#OneWeekDay5", "4", table ); // Thursday
Set ( "#OneWeekDay6", "6", table ); // Friday

// Banked time "+"
Click ( "#OneWeekAdd" );
table.EndEditRow ();
Put ( "#OneWeekCustomer", __.Company, table );
Put ( "#OneWeekProject", env.Project, table );
Put ( "#OneWeekTimeType", "Banked", table );
Set ( "#OneWeekDay2", "1", table ); // Monday
Set ( "#OneWeekDay3", "1", table ); // Tuesday
Set ( "#OneWeekDay4", "2", table ); // Wednesday

// Banked time "-"
Click ( "#OneWeekAdd" );
table.EndEditRow ();
Put ( "#OneWeekCustomer", __.Company, table );
Put ( "#OneWeekProject", env.Project, table );
Set ( "#OneWeekTimeType", "Bank Used", table );
Set ( "#OneWeekDay5", "4", table ); // Thursday
Set ( "#OneWeekDay6", "2", table ); // Friday

Click ( "#FormWrite" );
Close ();

// Check hours
With ( list );
Put ( "#EmployeeFilter", env.Employee );
Check ( "Hours", "40:00", Get ( "#List" ) );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", CurrentDate () );
	p.Insert ( "Employee", "Employee " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Schedule", "Schedule " + ID );
	p.Insert ( "Project", "Project " + ID );
	p.Insert ( "Compensation", "Hourly Rate " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Schedule
	// *************************

	p = Call ( "Catalogs.Schedules.Create.Params" );
	p.Description = Env.Schedule;
	p.TimesheetPeriod = "Week";
	Call ( "Catalogs.Schedules.Create", p );

	// ***************
	// Create Employee
	// ***************
	
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
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Compensation;
	p.Method = "Hourly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );

	// *************************
	// Hiring
	// *************************
	
	params = Call ( "Documents.Hiring.Create.Params" );
	p = Call ( "Documents.Hiring.Create.Row" );
	p.Employee = Env.Employee;
	startYear = BegOfYear ( Env.Date );
	p.DateStart = Format ( startYear, "DLF=D" );
	p.Department = Env.Department;
	p.Position = "Manager";
	p.Schedule = Env.Schedule;
	p.Rate = 150;
	p.Compensation = Env.Compensation;
	params.Employees.Add ( p );
	params.Date = Env.Date;
	Call ( "Documents.Hiring.Create", params );

	// ***************
	// Create Project
	// ***************
	
	p = Call ( "Catalogs.Projects.Create.Params" );
	p.Customer = __.Company;
	p.Description = Env.Project;
	p.DateStart = startYear;
	Call ( "Catalogs.Projects.Create", p );

	Call ( "Common.StampData", id );

EndProcedure
