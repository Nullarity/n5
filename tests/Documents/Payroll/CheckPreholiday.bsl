// Check if payroll takes into account pre-holidays

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A05W" );
env = getEnv ( id );
createEnv ( env );

#region createPayroll
Call("Documents.Payroll.ListByMemo", id);
With();
if (Call("Table.Count", Get("#List"))) then
	Click("#FormChange");
	With();
else
	Commando ( "e1cib/command/Document.Payroll.Create" );
	documentDate = Date ( Fetch ( "#DateStart" ) );
	date = Call("Common.ToDate", env.Date);
	direction = ? ( documentDate < date, 1, -1 );
	breaker = 1;
	while ( breaker < 200 ) do
		dateStart = Date ( Fetch ( "#DateStart" ) );
		if ( dateStart = date ) then
			break;
		else
			Click ( ? ( direction = 1, "#NextPeriod", "#PreviousPeriod" ) );
		endif;
		breaker = breaker + 1;
	enddo;
	Set("#Memo", id);
	Click("#JustSave");
endif;

Click ( "#Fill" );
With ( "Payroll: Setup Filters" );
table = Get ( "#UserSettings" );
GotoRow ( table, "Setting", "Department" );
Put ( "#UserSettingsValue", env.Department, table );
Click ( "#FormFill" );
Pause(3 * __.Performance);
With();
Activate("#Compensations");
Check("#Compensations / #CompensationsResult [1]", 10000); // Amount should not be changed
Check("#Compensations / #CompensationsHours [1]", 167); // 168-1 preholiday hour

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", "1/01/2017" );
	p.Insert ( "Year", "2017" );
	p.Insert ( "Employee", "Employee1: " + id );
	p.Insert ( "Department", "_Department " + ID );
	p.Insert ( "Holidays", "Holidays " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	date = Env.Date;
	
	// *************************
	// Create Employee
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
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Compensation
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	mainCompensation = "Compensation: " + id;
	p.Description = mainCompensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// **************************
	// Create Holidays & Schedule
	// **************************
	
	holidays = Env.Holidays;
	p = Call ( "Catalogs.Holidays.Create.Params" );
	p.Description = holidays;
	days = p.Days;
	holiday = Call ( "Catalogs.Holidays.Create.Day" );
	holiday.Day = Date ( 2017, 1, 4 );
	holiday.Title = "Some Holiday 1";
	days.Add ( holiday );
	holiday = Call ( "Catalogs.Holidays.Create.Day" );
	holiday.Day = Date ( 2017, 1, 7 );
	holiday.Title = "Some Holiday 2";
	days.Add ( holiday );
	Call ( "Catalogs.Holidays.Create", p );

	p = Call ( "Catalogs.Schedules.Create.Params" );
	schedule = "_Schedule: " + id;
	p.Year = Env.Year;
	p.Description = schedule;
	p.MondayEvening = 1;
	p.MondayNight = 1;
	p.Holidays = holidays;
	Call ( "Catalogs.Schedules.Create", p );
	
	// *************************
	// Hiring
	// *************************
	
	params = Call ( "Documents.Hiring.Create.Params" );
	addEmployee ( params, employee1Main, "Accountant", Env.Department, mainCompensation, schedule, date, "10000" );
	params.Date = date;
	Call ( "Documents.Hiring.Create", params );
	
	RegisterEnvironment(id);
	
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



