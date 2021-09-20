Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A607AD4" );
env = getEnv ( id );
createEnv ( env );

// ***********************************
// Create Report
// ***********************************

Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause ( __.Performance * 3 );
Put ( "#CompanyFilter", env.Company );

Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "Отчет о подоходном налоге (2014)" );
Click ( "#FormChoose" );
Pause ( __.Performance * 3 );

list = With ();
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", env.Date );
Put ( "#DateEnd", env.Date );
Click ( "#Select" );

With ( list );
Set ( "#ReportField[R100C21:R100C28]", 1000 );
Set ( "#ReportField[R101C21:R101C28]", 500 );
Set ( "#ReportField[R100C29:R100C38]", 200 );

Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Code", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Organization", "Organization: " + ID );
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
	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = env.Company;
	Call ( "Common.Find", p );
	Click ( "#FormChange" );
	With ( env.Company + "*" );
	Put ( "#CodeFiscal", "1000101552352" );
	Put ( "#RegistrationNumber", "RegistrationNumber" );
	Click ( "#FormWrite" );
	
	Click ( "Contacts", GetLinks () );
	form = With ( env.Company + "*" );
	
	Click ( "#FormCreate" );
	With ( "Contacts (create)" );
	Put ( "#FirstName", "Accountant" );
	Put ( "#ContactType", "Accountant" );
	Click ( "#FormWriteAndClose" );
	
	With ( form );
	Click ( "#FormCreate" );
	With ( "Contacts (create)" );
	Put ( "#FirstName", "Director" );
	Put ( "#ContactType", "Director" );
	Click ( "#FormWriteAndClose" );
	
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
	Put ( "#FirstName", "FirstName:" + id );
	Put ( "#LastName", "LastName:" + id );
	Put ( "#Patronymic", "Patronymic:" + id );
	Put ( "#Birthday", "11/06/1988" );
	Put ( "#PIN", "PIN:" + id );
	Put ( "#SIN", "SIN:" + id );
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
	// Entry salary
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "5311", "5332", "50", salary ) );
	p.Records.Add ( row ( "5311", "5342", "100", salary ) );
	p.Records.Add ( row ( "5311", "2264", "60", salary ) );
	p.Records.Add ( row ( "5311", "2411", "2000", salary ) );
	Call ( "Documents.Entry.Create", p );
	
	// *************************
	// Entry
	// *************************
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "5211", "2411", "115000" ) );
	p.Records.Add ( row ( "5211", "5343", "5000", , "ALT" ) );
	Call ( "Documents.Entry.Create", p );
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "5211", "2411", "5000" ) );
	p.Records.Add ( row ( "5211", "5343", "50", , "ROY" ) );
	Call ( "Documents.Entry.Create", p );
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "5211", "2411", "5000" ) );
	p.Records.Add ( row ( "5211", "5343", "50", , "ROY" ) );
	Call ( "Documents.Entry.Create", p );
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "5211", "2411", "1000" ) );
	p.Records.Add ( row ( "5211", "5343", "5", , "DIV a)" ) );
	Call ( "Documents.Entry.Create", p );
	
	// *************************
	// Divisions
	// *************************
	
	p = Call ( "Catalogs.Divisions.Create.Params" );
	p.Company = Env.Company;
	for i = 1 to 3 do
		p.Description = "Division" + i + ": " + id;;
		p.Cutam = "Cutam: " + i;
		Call ( "Catalogs.Divisions.Create", p );
	enddo;
	
	// *************************
	// DefaultValues
	// *************************
	
	Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
	Pause ( __.Performance * 3 );
	Put ( "#CompanyFilter", env.Company );
	
	Click ( "#ListCreate" );
	With ( "Select Report" );
	GotoRow ( "#List", "Description", "Значения по умолчанию" );
	Click ( "#FormChoose" );
	Pause ( __.Performance * 3 );
	
	form = With ( "Значения по умолчанию" );
	Set ( "#ReportField[CUATM]", "CUATM: " + id );
	Set ( "#ReportField[CAEM]", "CAEM: " + id );
	Set ( "#ReportField[TaxAdministration]", "TaxAdministration: " + id );
	Close ( form );
	
	RegisterEnvironment ( id );
	
EndProcedure

Function row ( AccountDr, AccountCr, Amount, DimDr2 = undefined, DimCr1 = undefined )
	
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = AccountDr;
	row.AccountCr = AccountCr;
	row.Amount = Amount;
	row.DimDr2 = DimDr2;
	row.DimCr1 = DimCr1;
	return row;
	
EndFunction