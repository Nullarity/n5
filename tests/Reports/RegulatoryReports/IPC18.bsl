return;

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BE61825" );
env = getEnv ( id );
createEnv ( env );

// ************
// Report
// ************

Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause (1);
list = With ();
Put ( "#CompanyFilter", Env.Company );
Pause (1);

With ( list );
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "IPC18" );
Click ( "#FormChoose" );

With ( list );
Pause (1);
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "07/01/2019" );
Put ( "#DateEnd", "07/31/2019" );
Click ( "#Select" );

With ( list );
Call ( "Common.CheckLogic", "#ReportField" );

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
	if ( Call ( "Common.DataCreated", id ) ) then
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
	createPayroll ( Env );
	createPayEmployees ( Env );
	createEntries ( Env );
	setDefaultValues ( Env );
	Call ( "Common.StampData", id );
	
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

EndProcedure

Procedure createPosition ( Env )
	
	p = Call ( "Catalogs.Positions.Create.Params" );
	p.Description = Env.Position;
	Call ( "Catalogs.Positions.Create", p );

EndProcedure

Procedure createCompensations ( Env )
	
	createCompensation ( Env.Salary, "Monthly Rate" );
	createCompensation ( Env.Sick, "Sick Days" );
	createCompensation ( Env.SickSocial, "Sick Days, Social" );
	createCompensation ( Env.SickChild, "Sick Days, Child Care" );
	createCompensation ( Env.ChildCare, "Child Care" );

EndProcedure

Procedure createCompensation ( Name, Method )
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Name;
	p.Method = Method;
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
	createSocialEmployee ( Env );
	createMedical ( Env );
	createMedicalEmployee ( Env );
	createIncome ( Env );

EndProcedure

Procedure createSocial ( Env )
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = Env.Social;
	p.Method = "Social Insurance";
	p.Account = "5331";
	p.Rate = 23;
	p.RateDate = "01/01/2019";
	p.Base.Add ( Env.Salary );
	Call ( "CalculationTypes.Taxes.Create", p );

EndProcedure

Procedure createSocialEmployee ( Env )
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = Env.SocialEmployee;
	p.Method = "Social Insurance (Employees)";
	p.Account = "5331";
	p.Rate = 6;
	p.RateDate = "01/01/2019";
	p.Base.Add ( Env.Salary );
	Call ( "CalculationTypes.Taxes.Create", p );

EndProcedure

Procedure createMedical ( Env )
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = Env.Medical;
	p.Method = "Medical Insurance";
	p.Account = "5332";
	p.Rate = 4.5;
	p.RateDate = "01/01/2019";
	p.Base.Add ( Env.Salary );
	Call ( "CalculationTypes.Taxes.Create", p );

EndProcedure

Procedure createMedicalEmployee ( Env )
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = Env.MedicalEmployee;
	p.Method = "Medical Insurance (Employees)";
	p.Account = "5332";
	p.Rate = 4.5;
	p.RateDate = "01/01/2019";
	p.Base.Add ( Env.Salary );
	Call ( "CalculationTypes.Taxes.Create", p );

EndProcedure

Procedure createIncome ( Env )
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = Env.Income;
	p.Method = "Income Tax (scale)";
	p.RateDate = "01/01/2019";
	p.Account = "5342";
	p.Base.Add ( Env.Salary );
	scale = p.Scale;
	limit = Call ( "CalculationTypes.Taxes.Create.Scale" );
	limit.Limit = 31140;
	limit.Rate = 7;
	scale.Add ( limit );
	limit = Call ( "CalculationTypes.Taxes.Create.Scale" );
	limit.Limit = 999999999;
	limit.Rate = 18;
	scale.Add ( limit );
	Call ( "CalculationTypes.Taxes.Create", p );

EndProcedure

Procedure createHiring ( Env )
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Hiring" );
	form = With ();
	Put ( "#Date", "07/01/2019" );
	Put ( "#Company", Env.Company );
	Click ( "#EmployeesContextMenuAdd" );
	With ( "Employee" );
	Put ( "#Employee", Env.Employee );
	Put ( "#DateStart", "07/01/2019" );
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
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Document.SickLeave" );
	With ();
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Employee", Env.Employee );
	Put ( "#Date", "07/01/2019" );
	Put ( "#DateStart", Params.DateStart );
	Put ( "#DateEnd", Params.DateEnd );
	Put ( "#Compensation", Params.Sick );
	Click ( "#FormPostAndClose" );

EndProcedure

Procedure createPayroll ( Env )
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Payroll" );
	form = With ();
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Period", "Month" );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#EmployeesDebt", "2264" );
	Put ( "#EmployerDebt", "5232" );
	Put ( "#Memo", Env.ID );
	Put ( "#Date", "07/01/2019" );
	runFiller ( Env, form );
	Get ( "#Compensations" );
	Click ( "#FormPostAndClose" );

EndProcedure

Procedure runFiller ( Env, Form, SetPeriod = true )
	
	Click ( "#Fill" );
	filler = With ();
	setEmployee ( Env.Employee );
	With ( filler );
	if ( SetPeriod ) then
		setPeriod ();
	endif;	
	With ();
	Click ( "#FormFill" );
	Pause ( __.Performance * 7 );
	With ( Form );

EndProcedure

Procedure setPeriod ()
	
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Period" );
	table.Choose ();
	group = table.GetObject ( , "Values", "UserSettingsColumnGroupValues" );
	field = Group.GetObject ( , "Value", "UserSettingsValue" );
	field.StartChoosing ();
	With ();
	Set ( "#DateBegin", "07/01/2019" );
	Set ( "#DateEnd", "07/31/2019" );
	Click ( "#Select" );

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
//	Set ( "#Account", "2421" );
	runFiller ( Env, form, false );
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

	Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
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