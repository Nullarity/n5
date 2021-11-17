return;
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0CZ" );
env = getEnv ( id );
createEnv ( env );

// ************
// Report
// ************

Commando ( "e1cib/command/Catalog.Reports.Command.Show", false );
Pause (1);
list = With ();
Put ( "#CompanyFilter", Env.Company );
Pause (1);

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "IPC21" );
Click ( "#FormChoose" );

With ( list );
Pause (1);
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "07/01/2019" );
Put ( "#DateEnd", "07/31/2019" );
Click ( "#Select" );

//With ( list );
//Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Employee", "Employee " + ID );
	p.Insert ( "Company", "Company " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Division", "Division " + ID );
	p.Insert ( "Position", "Position " + ID );
	p.Insert ( "Salary", "Salary: " + ID );
	p.Insert ( "Sick", "Sick: " + ID );
	p.Insert ( "SickSocial", "Sick Social: " + ID );
	p.Insert ( "SickChild", "Sick Child: " + ID );
	p.Insert ( "ChildCare", "Child Care: " + ID );
	p.Insert ( "Expense", "Expense: " + ID );
	p.Insert ( "ExpenseMethod", "ExpenseMethod: " + ID );
	p.Insert ( "Social", "Social: " + ID );
	p.Insert ( "SocialEmployee", "SocialEmployee: " + ID );
	p.Insert ( "Medical", "Medical: " + ID );
	p.Insert ( "MedicalEmployee", "MedicalEmployee: " + ID );
	p.Insert ( "Income", "Income: " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	createCompany ( Env );
	createEmployee ( Env );
	createPosition ( Env );
	createCompensations ( Env );
	Call ( "Catalogs.Expenses.Create", Env.Expense );
	createDivision ( Env );
	createDepartment ( Env );
	createExpenseMethod ( Env );
	createTaxes ( Env );
	createHiring ( Env );
	createSickLeaves ( Env );
	createPayroll ( Env, 4 );
	createPayroll ( Env, 5 );
	createPayroll ( Env, 6 );
	createPayroll ( Env, 7 );
	createPayEmployees ( Env );
	createEntries ( Env );
	setDefaultValues ( Env );
	RegisterEnvironment ( id );
	
EndProcedure

Procedure createCompany ( Env )
	
	p = Call ( "Catalogs.Companies.Create.Params" );
	p.Description = Env.Company;
	Call ( "Catalogs.Companies.Create", p );

EndProcedure

Procedure createEmployee ( Env )
	
	id = Env.ID;
	MainWindow.ExecuteCommand ( "e1cib/List/Catalog.Employees" );
	With ( "Employees" );
	Click ( "#FormCreate" );
	With ();
	name = Env.Employee;
	Put ( "#FirstName", name );
	Put ( "#Birthday", "11/06/1988" );
	Put ( "#PIN", "PIN:" + id );
	Put ( "#SIN", "SIN:" + id );
	Put ( "#EmployeeCompany", Env.Company );
	Put ( "#Code", id );
	Click ( "Yes", Forms.Get1C () );
	Click ( "#FormWrite" );
	
	// *************************
	// Insurance
	// *************************
	
	With ( name + "*" );
	Click ( "Insurance", GetLinks () );
	With ( name + "*" );
	Click ( "#FormCreate" ); 
	With ( "Insurance (create)" );
	Put ( "#Period", "01/01/2017" );
	Put ( "#Category", "101" );
	Click ( "#FormWriteAndClose" );
	
	With ();
	Close ();

EndProcedure

Procedure createPosition ( Env )
	
	p = Call ( "Catalogs.Positions.Create.Params" );
	p.Description = Env.Position;
	Call ( "Catalogs.Positions.Create", p );

EndProcedure

Procedure createCompensations ( Env )
	
	createCompensation ( Env.Salary, "Monthly Rate" );
	base = Env.Salary;
	createCompensation ( Env.Sick, "Sick Days", base );
	createCompensation ( Env.SickSocial, "Sick Days, Only Social", base );
	createCompensation ( Env.SickChild, "Sick Days, Child Care", base );
	createCompensation ( Env.ChildCare, "Child Care" );

EndProcedure

Procedure createCompensation ( Name, Method, Base )
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Name;
	p.Method = Method;
	if ( Base <> undefined ) then
		p.Base.Add ( Base );
	endif;
	Call ( "CalculationTypes.Compensations.Create", p );
	
EndProcedure

Procedure createDivision ( Env )
	
	p = Call ( "Catalogs.Divisions.Create.Params" );
	p.Description = Env.Division;
	p.Company = Env.Company;
	p.Cutam = Env.ID;
	Call ( "Catalogs.Divisions.Create", p );

EndProcedure

Procedure createDepartment ( Env )
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	p.Company = Env.Company;
	p.Division = Env.Division;
	Call ( "Catalogs.Departments.Create", p );

EndProcedure

Procedure createExpenseMethod ( Env )
	
	p = Call ( "Catalogs.ExpenseMethods.Create.Params" );
	p.Expense = Env.Expense;
	expenseMethod = Env.ExpenseMethod;
	p.Description = expenseMethod;
	p.Account = "7141";
	Call ( "Catalogs.ExpenseMethods.Create", p );
	Env.Insert ( "ExpenseMethod", expenseMethod );

EndProcedure

Procedure createTaxes ( Env )
	
	createSocial ( Env );
	createMedical ( Env );
	createIncome ( Env );

EndProcedure

Procedure createSocial ( Env )
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = Env.Social;
	p.Method = "Social Insurance";
	p.Account = "5331";
	p.Rate = 24;
	p.RateDate = "01/01/2019";
	p.Base.Add ( Env.Salary );
	Call ( "CalculationTypes.Taxes.Create", p );

EndProcedure

Procedure createMedical ( Env )
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = Env.Medical;
	p.Method = "Medical Insurance";
	p.Account = "5332";
	p.Rate = 9;
	p.RateDate = "01/01/2019";
	p.Base.Add ( Env.Salary );
	Call ( "CalculationTypes.Taxes.Create", p );

EndProcedure

Procedure createIncome ( Env )
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = Env.Income;
	p.Method = "Income Tax";
	p.Account = "5342";
	p.Rate = 12;
	p.RateDate = "01/01/2019";
	p.Base.Add ( Env.Salary );
	Call ( "CalculationTypes.Taxes.Create", p );

EndProcedure

Procedure createHiring ( Env )
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Hiring" );
	form = With ();
	Put ( "#Date", "01/01/2019" );
	Put ( "#Company", Env.Company );
	Click ( "#EmployeesContextMenuAdd" );
	With ( "Employee" );
	Put ( "#Employee", Env.Employee );
	Put ( "#DateStart", "01/01/2019" );
	Put ( "#Department", Env.Department );
	Put ( "#Position", Env.Position );
	Put ( "#Compensation", Env.Salary );
	Put ( "#Expenses", Env.ExpenseMethod );
	Put ( "#Rate", 5000 );
	Click ( "#FormOK" );
	With ( form );
	Click ( "#FormPostAndClose" );

EndProcedure

Procedure createSickLeaves ( Env )
	
	p = new Structure ( "DateStart, DateEnd, Sick" );
	p.DateStart = "7/01/2019";
	p.DateEnd = "7/10/2019";
	p.Sick = Env.Sick;
	createSickLeave ( Env, p );
	p.DateStart = "7/11/2019";
	p.DateEnd = "7/12/2019";
	p.Sick = Env.SickSocial;
	createSickLeave ( Env, p );
	p.DateStart = "7/15/2019";
	p.DateEnd = "7/16/2019";
	p.Sick = Env.SickChild;
	createSickLeave ( Env, p );
	p.DateStart = "7/20/2019";
	p.DateEnd = "7/21/2019";
	p.Sick = Env.ChildCare;
	createSickLeave ( Env, p );

EndProcedure

Procedure createSickLeave ( Env, Params )
	
	Commando ( "e1cib/Data/Document.SickLeave" );
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Employee", Env.Employee );
	Put ( "#Date", "07/01/2019" );
	Put ( "#DateStart", Params.DateStart );
	Put ( "#DateEnd", Params.DateEnd );
	Put ( "#Compensation", Params.Sick );
	Click ( "#FormPostAndClose" );

EndProcedure

Procedure createPayroll ( Env, Month )
	
	Commando ( "e1cib/Data/Document.Payroll" );
	form = With ();
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Period", "Month" );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Memo", Env.ID );
	Put ( "#Date", Call ( "Common.USFormat", EndOfMonth ( Date ( 2019, Month, 1 ) ) ) );
	runFiller ( Env, form );
	Get ( "#Compensations" );
	Click ( "#FormPostAndClose" );

EndProcedure

Procedure runFiller ( Env, Form )
	
	Click ( "#Fill" );
	filler = With ();
	setEmployee ( Env.Employee );
	With ( filler );
	With ();
	Click ( "#FormFill" );
	Pause ( __.Performance * 7 );
	With ( Form );

EndProcedure

Procedure setEmployee ( Employee )
	
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Employee" );
	table.Choose ();
	group = table.GetObject ( , "Values", "UserSettingsColumnGroupValues" );
	field = group.GetObject ( , "Value", "UserSettingsValue" );
	field.InputText ( Employee );
	Next ();

EndProcedure

Procedure createPayEmployees ( Env )

	Commando ( "e1cib/data/Document.PayEmployees" );
	form = With ();
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Date", "07/31/2019" );
	Put ( "#Account", "2421" );
	runFiller ( Env, form );
	Click ( "#FormPostAndClose" );

EndProcedure

Procedure createEntries ( Env )
	
	createEntry ( Env, "DOB", 100, 9900 );
	createEntry ( Env, "PL", 50, 450 );

EndProcedure

Procedure createEntry ( Env, DimCr1, Amount1, Amount2 )
	
	p = Call ( "Documents.Entry.Create.Params" );
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = "5211";
	row.AccountCr = "5343";
	row.DimCr1 = DimCr1;
	row.Amount = Amount1;
	p.Records.Add ( row );
	row = Call ( "Documents.Entry.Create.Row" );
	row.AccountDr = "5211";
	row.AccountCr = "2411";
	row.Amount = Amount2;
	p.Records.Add ( row );
	p.Date = "07/01/2019";
	p.Company = Env.Company;
	Call ( "Documents.Entry.Create", p );
	
EndProcedure

Procedure setDefaultValues ( Env )

	Commando ( "e1cib/command/Catalog.Reports.Command.Show", false );
	Pause (3);
	list = With ();
	Put ( "#CompanyFilter", Env.Company );
	Click ( "#ListCreate" );
	
	With ();
	GotoRow ( "#List", "Description", "Значения по умолчанию" );
	Click ( "#FormChoose" );
	
	form = With ( "Значения по умолчанию" );
	Pause (1);
	Set ( "#ReportField[CNAS]", "CNAS: " + env.ID );
	Set ( "#ReportField[TaxAdministration]", "TaxAdministration: " + env.ID );
	Close ( form );

EndProcedure