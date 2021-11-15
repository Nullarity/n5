Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BD9DA18" );
env = getEnv ( id );
createEnv ( env );

p = Call ( "Common.Report.Params" );
p.Path = "Employees / Personal Card";
p.Title = "Personal Card";
item = Call ( "Common.Report.Filter" );
item.Name = "Year";
item.Value = "2017";
p.Filters.Add ( item );
item = Call ( "Common.Report.Filter" );
item.Name = "Employee";
item.Value = Env.Employee;
p.Filters.Add ( item );
Call ( "Common.Report", p );
	
form = With ( "Personal Card" );
Call ( "Common.CheckLogic", "#Result" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", "01/01/2017" );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Compensation", "Compensation " + ID );
	p.Insert ( "Expenses", "Expenses " + ID );
	p.Insert ( "Schedule", "Schedule " + ID );
	p.Insert ( "Employee", "Employee " + ID );
	p.Insert ( "Address", "Address " + ID );
	p.Insert ( "Position", "Accountant" );
	p.Insert ( "Rate", "10000" );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Employee
	// *************************
	
	employee = createEmployee ( Env );
	
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
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// *************************
	// Create Expenses
	// *************************
	
	Call ( "Catalogs.Expenses.Create", Env.Expenses );
	
	// *************************
	// Create Taxes
	// *************************
	
	createTax ( Env, "Medical(Company) " + id, "Medical Insurance", "5332", Env.Compensation, "01/2017", "4.5" );
	createTax ( Env, "Medical(Employee) " + id, "Medical Insurance (Employees)", "5332", Env.Compensation, "01/2017", "4.5" );
	createTax ( Env, "Social(Company) " + id, "Social Insurance", "5331", Env.Compensation, "01/2017", "23" );
	createTax ( Env, "Social(Employee) " + id, "Social Insurance (Employees)", "5331", Env.Compensation, "01/2017", "6" );
	createTax ( Env, "Income tax " + id, "Income Tax (scale)", "5342", Env.Compensation, "01/2017" );
	
	// *************************
	// Create Schedule
	// *************************

	p = Call ( "Catalogs.Schedules.Create.Params" );
	p.Description = Env.Schedule;
	p.Year = "2017";
	Call ( "Catalogs.Schedules.Create", p );

	// *************************
	// Hiring
	// *************************
	
	createHire ( Env, employee, Env.Date );
	
	// ********************
	// Create Payroll
	// ********************
	
	Commando ( "e1cib/data/Document.Payroll" );
	form = With ( "Payroll (cr*" );
	Put ( "#Date", "01/01/2017" );
	fillPayroll ( form, Env.Department, "01/01/2017", "01/31/2017" );
	Click ( "#FormPostAndClose" );

	// ********************
	// Create PayEmployees
	// ********************

	Commando ( "e1cib/data/Document.PayEmployees" );
	form = With ( "Pay Employees (cr*" );
	Put ( "#Date", "02/01/2017" );
	Put ( "#Method", "Calculation Only" );
	fillPayEmployees ( form, Env.Department );
	Click ( "#FormPostAndClose" );
	
	// ********************
	// Create Payroll
	// ********************
	
	Commando ( "e1cib/data/Document.Payroll" );
	form = With ( "Payroll (cr*" );
	Put ( "#Date", "02/01/2017" );
	fillPayroll ( form, Env.Department, "02/01/2017", "02/28/2017" );
	Click ( "#FormPostAndClose" );

	// ********************
	// Create PayEmployees
	// ********************

	Commando ( "e1cib/data/Document.PayEmployees" );
	form = With ( "Pay Employees (cr*" );
	Put ( "#Date", "03/01/2017" );
	Put ( "#Method", "Calculation Only" );
	fillPayEmployees ( form, Env.Department );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Termination
	// *************************

	Commando ( "e1cib/command/Document.Termination.Create" );
	With ( "Termination (cr*" );
	Put ( "#Date", "03/02/2017" );
	Click ( "#EmployeesAdd" );
	Set ( "#EmployeesEmployee", Env.Employee );
	Set ( "#EmployeesDate", "03/02/2017" );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Create Existed Employee
	// *************************
	
	employee = createEmployee ( Env, true );
	
	// *************************
	// Hiring
	// *************************
	
	createHire ( Env, employee, "04/01/2017" );
	
	// ********************
	// Create Payroll
	// ********************
	
	Commando ( "e1cib/data/Document.Payroll" );
	form = With ( "Payroll (cr*" );
	Put ( "#Date", "04/01/2017" );
	fillPayroll ( form, Env.Department, "04/01/2017", "04/30/2017" );
	Click ( "#FormPostAndClose" );

	// ********************
	// Create Pay Employees
	// ********************

	Commando ( "e1cib/data/Document.PayEmployees" );
	form = With ( "Pay Employees (cr*" );
	Put ( "#Date", "05/01/2017" );
	Put ( "#Method", "Calculation Only" );
	fillPayEmployees ( form, Env.Department );
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );

EndProcedure

Function createEmployee ( Env, SelectExisted = false )

	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Employees" );
	form = With ( "Individuals (create)" );
	if ( SelectExisted ) then
		Click ( "#FormSelectExisted" );
		With ( "Individuals" );
		GoToRow ( "#List", "Description", Env.Employee );
		Click ( "#FormChoose" );
		With ( form );
		Click ( "#FormWrite" );
	else
		Put ( "#FirstName", Env.Employee );
		Put ( "#PIN", "555666555" );
		Click ( "#FormWrite" );
		createAddreses ( Env );	
		createDeductions ( Env );
		createStatus ( Env );	
	endif;
	With ( Env.Employee + "*" );
	Click ( "Main", GetLinks () );
	With ( Env.Employee + "*" );
	code = Fetch ( "#EmployeeCode" );		
	Close ( Env.Employee + "*" );
	return code;

EndFunction

Procedure createAddreses ( Env )
	
	With ( Env.Employee + "*" );
	Click ( "Addresses", GetLinks () );
	
	With ( Env.Employee + "*" );
	Click ( "#FormCreate" );
	 
	With ( "Addresses (create)" );
	Click ( "#Manual" );
	Put ( "#Address", Env.Address );
	Click ( "#FormWriteAndClose" );
	
	With ( Env.Employee + "*" );
	Click ( "Main", GetLinks () );
	
	With ( Env.Employee + "*" );
	Put ( "#Address", Env.Address );
	Click ( "#FormWrite" );

EndProcedure

Procedure createDeductions ( Env )
	
	With ( Env.Employee + "*" );
	Click ( "Deductions", GetLinks () );
	
	With ( Env.Employee + "*" );
	Click ( "#ListCreate" );
	 
	With ( "Deductions (create)" );
 	Put ( "#Period", "01/2017" );
 	Put ( "#Deduction", "P" );
 	Click ( "#FormWriteAndClose" );
 	
 	With ( Env.Employee + "*" );
	Click ( "#UnusedDeductionsContextMenuCreate" );
	
	With ( "Unused Deductions (create)" );
	Put ( "#Year", "2016" );
	Put ( "#Amount", "1000" );
	Click ( "#FormWriteAndClose" );		

EndProcedure

Procedure createStatus ( Env )

	With ( Env.Employee + "*" );
 	Click ( "Status", GetLinks () );
 	
 	With ( Env.Employee + "*" );
	Click ( "#FormCreate" );
	 
	With ( "Marital Statuses (create)" );
	Put ( "#Period", "05/20/2017" );
	Put ( "#Status", "Married" );
	Put ( "#PIN", "SpousePIN" );
	Click ( "#FormWriteAndClose" );

EndProcedure

Procedure createTax ( Env, Description, Method, Account, Compensation, RateDate, Rate = undefined )

	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = Description;
	p.Method = Method;
	p.Account = Account;
	p.RateDate = RateDate;
	base = p.Base;
	base.Add ( Compensation );
	if ( Method = "Income Tax (scale)" ) then
		scale = p.Scale;
		s = Call ( "CalculationTypes.Taxes.Create.Scale" );
		s.Limit = "25000";
		s.Rate = "7";
		scale.Add ( s );
		s = Call ( "CalculationTypes.Taxes.Create.Scale" );
		s.Limit = "99999999999";
		s.Rate = "18";
		scale.Add ( s );
	else
		p.Rate = Rate;
	endif;
	Call ( "CalculationTypes.Taxes.Create", p );	

EndProcedure

Procedure fillPayroll ( Form, Department, DateBegin, DateEnd )
	
	With ( Form );
	Click ( "#Fill" );

	With ( "Payroll: Setup Filters" );
    table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Department" );
	Put ( "#UserSettingsValue", Department, table );
	
	With ( "Payroll: Setup Filters" );
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Period" );
	Choose ( "#UserSettingsValue", table );
	With ( "Select period" );
	Put ( "#DateBegin", DateBegin );
	Put ( "#DateEnd", DateEnd );
	Click ( "#Select" );
	
	With ( "Payroll: Setup Filters" );
	Click ( "#FormFill" );
	Pause ( __.Performance * 4 );
	With ( Form );

EndProcedure

Procedure fillPayEmployees ( Form, Department )
	
	With ( Form );
	Click ( "#Fill" );
	With ( "Pay: Setup Filters" );
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Department" );
	table.ChangeRow ();
	Put ( "#UserSettingsValue", Department, table );
	table.EndEditRow ();
	Click ( "#FormFill" );
	Pause ( __.Performance * 4 );
	With ( Form );

EndProcedure

Procedure createHire ( Env, Employee, Date )

	p = Call ( "Documents.Hiring.Create.Params" );
	row = Call ( "Documents.Hiring.Create.Row" );
	row.Employee = Employee;
	row.DateStart = Date;
	row.Department = Env.Department;
	row.Position = Env.Position;
	row.Rate = Env.Rate;
	row.Compensation = Env.Compensation;
	row.Schedule = Env.Schedule;
	row.Expenses = Env.Expenses;
	row.Put = true;
	p.Employees.Add ( row );
	p.Date = Date;
	Call ( "Documents.Hiring.Create", p );		

EndProcedure






