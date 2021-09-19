Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6ABEB0" );
env = getEnv ( id );
createEnv ( env );

// ***********************************
// Create Report
// ***********************************

Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause (1);
list = With ();
Put ( "#CompanyFilter", env.Company );
Pause (1);

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "Информация о доходах физического лица" );
Click ( "#FormChoose" );

With ( list );
Pause (1);
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", env.Date );
Put ( "#DateEnd", env.Date );
Click ( "#Select" );

With ( list );
Set ( "#ReportField[R3C6:R3C34]", Env.Code );

Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Code", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Employee", "Employee: " + ID );
	p.Insert ( "Date", "03/01/2019" );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Company
	// *************************
	
	Call ( "Catalogs.Companies.Create", Env.Company );
	MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Companies" );
	With ( "Companies" );
	Clear ( "#UnitFilter" );
	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = env.Company;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ( env.Company + "*" );
	Put ( "#CodeFiscal", "1000101552352" );
	Put ( "#RegistrationNumber", "RegistrationNumber" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Roles
	// *************************
	
	Commando ( "e1cib/data/Document.Roles" );
	Set ( "#Company", Env.Company );
	Put ( "#User", "Accountant" );
	Put ( "#Role", "Chief Accountant" );
	Click ( "#Apply" );
	
	Commando ( "e1cib/data/Document.Roles" );
	Set ( "#Company", Env.Company );
	Put ( "#User", "Director" );
	Put ( "#Role", "General Manager" );
	Click ( "#Apply" );
	
	// *************************
	// Create Compensation
	// *************************
	
	salary = "Hourly Rate: " + id;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = salary;
	Call ( "CalculationTypes.Compensations.Create", p );	
	
	// *************************
	// Create Medical Insurance
	// *************************
	
	medical = "Medical Insurance: " + id;
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = medical;
	p.Account = "5332";
	p.Method = "Medical Insurance (Employees)";
	Call ( "CalculationTypes.Taxes.Create", p );
	
	// *************************
	// Create IncomeTax
	// *************************
	
	incomeTax = "Income tax: " + id;
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = incomeTax;
	p.Account = "5342";
	p.Method = "Income Tax (scale)";
	Call ( "CalculationTypes.Taxes.Create", p );	
	
	// *************************
	// Employee
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/List/Catalog.Employees" );
	With ( "Employees" );
	Click ( "#FormCreate" );
	formEmployee = With ( "Individuals (create)" );
	name = "FirstName: " + id;
	Put ( "#FirstName", name );
	Put ( "#LastName", "LastName: " + id );
	Put ( "#Patronymic", "Patronymic: " + id );
	Put ( "#Birthday", "11/06/1988" );
	Put ( "#PIN", "PIN: " + id );
	Put ( "#SIN", "SIN: " + id );
	Put ( "#EmployeeBusinessPhone", "(555) 111-5555" );
	Put ( "#HomePhone", "(555) 555-5555" );
	Put ( "#Code", env.Code );
	Click ( "Yes", Forms.Get1C () ); 
	Click ( "#FormWrite" );
	employeeCode = env.Code;
	
	// *************************
	// Hire Employee
	// *************************
	
	// *************************
	// Expense
	// *************************
	
	expense = "Expense: " + id;
	Call ( "Catalogs.Expenses.Create", expense );
	
	// *************************
	// ExpenseMethods
	// *************************
	
	p = Call ( "Catalogs.ExpenseMethods.Create.Params" );
	p.Expense = expense;
	expenseMethod = "ExpenseMethod: " + id;
	p.Description = expenseMethod;
	p.Account = "7141";
	Call ( "Catalogs.ExpenseMethods.Create", p );
	Env.Insert ( "ExpenseMethod", expenseMethod );
	
	// *************************
	// Hiring
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Hiring" );
	form = With ( "Hiring (create)" );
	Put ( "#Date", "01/01/2019" );
	Click ( "#EmployeesContextMenuAdd" );
	With ( "Employee" );
	Put ( "#Employee", employeeCode );
	Put ( "#DateStart", "01/01/2019" );
	Put ( "#Department", "Administration" );
	Put ( "#Position", "Accountant" );
	Put ( "#Compensation", salary );
	Put ( "#Expenses", expenseMethod );
	Put ( "#Rate", 50 );
	Click ( "#FormOK" );
	With ( form );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	employee = Env.Employee;
	p.Records.Add ( row ( "5311", "5332", "50", employeeCode, salary ) );
	p.Records.Add ( row ( "5311", "5342", "100", employeeCode, salary ) );
	p.Records.Add ( row ( "5311", "2264", "60", employeeCode, salary ) );
	p.Records.Add ( row ( "5311", "2411", "2000", employeeCode, salary ) );
	Call ( "Documents.Entry.Create", p );
	
	// *************************
	// EmployeesOtherDebt
	// *************************
	
	Call ( "Reports.RegulatoryReports.EmployeesOtherDebt" );
	
	RegisterEnvironment ( id );
	
EndProcedure

Function row ( AccountDr, AccountCr, Amount, DimDr1 = undefined, DimDr2 = undefined )
	
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = AccountDr;
	row.AccountCr = AccountCr;
	row.Amount = Amount;
	row.DimDr1 = DimDr1;
	row.DimDr2 = DimDr2;
	return row;
	
EndFunction
