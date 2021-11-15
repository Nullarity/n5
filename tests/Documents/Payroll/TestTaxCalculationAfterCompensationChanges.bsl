Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2871FFB2" );
env = getEnv ( id );
createEnv ( env );

// Open and unpost payroll
Commando ( "e1cib/list/Document.Payroll" );
With ( "Payroll" );
GotoRow ( "#List", "Memo", env.ID );
//Click ( "#ListContextMenuUndoPosting" );
Click ( "#FormChange" );
form = With ( "Payroll #*" );
Click ( "#FormUndoPosting" );
// Change salary
GotoRow ( "#Compensations", "#", 1 );
Click ( "#CompensationsEdit" );

// Change Result
With ();
if ( Fetch ( "#Edit" ) = "No" ) then
	Click ( "#Edit" );
endif;
changedCompensation = Int ( env.Employees [ 0 ].Rate / 2 );
Set ( "#Result", changedCompensation );
Set ( "#AccountingResult", changedCompensation );
Click ( "#FormOK" );

// Recalc taxes, post document
With ( form );
Click ( "#CalculateTaxes1" );
Click ( "Yes", DialogsTitle );
Pause ( __.Performance * 7 );
Click ( "#FormPost" );

// Check records
Click ( "#FormReportRecordsShow" );
With ( "Records: Payroll *" );
Call ( "Common.CheckLogic", "#TabDoc" );

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
	employees.Add ( newEmployee ( "_Employee1 " + id, dateStart, dateEnd, 1000 ) );
	employees.Add ( newEmployee ( "_Employee2 " + id, dateStart, dateEnd, 1000 ) );
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
	// Create Tax1
	// *************************
	
	date = Format ( BegOfMonth ( Env.Date ), "DLF=D" );;
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = "_Tax1: " + id;
	p.Method = "Percent";
	p.RateDate = date;
	p.Rate = 3;
	p.Account = "5331";
	base = p.Base;
	base.Add ( mainCompensation );
	Call ( "CalculationTypes.Taxes.Create", p );
	
	// *************************
	// Create Tax2
	// *************************
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = "_Tax2: " + id;
	p.Method = "Social Insurance (Employees)";
	p.RateDate = date;
	p.Rate = 4.5;
	p.Account = "5331";
	base = p.Base;
	base.Add ( mainCompensation );
	Call ( "CalculationTypes.Taxes.Create", p );

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
	
	documentDate = Date ( Fetch ( "#DateStart" ) );
	date = BegOfMonth ( Env.Date );
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
	Pause ( __.Performance * 10 );
	With ( form );
	Set ( "#Memo", id );
	
	rows = Call ( "Table.Count", Get ( "#Compensations" ) );
	if ( rows <> 2 ) then
		Stop ( "Table <Calculations> must have 2 rows.
		|The table has: " + rows + " rows" );
	endif;
	
	Click ( "#FormPost" );	
	CheckErrors ();
	
	Close ();
	
	RegisterEnvironment ( id );

EndProcedure
