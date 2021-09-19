	
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A61A9AE" );
env = getEnv ( id );
createEnv ( env );

// ***********************************
// Create Report
// ***********************************

// Open reports
Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
list = With ();
Pause ( 1 );
Put ( "#CompanyFilter", env.Company );

// Create Report
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "IALS18" );
Click ( "#FormChoose" );

// Select period
With ( list );
periodField = Get ( "#FinancialPeriodField" );

Pause ( 1 );

periodField.Open ();
With ( "Select period" );
Set ( "#DateBegin", env.Date );
Set ( "#DateEnd", env.Date );
Click ( "#Select" );

// Check fields calculation
With ( list );

//Set ( "#ReportField[R100C21:R100C28]", 1000 );
//Set ( "#ReportField[R101C21:R101C28]", 500 );
//Set ( "#ReportField[R100C29:R100C38]", 200 );


Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "Code", ID );
	ID = " " + ID + "#";
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "_Company: " + ID );
	p.Insert ( "Organization", "_Organization: " + ID );
	p.Insert ( "Date", "03/01/2017" );
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
	Click ( "#FormWrite" );
	Click ( "Contacts", GetLinks () );
	form = With ( env.Company + "*" );
	Click ( "#FormCreate" );
	With ( "Contacts (create)" );
	Put ( "#FirstName", "Accountant" );
	Put ( "#ContactType", "Accountant" );
	Put ( "#HomePhone", "(555) 555-5555" );
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
	
	salary = "Hourly Rate" + id;
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = salary;
	Call ( "CalculationTypes.Compensations.Create", p );	
	
	// *************************
	// Create Medical Insurance
	// *************************
	
	medical = "Medical Insurance" + id;
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = medical;
	p.Account = "5332";
	p.Method = "Medical Insurance (Employees)";
	Call ( "CalculationTypes.Taxes.Create", p );
	
	// *************************
	// Create IncomeTax
	// *************************
	
	incomeTax = "Income tax:" + id;
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
	name = "_FirstName:" + id;
	Put ( "#FirstName", name );
	Put ( "#LastName", "_LastName:" + id );
	Put ( "#Patronymic", "_Patronymic:" + id );
	//Set ( "#Sex" );
	Put ( "#Birthday", "11/06/1988" );
	Put ( "#PIN", "_PIN:" + id );
	Put ( "#SIN", "_SIN:" + id );
	Put ( "#EmployeeBusinessPhone", "(555) 555-5555" );
	Put ( "#HomePhone", "(555) 555-1111" );
	Put ( "#Code", env.Code );
	Click ( "Yes", Forms.Get1C () ); 
	Click ( "#FormWrite" );
	employeeCode = env.Code;
	
	// *************************
	// 						Status
	// *************************
	With ( name + "*" );
	Click ( "Status", GetLinks () );
	With ( name + "*" );
	Click ( "#FormCreate" ); 
	With ( "Marital Statuses (create)" );
	Put ( "#Period", "05/20/2017" );
	Put ( "#Status", "Married" );
	Put ( "#PIN", "888000888" );
	Click ( "#FormWriteAndClose" );
	
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
	Put ( "#Date", "01/01/2017" );
	Click ( "#EmployeesContextMenuAdd" );
	With ( "Employee" );
	Put ( "#Employee", employeeCode );
	Put ( "#DateStart", "01/01/2017" );
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
	p.Records.Add ( row ( "5311", "5332", "50", employeeCode, salary ) );
	p.Records.Add ( row ( "5311", "5342", "100", employeeCode, salary ) );
	p.Records.Add ( row ( "5311", "2264", "60", employeeCode, salary ) );
	p.Records.Add ( row ( "5311", "2411", "2000", employeeCode, salary ) );
	Call ( "Documents.Entry.Create", p );
	
	// *************************
	// Create organization
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/Data/Catalog.Organizations" );
	With ( "Organizations (create)" );
	organization1 = "_Organization1: " + id;
	Put ( "#Description", organization1 );
	Put ( "#CodeFiscal", "0000888818888" );
	Click ( "#FormWriteAndClose" );
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Catalog.Organizations" );
	With ( "Organizations (create)" );
	organization2 = "_Organization2: " + id;
	Put ( "#Description", organization2 );
	Put ( "#CodeFiscal", "00009991999" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Entry organization
	// *************************
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "5211", "2411", "115000", organization1 ) );
	p.Records.Add ( row ( "5211", "5343", "50000", organization1, , "ALT" ) );
	Call ( "Documents.Entry.Create", p );
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "5211", "2411", "50000", organization1 ) );
	p.Records.Add ( row ( "5211", "5343", "500", organization1, , "ROY" ) );
	Call ( "Documents.Entry.Create", p );
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "5211", "2411", "50000", organization2 ) );
	p.Records.Add ( row ( "5211", "5343", "500", organization2, , "ROY" ) );
	Call ( "Documents.Entry.Create", p );
	
	p = Call ( "Documents.Entry.Create.Params" );
	p.Date = env.Date;
	p.Company = env.Company;
	p.Records.Add ( row ( "5211", "2411", "1000", organization2 ) );
	p.Records.Add ( row ( "5211", "5343", "5", organization2, , "DIV a)" ) );
	Call ( "Documents.Entry.Create", p );
	
	// *************************
	// Deductions
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/list/Catalog.DeductionsClassifier" );
	list = With ( "Deductions" );
	Click ( "#ListContextMenuCreate" );
	form = With ( "Deductions (create)" );
	Put ( "#Code", "P" );
	Put ( "#Description", "P" );
	Click ( "#FormWriteAndClose" );
	if ( Waiting ( "1?:*" ) ) then
		With ( "1?:*" );
		Click ( "OK" );
		Close ( form );
		if ( Waiting ( "1?:*" ) ) then
			With ( "1?:*" );
			Click ( "No" );
		endif;
	endif;
	Close ( list );
	
	MainWindow.ExecuteCommand ( "e1cib/list/InformationRegister.DeductionRates" );
	With ( "Deduction Rates" );
	Click ( "#ListContextMenuCreate" );
	form = With ( "Deduction Rates (create)" );
	Put ( "#Period", "01/01/2017" );
	Put ( "#Rate", 1200 );
	Put ( "#Deduction", "P" );
	Click ( "#FormWriteAndClose" );
	try
		Click ( "OK", Forms.Get1C () ); 
		Close ( form );
		Click ( "No", Forms.Get1C () ); 
	except
	endtry;
	
	MainWindow.ExecuteCommand ( "e1cib/list/InformationRegister.Deductions" );
	list = With ( "Deductions" );
	Click ( "#ListContextMenuCreate" );
	form = With ( "Deductions (create)" );
	Put ( "#Period", "01/01/2017" );
	Put ( "#Deduction", "P" );
	Put ( "#Employee", employeeCode );
	Click ( "#FormWriteAndClose" );
	try
		Click ( "OK", Forms.Get1C () ); 
		Close ( form );
		Click ( "No", Forms.Get1C () ); 
	except
	endtry;
	close ( list );
	
	// *************************
	// DefaultValues
	// *************************
	
	Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
	list = With ( "Regulatory Reports" );
	Pause ( 1 );
	Put ( "#CompanyFilter", env.Company );
	
	// Create Report
	Click ( "#ListCreate" );
	With ( "Select Report" );
	GotoRow ( "#List", "Description", "Значения по умолчанию" );
	Click ( "#FormChoose" );
	
	With ( list );
	
	Pause ( 1 );
	
	Set ( "#ReportField[CUATM]", "CUATM: " + id );
	Set ( "#ReportField[CAEM]", "CAEM: " + id );
	Set ( "#ReportField[TaxAdministration]", "TaxAdministration: " + id );
	
	RegisterEnvironment ( id );
	
EndProcedure

Function row ( AccountDr, AccountCr, Amount, DimDr1 = undefined, DimDr2 = undefined, DimCr1 = undefined, DimCr2 = undefined )
	
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = AccountDr;
	row.AccountCr = AccountCr;
	row.Amount = Amount;
	row.DimDr1 = DimDr1;
	row.DimDr2 = DimDr2;
	row.DimCr1 = DimCr1;
	row.DimCr2 = DimCr2;
	
	return row;
	
EndFunction
