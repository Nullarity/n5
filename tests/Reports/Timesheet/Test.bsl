Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "284DAA6B" );
env = getEnv ( id );
createEnv ( env );

make ( "01/01/2017", "01/31/2017", env );
form = With ( "Timesheet*" );
Call ( "Common.CheckLogic", "#Result" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", "01/01/2017" );
	p.Insert ( "Year", "2017" );
	p.Insert ( "Employee", "Employee1: " + id );
	p.Insert ( "Department1", "_Department1 " + ID );
	p.Insert ( "Department2", "_Department2 " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	date = Env.Date;
	
	// *************************
	// Create Employees
	// *************************
	
	employees = new Array ();
	
	// Employee1 main work
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Employees" );
	form = With ( "Individuals (create)" );
	employee1Name = Env.Employee;
	Put ( "#FirstName", employee1Name );
	Click ( "#FormWrite" );
	employee1Main = Fetch ( "#EmployeeCode" );
	
	Close ( form );
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department1;
	Call ( "Catalogs.Departments.Create", p );
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department2;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Compensation
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	mainCompensation = "Compensation: " + id;
	p.Description = mainCompensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	vacation = "Vacation: " + id;
	p.Description = vacation;
	p.Method = "Vacation";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// *************************
	// Create Schedule
	// *************************
	
	p = Call ( "Catalogs.Schedules.Create.Params" );
	schedule = "_Schedule: " + id;
	p.Year = Env.Year;
	p.Description = schedule;
	p.MondayEvening = 1;
	p.MondayNight = 1;
	Call ( "Catalogs.Schedules.Create", p );
	
	// *************************
	// Hiring
	// *************************
	
	params = Call ( "Documents.Hiring.Create.Params" );
	addEmployee ( params, employee1Main, "Accountant", Env.Department1, mainCompensation, schedule, date, "10000" );
	params.Date = date;
	Call ( "Documents.Hiring.Create", params );
	
	// *************************
	// Transfer
	// *************************
	
	Commando ( "e1cib/data/Document.EmployeesTransfer" );
	form = With ( "Employees Transfer (create)" );
	Put ( "#Date", "01/15/2017" );
	Click ( "#EmployeesContextMenuAdd" );
	With ( "Employee" );
	Put ( "#Employee", employee1Main );
	Put ( "#Action", "Change" );
	Put ( "#Date", "01/15/2017" );
	Put ( "#Department", Env.Department2 );
	Put ( "#Position", "Manager" );
	Put ( "#Compensation", mainCompensation );
	Put ( "#Rate", "15000" );
	Click ( "#FormOK" );
	
	With ( form );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Vacation
	// *************************
	
	Commando ( "e1cib/data/Document.Vacation" );
	With ( "Vacation (create)" );
	Put ( "#Date", "01/29/2017" );
	table = Activate ( "#Employees" );
	Click ( "#EmployeesContextMenuAdd" );
	Put ( "#EmployeesEmployee", employee1Main, table );
	Put ( "#EmployeesDateStart", "01/29/2017", table );
	Put ( "#EmployeesDateEnd", "01/31/2017", table );
	Put ( "#EmployeesCompensation", vacation, table );
	
	Click ( "#FormPostAndClose" );
	
	Call ( "Common.StampData", id );
	
EndProcedure

Procedure addEmployee ( Params, Employee, Position, Department, Compensation, Schedule, Date, Rate )
	
	p = Call ( "Documents.Hiring.Create.Row" );
	p.Employee = Employee;
	p.DateStart = Date;
	p.Department = Department;
	p.Position = Position;
	p.Rate = Rate;
	p.Compensation = Compensation;
	p.Schedule = Schedule;
	p.Put = true;
	Params.Employees.Add ( p );
	
EndProcedure

Procedure make ( Date1, Date2, Env )
	
	p = Call ( "Common.Report.Params" );
	p.Path = "Employees / Timesheet";
	p.Title = "Timesheet*";
	filters = new Array ();
	
	item = Call ( "Common.Report.Filter" );
	item.Period = true;
	item.Name = "Period";
	item.ValueFrom = Date1;
	item.ValueTo = Date2;
	filters.Add ( item );
	
	item = Call ( "Common.Report.Filter" );
	item.Name = "Employee";
	item.Value = env.Employee;
	filters.Add ( item );
	
	p.Filters = filters;
	p.UseOpenMenu = false;
	Commando("e1cib/app/Report.Timesheet");
	form = With ( Call ( "Common.Report", p ) );
	
	settings = Activate ( "#UserSettings" );
	settings.GotoFirstRow ();
	
	Activate ( "#UserSettingsUse", settings );
	Click ( "#UserSettingsUse", settings );
	
	With ( form );
	Click ( "#GenerateReport" );
	
EndProcedure



