// Hire Employees
// Create Payroll Balances
// Post document
// Check records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2866588E" );
env = getEnv ( id );
createEnv ( env );

// Create Payroll Balances
Commando ( "e1cib/list/DocumentJournal.Balances" );
With ();

if ( Date ( Fetch ( "#BalanceDate" ) ) = Date ( 1, 1, 1 ) ) then
    Set ( "#BalanceDate", Format ( CurrentDate (), "DLF=D" ) );
endif;

Click ( "#FormCreateByParameterPayrollBalances" );
With ( "Payroll Balances (cr*" );

// Add Employee 1
employee = env.Employees [ 0 ];
compensation = env.MonthlyRate;
Click ( "#EmployeesAdd" );
Put ( "#EmployeesEmployee", employee.Name );
Put ( "#EmployeesCompensation", compensation );
Set ( "#EmployeesPaid", 10000 );
Set ( "#EmployeesBalance", 1000 );
Set ( "#EmployeesSocialAccrued", 1500 );
Set ( "#EmployeesSocial", 300 );
Set ( "#EmployeesMedical", 500 );
Set ( "#EmployeesIncomeTax", 1200 );

// Add Employee 1
employee = env.Employees [ 1 ];
Click ( "#EmployeesAdd" );
Put ( "#EmployeesEmployee", employee.Name );
Put ( "#EmployeesCompensation", compensation );
Set ( "#EmployeesPaid", 20000 );
Set ( "#EmployeesBalance", 2000 );
Set ( "#EmployeesSocialAccrued", 2500 );
Set ( "#EmployeesSocial", 400 );
Set ( "#EmployeesMedical", 600 );
Set ( "#EmployeesIncomeTax", 2200 );

// Post
Click ( "#FormPost" );

// Check Records
Click ( "#FormReportRecordsShow" );
CheckTemplate ( "#TabDoc", "Records: *" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = BegOfYear ( CurrentDate () );
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
	employees.Add ( newEmployee ( "_Employee1 " + id, dateStart ) );
	employees.Add ( newEmployee ( "_Employee2 " + id, dateStart ) );
	return employees;

EndFunction

Function newEmployee ( Name, DateStart )

	p = new Structure ( "Name, DateStart, DateEnd, Rate" );
	p.Name = Name;
	p.DateStart = DateStart;
	p.Rate = 1000;
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
	// Create IncomeTax
	// *************************
	
	date = Format ( BegOfMonth ( Env.Date ), "DLF=D" );;
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = "_Tax1: " + id;
	p.Method = "Income Tax";
	p.RateDate = date;
	p.Rate = 3;
	p.Account = "24010";
	base = p.Base;
	base.Add ( mainCompensation );
	Call ( "CalculationTypes.Taxes.Create", p );
	
	// *************************
	// Create Medical Insurance
	// *************************
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = "_Tax3: " + id;
	p.Method = "Medical Insurance (Employees)";
	p.RateDate = date;
	p.Rate = 4.5;
	p.Account = "24030";
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

	RegisterEnvironment ( id );

EndProcedure
