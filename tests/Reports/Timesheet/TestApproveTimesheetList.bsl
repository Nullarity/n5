Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2D0974D8" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Open Timesheet
// *************************

MainWindow.ExecuteCommand ( "e1cib/list/Document.Timesheet" );
list = With ();
Put ( "#EmployeeFilter", Env.Employee );
table = Activate ( "#List" );
status = Fetch ( "#TimesheetStatus", table );
if ( status = "Approval Completed" ) then
	Click ( "#FormUndoPosting" );
	Click ( "#FormChange" );
	With ();
	Click ( "#FormSendForApproval" );	
	Click ( "Yes" );
endif;
With ( list );
Click ( "#FormApproveTimesheet" );
Click ( "Yes" );
Pause ( 2 );
With ( list );
Click ( "#FormReportRecordsShow" );
With ( "Records: Timesheet*" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Employee", "Employee " + ID );
	p.Insert ( "Project", "Project " + ID );
	p.Insert ( "Compensation", "Compensation " + ID );
	p.Insert ( "schedule", "schedule " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Organizations" );
	With ();
	Click ( "#Customer" );
	Put ( "#Description", Env.Customer );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Employee
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );
	
	// *************************
	// Create Compensation
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Compensation;
	p.Method = "Hourly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );

	// *************************
	// Create Schedule
	// *************************

	p = Call ( "Catalogs.Schedules.Create.Params" );
	p.Description = Env.Schedule;
	p.Year = "2018";
	p.TimesheetPeriod = "Week";
	Call ( "Catalogs.Schedules.Create", p );
	
	// *************************
	// Hiring
	// *************************
	
	params = Call ( "Documents.Hiring.Create.Params" );
	employees = params.Employees;

	p = Call ( "Documents.Hiring.Create.Row" );
	p.Employee = Env.Employee;
	p.DateStart = "01/01/2018";
	p.Department = "Administration";
	p.Position = "Manager";
	p.Rate = "1000";
	p.Compensation = Env.Compensation;
	p.Schedule = Env.schedule;
 	employees.Add ( p );
	params.Date = "01/01/2018";
	Call ( "Documents.Hiring.Create", params );
	
	// *************************
	// Set Performer
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Users" );
	With ();
	p = Call ( "Common.Find.Params" );
	p.Where = "Name";
	p.What = "admin";
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ();
	Click ( "#Settings / More" );
	Put ( "#Employee", Env.Employee );
	Click ( "#FormWriteAndClose" );
	Pause(5);
	
	// *************************
	// Create Project
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Projects" );
	With ();
	Put ( "#Owner", Env.Customer );
	Put ( "#Manager", Env.Employee );
	Put ( "#DateStart", "01/01/2018" );
	Click ( "#UseApprovingProcess" );
	Put ( "#Description", Env.Project );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Time Entry
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/data/Document.TimeEntry" );
	With ();
	Put ( "#Customer", Env.Customer );
	Put ( "#Project", Env.Project );
	Put ( "#Date", "01/07/2018" );
	Next ();
	table = Activate ( "#Tasks" );
	Put ( "#TasksTimeStart", "01:00", table );
	Next ();
	Put ( "#TasksTimeEnd", "02:00", table );
	Put ( "#TasksTask", "Consulting", table );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Timesheet
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/list/Document.Timesheet" );
	With ();
	Put ( "#EmployeeFilter", Env.Employee );
	Click ( "#FormCreate" );
	With ();
	
	date = "1/7/2018 12:00:00 AM";
	while ( true ) do
		if ( Fetch ( "#DateStart" ) = date ) then
			break;
		else
			Click ( "#PreviousPeriod" );
		endif;
	enddo;
	Click ( "#FormSendForApproval" );
	Click ( "Yes" );
	
	RegisterEnvironment ( id );

EndProcedure
