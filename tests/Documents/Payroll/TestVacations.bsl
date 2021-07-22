// - Hiring 4 employees
// - Create payroll for January
// - Create payroll for February
// - Create payroll for March
// - Create vacations for April and May
// - Create payroll for April
// - Create payroll for May
// - Check Results

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BDCCF53" );
env = getEnv ( id );
createEnv ( env );

// ********************
// Create May Payroll
// ********************

Commando ( "e1cib/data/Document.Payroll" );
form = With ( "Payroll (cr*" );
Set ( "#Period", "Other" );
Click ( "Yes", Forms.Get1C () );
Set ( "#DateStart", "05/01/2019" );
Set ( "#DateEnd", "05/30/2019" );
Click ( "#Fill" );
With ( "Payroll: Setup Filters" );
table = Get ( "#UserSettings" );
GotoRow ( table, "Setting", "Department" );
Put ( "#UserSettingsValue", env.Department, table );
Click ( "#FormFill" );
Pause ( __.Performance * 5 );
With ( form );

// ********************
// Check Results
// ********************

Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Payroll *" );
Call ( "Common.CheckLogic", "#TabDoc" );
Close ();
With ();
Click ( "#FormUndoPosting" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = Date ( 2019, 01, 01 );
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", date );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Manager", "Manager " + ID );
	p.Insert ( "Holidays", "Holidays " + ID );
	p.Insert ( "Schedule", "Schedule " + ID );
	p.Insert ( "Employees", getEmployees ( p ) );
	p.Insert ( "Compensation", "Monthly " + ID );
	p.Insert ( "VacationCompensation", "Vacation " + ID );
	p.Insert ( "QuarterlyCompensation", "Quarterly " + ID );
	p.Insert ( "AnnualCompensation", "Annual " + ID );
	p.Insert ( "SocialInsurance", "Social Insurance " + ID );
	p.Insert ( "Vacations", getVacations ( p ) );	
	return p;

EndFunction

Function getEmployees ( Env )

	id = Env.ID;
	date = Env.Date;
	dateStart = BegOfMonth ( date );
	dateEnd = Date ( 1, 1, 1 );
	employees = new Array ();
	employees.Add ( getEmployee ( "Employee_1 " + id, dateStart, dateEnd, 7000 ) );
	employees.Add ( getEmployee ( "Employee_2 " + id, dateStart, dateEnd, 8000 ) );
	employees.Add ( getEmployee ( "Employee_3 " + id, dateStart, dateEnd, 9000 ) );
	employees.Add ( getEmployee ( "Employee_4 " + id, dateStart, dateEnd, 10000 ) );
	return employees;

EndFunction

Function getEmployee ( Name, DateStart, DateEnd, Rate )

	p = new Structure ( "Name, DateStart, DateEnd, Rate" );
	p.Name = Name;
	p.DateStart = DateStart;
	p.DateEnd = DateEnd;
	p.Rate = Rate;
	return p;

EndFunction

Function getVacations ( Env )
	
	id = Env.ID;
	vacations = new Array ();
	vacations.Add ( getVacation ( "Employee_1 " + id, "05/15/2019", "06/12/2019" ) );
	vacations.Add ( getVacation ( "Employee_2 " + id, "04/10/2019", "05/08/2019" ) );
	vacations.Add ( getVacation ( "Employee_3 " + id, "05/01/2019", "05/15/2019" ) );
	return vacations;

EndFunction

Function getVacation ( Employee, DateStart, DateEnd )

	p = new Structure ( "Employee, DateStart, DateEnd" );
	p.Employee = Employee;
	p.DateStart = DateStart;
	p.DateEnd = DateEnd;
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
	// Create Position
	// *************************

	p = Call ( "Catalogs.Positions.Create.Params" );
	p.Description = env.Manager;
	Call ( "Catalogs.Positions.Create", p );

	// *************************
	// Create Compensation
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Compensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// *************************
	// Create Quarterly Compensation
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.QuarterlyCompensation;
	p.Method = "Quarterly";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// *************************
	// Create Annual Compensation
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.AnnualCompensation;
	p.Method = "Annual";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// *****************************************************
	// Create Social Insurance
	// *****************************************************
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = Env.SocialInsurance;
	p.Method = "Social Insurance";
	p.Account = "5331";
	Call ( "CalculationTypes.Taxes.Create", p );
	
	// ****************************
	// Create Vacation Compensation
	// ****************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.VacationCompensation;
	p.Method = "Vacation";
	p.Base.Add ( Env.Compensation );
	p.Base.Add ( Env.QuarterlyCompensation );
	p.Base.Add ( Env.AnnualCompensation );
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// *************************
	// Create Holidays
	// *************************

	holidays = Env.Holidays;
	p = Call ( "Catalogs.Holidays.Create.Params" );
	p.Description = holidays;
	days = p.Days;
	holiday = Call ( "Catalogs.Holidays.Create.Day" );
	holiday.Day = Date ( 2019, 1, 1 );
	holiday.Title = "Some Holiday 1";
	days.Add ( holiday );
	holiday = Call ( "Catalogs.Holidays.Create.Day" );
	holiday.Day = Date ( 2019, 3, 8 );
	holiday.Title = "Some Holiday 2";
	days.Add ( holiday );
	holiday = Call ( "Catalogs.Holidays.Create.Day" );
	holiday.Day = Date ( 2019, 5, 1 );
	holiday.Title = "Some Holiday 3";
	days.Add ( holiday );
	Call ( "Catalogs.Holidays.Create", p );
	
	// *************************
	// Create Schedule
	// *************************

	p = Call ( "Catalogs.Schedules.Create.Params" );
	p.Description = Env.Schedule;
	p.Year = "2019";
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
		p.Position = Env.Manager;
		p.Rate = employee.Rate;
		p.Compensation = Env.Compensation;
		p.Schedule = schedule;
		employees.Add ( p );
	enddo;
	
	date = Env.Date;
	params.Date = date;
	Call ( "Documents.Hiring.Create", params );
	
	// *****************************************************
	// Create Vacations
	// *****************************************************
	
	Commando ( "e1cib/command/Document.Vacation.Create" );
	With ( "Vacation (cr*" );
	for each vacation in Env.Vacations do
		Click ( "#EmployeesAdd" );
		Set ( "#EmployeesEmployee", vacation.Employee );
		Set ( "#EmployeesDateStart", vacation.DateStart );
		Set ( "#EmployeesDateEnd", vacation.DateEnd );
		Put ( "#EmployeesCompensation", Env.VacationCompensation );
	enddo;
	Click ( "#FormPostAndClose" );
	
	// *****************************************************
	// Create Payroll for January
	// *****************************************************
	
	Commando ( "e1cib/data/Document.Payroll" );
	form = With ( "Payroll (cr*" );
	Set ( "#Period", "Other" );
	Click ( "Yes", Forms.Get1C () );
	Set ( "#DateStart", "01/01/2019" );
	Set ( "#DateEnd", "01/31/2019" );
	Click ( "#Fill" );
	With ( "Payroll: Setup Filters" );
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Department" );
	Put ( "#UserSettingsValue", env.Department, table );
	Click ( "#FormFill" );
	Pause ( __.Performance * 5 );
	With ( form );
	Click ( "#FormPostAndClose" );
	
	// *****************************************************
	// Create Payroll for February
	// *****************************************************
	
	Commando ( "e1cib/data/Document.Payroll" );
	form = With ( "Payroll (cr*" );
	Set ( "#Period", "Other" );
	Click ( "Yes", Forms.Get1C () );
	Set ( "#DateStart", "02/01/2019" );
	Set ( "#DateEnd", "02/28/2019" );
	Click ( "#Fill" );
	With ( "Payroll: Setup Filters" );
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Department" );
	Put ( "#UserSettingsValue", env.Department, table );
	Click ( "#FormFill" );
	Pause ( __.Performance * 5 );
	With ( form );
	Click ( "#CompensationsAdd" );
	With ( "Compensation" );
	Set ( "#Employee", env.Employees [ 0 ].Name );
	Set ( "#DateStart", "02/01/2019" );
	Set ( "#DateEnd", "02/28/2019" );
	Set ( "#Department", env.Department );
	Set ( "#Position", env.Manager );
	Set ( "#Compensation", Env.AnnualCompensation );
	Set ( "#Schedule", Env.Schedule );
	Set ( "#Currency", "MDL" );
	Set ( "#Account", "5311" );
	Set ( "#Result", 12000 );
	Set ( "#AccountingResult", 12000 );
	Click ( "#FormOK" );
	With ( form );
	Click ( "#FormPostAndClose" );
	
	// *****************************************************
	// Create Payroll for March
	// *****************************************************
	
	Commando ( "e1cib/data/Document.Payroll" );
	form = With ( "Payroll (cr*" );
	Set ( "#Period", "Other" );
	Click ( "Yes", Forms.Get1C () );
	Set ( "#DateStart", "03/01/2019" );
	Set ( "#DateEnd", "03/31/2019" );
	Click ( "#Fill" );
	With ( "Payroll: Setup Filters" );
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Department" );
	Put ( "#UserSettingsValue", env.Department, table );
	Click ( "#FormFill" );
	Pause ( __.Performance * 5 );
	With ( form );
	Click ( "#CompensationsAdd" );
	With ( "Compensation" );
	Set ( "#Employee", env.Employees [ 1 ].Name );
	Set ( "#DateStart", "03/01/2019" );
	Set ( "#DateEnd", "03/31/2019" );
	Set ( "#Department", env.Department );
	Set ( "#Position", env.Manager );
	Set ( "#Compensation", Env.QuarterlyCompensation );
	Set ( "#Schedule", Env.Schedule );
	Set ( "#Currency", "MDL" );
	Set ( "#Account", "5311" );
	Set ( "#Result", 3000 );
	Set ( "#AccountingResult", 3000 );
	Click ( "#FormOK" );
	With ( form );
	Click ( "#FormPostAndClose" );
	
	// *****************************************************
	// Create Payroll for April
	// *****************************************************
	
	Commando ( "e1cib/data/Document.Payroll" );
	form = With ( "Payroll (cr*" );
	Set ( "#Period", "Other" );
	Click ( "Yes", Forms.Get1C () );
	Set ( "#DateStart", "04/01/2019" );
	Set ( "#DateEnd", "04/30/2019" );
	Click ( "#Fill" );
	With ( "Payroll: Setup Filters" );
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Department" );
	Put ( "#UserSettingsValue", env.Department, table );
	Click ( "#FormFill" );
	Pause ( __.Performance * 5 );
	With ( form );
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );

EndProcedure
