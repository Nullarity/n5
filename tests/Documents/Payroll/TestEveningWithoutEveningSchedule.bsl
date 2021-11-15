Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "284ABD6A" );
env = getEnv ( id );
createEnv ( env );

// ********************
// Create a new Payroll
// ********************

Commando ( "e1cib/data/Document.Payroll" );
form = With ( "Payroll (cr*" );

Click ( "#Fill" );
With ( "Payroll: Setup Filters" );
table = Get ( "#UserSettings" );
GotoRow ( table, "Setting", "Department" );
Put ( "#UserSettingsValue", env.Department, table );

Click ( "#FormFill" );
Pause ( __.Performance * 7 );

With ( form );

Check ( "#Compensations / Result [ 1 ]", 1000 );
Check ( "#Compensations / Result [ 2 ]", 87.5 );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", CurrentDate () );
	p.Insert ( "Department", "_Department " + ID );
	p.Insert ( "Schedule", "_Schedule " + ID );
	p.Insert ( "Employees", getEmployees ( p ) );
	p.Insert ( "MonthlyRate", "_Monthly " + ID );
	p.Insert ( "Evening", "_Evening " + ID );
	p.Insert ( "Night", "_Night " + ID );
	return p;

EndFunction

Function getEmployees ( Env )

	id = Env.ID;
	date = Env.Date;
	dateStart = BegOfMonth ( date );
	dateEnd = Date ( 1, 1, 1 );
	
	employees = new Array ();
	employees.Add ( newEmployee ( "_Employee1 " + id, dateStart, dateEnd, 1000 ) );
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
	// Create Evening & Night hours
	// ****************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Evening;
	p.Method = "Evening Hours";
	Call ( "CalculationTypes.Compensations.Create", p );

	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Night;
	p.Method = "Night Hours";
	Call ( "CalculationTypes.Compensations.Create", p );

	// *************************
	// Create Schedule
	// *************************

	p = Call ( "Catalogs.Schedules.Create.Params" );
	p.Description = Env.Schedule;
	p.Monday = 8;
	p.MondayNight = 2;
	p.Tuesday = 8;
	p.TuesdayNight = 2;
	p.Wednesday = 8;
	p.WednesdayNight = 2;
	p.Thursday = 8;
	p.ThursdayNight = 2;
	p.Friday = 8;
	p.FridayNight = 2;
	Call ( "Catalogs.Schedules.Create", p );
	
	// *************************
	// Hiring
	// *************************
	
	department = Env.Department;
	monthlyRate = Env.MonthlyRate;
	schedule = Env.schedule;
	evening = Env.Evening;
	eveningPercent = 20;
	night = Env.Night;
	nightPercent = 35;
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
		p.Compensation = monthlyRate;
		p.Schedule = schedule;
		
		// Evening
		addons = p.RowsAdditions;
		additional = Call ( "Documents.Hiring.Create.RowAdditional" );
		additional.Compensation = evening;
		additional.Rate = eveningPercent;
		addons.Add ( additional );

		// Night
		additional = Call ( "Documents.Hiring.Create.RowAdditional" );
		additional.Compensation = night;
		additional.Rate = nightPercent;
		addons.Add ( additional );

		employees.Add ( p );
	enddo;
	params.Date = Env.Date;
	Call ( "Documents.Hiring.Create", params );

	RegisterEnvironment ( id );

EndProcedure
