Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BE5D955" );
env = getEnv ( id );
createEnv ( env );

make ( "01/01/2019", "01/31/2019", env );
Run ( "TestJanuary" );
make ( "02/01/2019", "02/28/2019", env );
Run ( "TestFebruary" );
make ( "03/01/2019", "03/31/2019", env );
Run ( "TestMarch" );
make ( "01/01/2019", "03/31/2019", env );
Run ( "TestTotals" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", "01/01/2019" );
	p.Insert ( "Department", "_Department " + ID );
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
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Employees" );
	form = With ( "Individuals (create)" );
	employee1Name = "Employee1: " + id;
	Set ( "#FirstName", employee1Name );
	Set ( "#Code", Call ( "Common.GetID " ) );
	Click ( "Yes", "1?:*" );
	Click ( "#FormWrite" );
	employee1Main = Fetch ( "#EmployeeCode" );
	
	// *************************
	// Deductions
	// *************************
	
	With ( form );
	Click ( "Deductions", GetLinks () );
	With ( employee1Name + "*" );
	Click ( "#ListCreate" ); 
	With ( "Deductions (create)" );
 	Put ( "#Period", "01/2019" );
 	Put ( "#Deduction", "P" );
 	Click ( "#FormWriteAndClose" );
	Close ( employee1Name + "*" );
	
	// *************************
	// Create Employee
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Employees" );
	form = With ( "Individuals (create)" );
	Click ( "#FormSelectExisted" );
	With ( "Individuals" );
	GoToRow ( "#List", "Description", employee1Name );
	Click ( "#FormChoose" );
	With ( form );
	Click ( "#FormWrite" );
	employee1Second = Fetch ( "#EmployeeCode" );
	Close ( form );
	
	// *************************
	// Create Employee
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Employees" );
	form = With ( "Individuals (create)" );
	employee2Name = "Employee2: " + id;
	Set ( "#FirstName", employee2Name );
	Set ( "#Code", Call ( "Common.GetID " ) );
	Click ( "Yes", "1?:*" );
	Click ( "#FormWrite" );
	employee2 = Fetch ( "#EmployeeCode" );
	
	// *************************
	// Deductions
	// *************************
	
	With ( form );
	Click ( "Deductions", GetLinks () );
	With ( employee2Name + "*" );
	Click ( "#ListCreate" ); 
	With ( "Deductions (create)" );
 	Put ( "#Period", "01/2019" );
 	Put ( "#Deduction", "P" );
 	Click ( "#FormWriteAndClose" );
	Close ( employee2Name + "*" );
	
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
	mainCompensation = "_MonthlyRate(Main): " + id;
	p.Description = mainCompensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	secondCompensation = "_MonthlyRate(Second): " + id;
	p.Description = secondCompensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// *************************
	// Create Taxes
	// *************************
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = "_Medical(Company): " + id;
	p.Method = "Medical Insurance";
	p.RateDate = "01/2019";
	p.Rate = 4.5;
	p.Account = "5332";
	base = p.Base;
	base.Add ( mainCompensation );
	base.Add ( SecondCompensation );
	Call ( "CalculationTypes.Taxes.Create", p );
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = "_Medical(Employee): " + id;
	p.Method = "Medical Insurance (Employees)";
	p.RateDate = "01/2019";
	p.Rate = 4.5;
	p.Account = "5332";
	base = p.Base;
	base.Add ( mainCompensation );
	base.Add ( SecondCompensation );
	Call ( "CalculationTypes.Taxes.Create", p );
	
	p = Call ( "CalculationTypes.Taxes.Create.Params", );
	p.Description = "_Social(Company): " + id;
	p.Method = "Social Insurance";
	p.RateDate = "01/2019";
	p.Rate = 23;
	p.Account = "5331";
	base = p.Base;
	base.Add ( mainCompensation );
	base.Add ( SecondCompensation );
	Call ( "CalculationTypes.Taxes.Create", p );
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = "_Social(Employee): " + id;
	p.Method = "Social Insurance (Employees)";
	p.RateDate = "01/2019";
	p.Rate = 6;
	p.Account = "5331";
	base = p.Base;
	base.Add ( mainCompensation );
	base.Add ( SecondCompensation );
	Call ( "CalculationTypes.Taxes.Create", p );
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = "_Income tax: " + id;
	p.Method = "Income Tax (scale)";
	p.RateDate = "01/2019";
	p.Account = "5342";
	base = p.Base;
	base.Add ( mainCompensation );
	base.Add ( SecondCompensation );
	scale = p.Scale;
	s = Call ( "CalculationTypes.Taxes.Create.Scale" );
	s.Limit = "25000";
	s.Rate = "7";
	scale.Add ( s );
	s = Call ( "CalculationTypes.Taxes.Create.Scale" );
	s.Limit = "99999999999";
	s.Rate = "18";
	scale.Add ( s );
	Call ( "CalculationTypes.Taxes.Create", p );
	
	// *************************
	// Create Schedule
	// *************************

	p = Call ( "Catalogs.Schedules.Create.Params" );
	schedule = "_Schedule: " + id;
	p.Description = schedule;
	Call ( "Catalogs.Schedules.Create", p );

	// *************************
	// Hiring
	// *************************
	
	department = Env.Department;
	params = Call ( "Documents.Hiring.Create.Params" );
	addEmployee ( params, employee1Main, "Accountant", department, mainCompensation, schedule, date, "10000" );
	addEmployee ( params, employee1Second, "Manager", department, secondCompensation, schedule, date, 2000 );
	addEmployee ( params, employee2, "Accountant", department, mainCompensation, schedule, date, "20000" );
	params.Date = date;
	Call ( "Documents.Hiring.Create", params );
	
	// ********************
	// Create Payroll
	// ********************
	
	// first Month
	
	Commando ( "e1cib/data/Document.Payroll" );
	form = With ( "Payroll (cr*" );
	Put ( "#Date", env.Date );
	
	Click ( "#Fill" );
	
	With ( "Payroll: Setup Filters" );
    table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Department" );
	Put ( "#UserSettingsValue", env.Department, table );
	
	With ( "Payroll: Setup Filters" );
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Period" );
	Choose ( "#UserSettingsValue", table );
	
	With ( "Select period" );
	Put ( "#DateBegin", "01/01/2019" );
	Put ( "#DateEnd", "01/31/2019" );
	Click ( "#Select" );
	
	With ( "Payroll: Setup Filters" );
	Click ( "#FormFill" );
	Pause ( __.Performance * 10 );

    // ********************
	// Create Compensations
	// ********************
	
    With ( "Payroll (create) *" );
    Compensations = Get ( "#Compensations" );
    Click ( "#CompensationsAdd" );
    With ( "Compensation" );
    Put ( "#Employee", "env.Employee" );
    Set ( "#DateStart", " 1/ 1/2020" );
    Set ( "#DateEnd", " 2/ 2/2020" );
    Set ( "#Days", "23" );
    Set ( "#Hours", "184" );
    Set ( "#ScheduledDays", "23" );
    Set ( "#ScheduledHours", "184" );
    Put ( "#Schedule", "env.Schedule" );
    Put ( "#Department", "env.Department" );
    Put ( "#Position", "env.Position" );
    Put ( "#Compensation", "Compensation" );
    Set ( "#Rate", "20.00" );
    Put ( "#Currency", "MDL" );
    Put ( "#Account", "5311" );
    Put ( "#Expenses", "env.Expenses" );
    Set ( "#AccountingResult", "10,000.00" );
    Click ( "#FormOK" );

    With ( "Payroll (create) *" );
    Compensations = Get ( "#Compensations" );
    Click ( "#CompensationsAdd" );
    With ( "Compensation" );
    Put ( "#Employee", "env.Employee" );
    Set ( "#DateStart", " 1/ 1/2020" );
    Set ( "#DateEnd", " 2/ 2/2020" );
    Set ( "#Days", "23" );
    Set ( "#Hours", "184" );
    Set ( "#ScheduledDays", "23" );
    Set ( "#ScheduledHours", "184" );
    Put ( "#Schedule", "env.Schedule" );
    Put ( "#Department", "env.Department" );
    Put ( "#Position", "env.Position" );
    Put ( "#Compensation", "Compensation" );
    Set ( "#Rate", "20.00" );
    Put ( "#Currency", "MDL" );
    Put ( "#Account", "5311" );
    Put ( "#Expenses", "env.Expenses" );
    Set ( "#AccountingResult", "2,000.00" );
    Click ( "#FormOK" );

    With ( "Payroll (create) *" );
    Compensations = Get ( "#Compensations" );
    Click ( "#CompensationsAdd" );
    With ( "Compensation" );
    Put ( "#Employee", "env.Employee" );
    Set ( "#DateStart", " 1/ 1/2020" );
    Set ( "#DateEnd", " 2/ 2/2020" );
    Set ( "#Days", "23" );
    Set ( "#Hours", "184" );
    Set ( "#ScheduledDays", "23" );
    Set ( "#ScheduledHours", "184" );
    Put ( "#Schedule", "env.Schedule" );
    Put ( "#Department", "env.Department" );
    Put ( "#Position", "env.Position" );
    Put ( "#Compensation", "Compensation" );
    Set ( "#Rate", "20.00" );
    Put ( "#Currency", "MDL" );
    Put ( "#Account", "5311" );
    Put ( "#Expenses", "env.Expenses" );
    Set ( "#AccountingResult", "20,000.00" );
    Click ( "#FormOK" );


	With ( form );
	Click ( "#FormPostAndClose" );

	// ********************
	// Create PayEmployees
	// ********************

	Commando ( "e1cib/data/Document.PayEmployees" );
	form = With ( "Pay Employees (cr*" );
	Put ( "#Date", "02/01/2019" );

	Click ( "#Fill" );
	With ( "Pay: Setup Filters" );
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Department" );
	Put ( "#UserSettingsValue", env.Department, table );

	Click ( "#FormFill" );
	Pause ( __.Performance * 7 );

	With ( form );
	Click ( "#FormPostAndClose" );
	
	// Second Month
	
	Commando ( "e1cib/data/Document.Payroll" );
	form = With ( "Payroll (cr*" );
	Put ( "#Date", "02/01/2019" );
	
	Click ( "#Fill" );
	
	With ( "Payroll: Setup Filters" );
    table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Department" );
	Put ( "#UserSettingsValue", env.Department, table );
	
	With ( "Payroll: Setup Filters" );
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Period" );
	Choose ( "#UserSettingsValue", table );
	
	With ( "Select period" );
	Put ( "#DateBegin", "02/01/2019" );
	Put ( "#DateEnd", "02/28/2019" );
	Click ( "#Select" );
	
	With ( "Payroll: Setup Filters" );
	Click ( "#FormFill" );
	Pause ( __.Performance * 10 );

    // ********************
	// Create Compensations
	// ********************
	
    With ( "Payroll (create) *" );
    Compensations = Get ( "#Compensations" );
    Click ( "#CompensationsAdd" );
    With ( "Compensation" );
    Put ( "#Employee", "env.Employee" );
    Set ( "#DateStart", " 1/ 1/2020" );
    Set ( "#DateEnd", " 2/ 2/2020" );
    Set ( "#Days", "23" );
    Set ( "#Hours", "184" );
    Set ( "#ScheduledDays", "23" );
    Set ( "#ScheduledHours", "184" );
    Put ( "#Schedule", "env.Schedule" );
    Put ( "#Department", "env.Department" );
    Put ( "#Position", "env.Position" );
    Put ( "#Compensation", "Compensation" );
    Set ( "#Rate", "20.00" );
    Put ( "#Currency", "MDL" );
    Put ( "#Account", "5311" );
    Put ( "#Expenses", "env.Expenses" );
    Set ( "#AccountingResult", "10,000.00" );
    Click ( "#FormOK" );

    With ( "Payroll (create) *" );
    Compensations = Get ( "#Compensations" );
    Click ( "#CompensationsAdd" );
    With ( "Compensation" );
    Put ( "#Employee", "env.Employee" );
    Set ( "#DateStart", " 1/ 1/2020" );
    Set ( "#DateEnd", " 2/ 2/2020" );
    Set ( "#Days", "23" );
    Set ( "#Hours", "184" );
    Set ( "#ScheduledDays", "23" );
    Set ( "#ScheduledHours", "184" );
    Put ( "#Schedule", "env.Schedule" );
    Put ( "#Department", "env.Department" );
    Put ( "#Position", "env.Position" );
    Put ( "#Compensation", "Compensation" );
    Set ( "#Rate", "20.00" );
    Put ( "#Currency", "MDL" );
    Put ( "#Account", "5311" );
    Put ( "#Expenses", "env.Expenses" );
    Set ( "#AccountingResult", "2,000.00" );
    Click ( "#FormOK" );

    With ( "Payroll (create) *" );
    Compensations = Get ( "#Compensations" );
    Click ( "#CompensationsAdd" );
    With ( "Compensation" );
    Put ( "#Employee", "env.Employee" );
    Set ( "#DateStart", " 1/ 1/2020" );
    Set ( "#DateEnd", " 2/ 2/2020" );
    Set ( "#Days", "23" );
    Set ( "#Hours", "184" );
    Set ( "#ScheduledDays", "23" );
    Set ( "#ScheduledHours", "184" );
    Put ( "#Schedule", "env.Schedule" );
    Put ( "#Department", "env.Department" );
    Put ( "#Position", "env.Position" );
    Put ( "#Compensation", "Compensation" );
    Set ( "#Rate", "20.00" );
    Put ( "#Currency", "MDL" );
    Put ( "#Account", "5311" );
    Put ( "#Expenses", "env.Expenses" );
    Set ( "#AccountingResult", "20,000.00" );
    Click ( "#FormOK" );

	With ( form );
	Click ( "#FormPostAndClose" );

	// ********************
	// Create a new Pay Employees
	// ********************

	Commando ( "e1cib/data/Document.PayEmployees" );
	form = With ( "Pay Employees (cr*" );
	Put ( "#Date", "03/01/2019" );

	Click ( "#Fill" );
	With ( "Pay: Setup Filters" );
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Department" );
	Put ( "#UserSettingsValue", env.Department, table );

	Click ( "#FormFill" );
	Pause ( __.Performance * 7 );

	With ( form );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Entry (pay salary)
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = "02/10/2019";
	p.Records.Add ( row ( "5312", "2411", "5000", employee1Name ) );
	p.Records.Add ( row ( "5312", "2411", "10000", employee2Name ) );
	Call ( "Documents.Entry.Create", p );
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = "03/10/2019";
	p.Records.Add ( row ( "5312", "2411", "10000", employee1Name ) );
	p.Records.Add ( row ( "5312", "2411", "50000", employee2Name ) );
	Call ( "Documents.Entry.Create", p );
	
	RegisterEnvironment ( id );

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

Function row ( AccountDr, AccountCr, Amount, DimDr1 = undefined )

	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = AccountDr;
	row.AccountCr = AccountCr;
	row.Amount = Amount;
	row.DimDr1 = DimDr1;
	return row;

EndFunction

Procedure make ( Date1, Date2, Env )

	p = Call ( "Common.Report.Params" );
	p.Path = "e1cib/app/Report.Payroll";
	p.Title = "Payroll*";
	filters = new Array ();
	item = Call ( "Common.Report.Filter",  );
	item.Period = true;
	item.Name = "Period";
	item.ValueFrom = Date1;
	item.ValueTo = Date2;
	filters.Add ( item );
	item = Call ( "Common.Report.Filter",  );
	item.Name = "Department";
	item.Value = env.Department;
	filters.Add ( item );
	p.Filters = filters;
	Call ( "Common.Report", p );

EndProcedure

