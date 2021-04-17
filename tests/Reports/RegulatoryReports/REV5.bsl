Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6FF64C" );
env = getEnv ( id );
createEnv ( env );

// ************
// Report
// ************

Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
Pause ( __.Performance * 3 );
Put ( "#CompanyFilter", env.Company );

Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "REV5" );
Click ( "#FormChoose" );
Pause ( __.Performance * 3 );

list = With ();
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "01/01/2019" );
Put ( "#DateEnd", "12/31/2019" );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
With ();
Click ( "Yes");

With ( list );
Set ( "#ReportField[R3C6:R3C33]", id );
Click ( "#FormRefreshReport" );

With ( list );
Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Department", "Department: " + ID );
	p.Insert ( "Date", "05/31/2019" );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
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
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Create Roles
	// *************************
	
	Commando ( "e1cib/data/Document.Roles" );
	With ( "Roles (create)" );
	Put ( "#Company", Env.Company );
	Put ( "#User", "Accountant" );
	Put ( "#Role", "Chief Accountant" );
	Click ( "#Apply" );
	
	Commando ( "e1cib/data/Document.Roles" );
	With ( "Roles (create)" );
	Put ( "#Company", Env.Company );
	Put ( "#User", "Director" );
	Put ( "#Role", "General Manager" );
	Click ( "#Apply" );
	
	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	p.Company = Env.Company;
	Call ( "Catalogs.Departments.Create", p );
		
	// *************************
	// Employee
	// *************************

	MainWindow.ExecuteCommand ( "e1cib/List/Catalog.Employees" );
	With ( "Employees" );
	Click ( "#FormCreate" );
	formEmployee = With ( "Individuals (create)" );
	name = "FirstName: " + id;
	Put ( "#EmployeeCompany", Env.Company );
	Put ( "#FirstName", name );
	Put ( "#LastName", "LastName: " + id );
	Put ( "#Patronymic", "Patronymic: " + id );
	Put ( "#Birthday", "11/06/1988" );
	Put ( "#PIN", "PIN: " + id );
	Put ( "#SIN", "SIN: " + id );
	Put ( "#Code", id );
	Click ( "Yes", Forms.Get1C () ); 
	Click ( "#FormWrite" );
	employeeCode = id;
	
	// *************************
	// IDs
	// *************************
	
	With ( formEmployee );
	Click ( "#FormWrite" );
	Click ( "IDs", GetLinks () );
	With ( name + "*" );
	Click ( "#FormCreate" ); 
	With ( "Identity Documents (create)" );
	Put ( "#Period", "01/01/2019" );
	Put ( "#Type", "Buletin de identitate al cetat. RM" );
	Put ( "#Issued", "01/10/1986" );
	Put ( "#IssuedBy", "IssuedBy: " + id );
	Put ( "#Series", "AA" );
	Put ( "#Number", "0001111" );
	Click ( "#FormWriteAndClose" );

	// *************************
	// Insurance
	// *************************

	With ( name + "*" );
	Click ( "Insurance", GetLinks () );
	With ( name + "*" );
	Click ( "#FormCreate" ); 
	With ( "Insurance (create)" );
	Put ( "#Period", "01/01/2019" );
	Put ( "#Category", "101" );
	Click ( "#FormWriteAndClose" );
	
	With ( name + "*" );
	Click ( "Insurance", GetLinks () );
	With ( name + "*" );
	Click ( "#FormCreate" ); 
	With ( "Insurance (create)" );
	Put ( "#Period", "02/01/2019" );
	Put ( "#Category", "102" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Position
	// *************************

	p = Call ( "Catalogs.Positions.Create.Params" );
	position = "Position: " + id;
	p.Description = position;
	Call ( "Catalogs.Positions.Create", p );
	Env.Insert ( "Position", position );
	
	// *************************
	// Compensation
	// *************************

	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	salary = "Salary: " + id;
	p.Description = salary;
	Call ( "CalculationTypes.Compensations.Create", p );
	Env.Insert ( "Salary", salary );
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	paternityVacation = "PaternityVacation: " + id;
	p.Description = paternityVacation;
	p.Method = "Paternity Vacation";
	Call ( "CalculationTypes.Compensations.Create", p );
	Env.Insert ( "PaternityVacation", paternityVacation );
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	extendedVacation = "ExtendedVacation: " + id;
	p.Description = extendedVacation;
	p.Method = "Extended Vacation";
	Call ( "CalculationTypes.Compensations.Create", p );
	Env.Insert ( "ExtendedVacation", extendedVacation );
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	childCare = "ChildCare: " + id;
	p.Description = childCare;
	p.Method = "Child Care";
	Call ( "CalculationTypes.Compensations.Create", p );
	Env.Insert ( "ChildCare", childCare );
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	extraChildCare = "ExtraChildCare: " + id;
	p.Description = extraChildCare;
	p.Method = "Extra Child Care";
	Call ( "CalculationTypes.Compensations.Create", p );
	Env.Insert ( "ExtraChildCare", extraChildCare );
	
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
	Put ( "#Company", Env.Company );
	Put ( "#Date", "01/01/2019" );
	Click ( "#EmployeesContextMenuAdd" );
	With ( "Employee" );
	Put ( "#Employee", employeeCode );
	Put ( "#DateStart", "01/01/2019" );
	Put ( "#Department", Env.Department );
	Put ( "#Position", position );
	Put ( "#Compensation", salary );
	Put ( "#Expenses", expenseMethod );
	Put ( "#Rate", 50 );
	Click ( "#FormOK" );
	With ( form );
	Click ( "#FormPostAndClose" );
	
	// *************************
	// Vacation
	// *************************

	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Vacation" );
	form = With ( "Vacation (create)" );
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Date", "01/01/2019" );
	Click ( "#JustSave" );
	vacationExtended = Fetch ( "#Number" );
	Close ( form );
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Vacation" );
	form = With ( "Vacation (create)" );
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Date", "05/01/2019" );
	Click ( "#JustSave" );
	vacationPaternity = Fetch ( "#Number" );
	Close ( form );
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Vacation" );
	form = With ( "Vacation (create)" );
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Date", "05/01/2019" );
	Click ( "#JustSave" );
	vacationChildCare = Fetch ( "#Number" );
	Close ( form );
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Vacation" );
	form = With ( "Vacation (create)" );
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Date", "05/01/2019" );
	Click ( "#JustSave" );
	vacationExtraChildCare = Fetch ( "#Number" );
	Close ( form );
	
	// *************************
	// Taxes
	// *************************

	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	social = "Social: " + id;
	p.Description = social;
	p.Method = "Social Insurance";
	p.Account = "5331";
	Call ( "CalculationTypes.Taxes.Create", p );
	
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	socialEmp = "SocialEmployee: " + id;
	p.Description = socialEmp;
	p.Method = "Social Insurance (Employees)";
	p.Account = "5331";
	Call ( "CalculationTypes.Taxes.Create", p );
	
	// *************************
	// Payroll
	// *************************

	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Payroll" );
	form = With ( "Payroll (create)" );
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Period", "Month" );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Date", "01/01/2019" );	
	Put ( "#EmployeesDebt", "2264" );
	Put ( "#EmployerDebt", "5232" );
	
	Env.Insert ( "EmployeeCode", employeeCode );
	
	//*************************************	JANUARY ******************
	//****** salary

	with ( form );
	addSalary ( Env, "01/01", "01/10", "2000" ); 
	with ( form );
	addTax ( Env, "01/01", "01/10", "200", social ); 
	with ( form );
	addTax ( Env, "01/01", "01/10", "190", socialEmp ); 
	
	//****** vacation

	with ( form );
	addExtendedVacation ( Env, "01/11", "01/30", "3000", vacationExtended ); 
	with ( form );
	addTax ( Env, "01/11", "01/30", "300", social ); 
	with ( form );
	addTax ( Env, "01/11", "01/30", "290", socialEmp ); 
	
	//*************************************	FEBRUARY ******************
	//****** salary

	with ( form );
	addSalary ( Env, "02/01", "02/05", "500" ); 
	with ( form );
	addTax ( Env, "02/01", "02/05", "50", social ); 
	with ( form );
	addTax ( Env, "02/01", "02/05", "49", socialEmp ); 
	
	//****** vacation

	with ( form );
	addChildCare ( Env, "02/06", "02/28", "3500", vacationChildCare ); 
	
	with ( form );
	Click ( "#FormPostAndClose" );
	
	//*************************************	MAY ******************
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Payroll" );
	form = With ( "Payroll (create)" );
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Period", "Month" );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Date", "05/01/2019" );
	Put ( "#EmployeesDebt", "2264" );
	Put ( "#EmployerDebt", "5232" );
	
	//****** salary

	with ( form );
	addSalary ( Env, "05/01", "05/15", "2500" ); 
	with ( form );
	addTax ( Env, "05/01", "05/15", "250", social ); 
	with ( form );
	addTax ( Env, "05/01", "05/15", "240", socialEmp ); 
	
	//****** vacation

	with ( form );
	addPaternityVacation ( Env, "05/16", "05/30", "600", vacationPaternity ); 
	with ( form );
	addTax ( Env, "05/16", "05/30", "60", social ); 
	with ( form );
	addTax ( Env, "05/16", "05/30", "59", socialEmp );
	
	with ( form );
	Click ( "#FormPostAndClose" );
	
	//*************************************	AUGUST ******************
	
	MainWindow.ExecuteCommand ( "e1cib/Data/Document.Payroll" );
	form = With ( "Payroll (create)" );
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Period", "Month" );
	Click ( "Yes", Forms.Get1C () );
	Put ( "#Date", "08/01/2019" );
	Put ( "#EmployeesDebt", "2264" );
	Put ( "#EmployerDebt", "5232" );
	
	//****** vacation

	with ( form );
	addExtraChildCare ( Env, "08/01", "08/30", "4000", vacationExtraChildCare ); 
	with ( form );
	
	Click ( "#FormPostAndClose" );
	
	setParameter ( "Extended Vacation", "155" );
	setParameter ( "Paternity Vacation", "165" );
	setParameter ( "Child Care", "157" );
	setParameter ( "Extra Child Care", "158" );
	
	// *************************
	// DefaultValues
	// *************************
	
	Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
	Pause ( __.Performance * 3 );
	Put ( "#CompanyFilter", Env.Company );

	Click ( "#ListCreate" );
	With ( "Select Report" );
	GotoRow ( "#List", "Description", "Значения по умолчанию" );
	Click ( "#FormChoose" );
	Pause ( __.Performance * 3 );
	
	form = With ( "Значения по умолчанию" );
	Set ( "#ReportField[TaxAdministration]", "TaxAdministration" );
	Set ( "#ReportField[CNAS]", "CNAS: " + id );
	Close ( form );
	
	Call ( "Common.StampData", id );
	
EndProcedure

Function local ( Date1, Date2 = undefined, Date3 = undefined )
	
	if ( Date2 = undefined ) then
		date = Date1;
	else
		date = Date ( Date1, Date2, Date3 );
	endif;
	return Format ( date, "DLF = 'DT'" );
	
EndFunction

Procedure addSalary ( Env, Start, End, Amount )
	
	addComon ( Env, Start, End, Env.Salary, Amount );
	
EndProcedure

Procedure addComon ( Env, Start, End, Compensation, Amount, Reference = undefined, Type = "" )
	
	Click ( "#CompensationsContextMenuAdd" );
	With ( "Compensation" );
	Put ( "#Employee", Env.EmployeeCode );
	Put ( "#DateStart", Start +"/2019" );
	Put ( "#DateEnd", End +"/2019" );
	Put ( "#Schedule", "General" );
	Put ( "#Department", Env.Department );
	Put ( "#Position", Env.Position );
	Put ( "#Compensation", Compensation );
	Put ( "#Currency", "MDL" );
	Put ( "#Account", "5311" );
	Put ( "#Expenses", Env.expenseMethod );
	Put ( "#AccountingResult", Amount );
	if ( Reference <> undefined ) then
		With ( "Compensation*" );
		form = CurrentSource;
		Choose ( "#Reference" );
		With ( "Select data type" );
		GotoRow ( "#TypeTree", "", Type );
		Click ( "#OK" );
		With ( Type + "s" );
		GotoRow ( "#List", "Number", Reference );
		Click ( "#FormChoose" );
		CurrentSource = form;
	endif;
	Click ( "#FormOK" );
	
EndProcedure

Procedure addExtendedVacation ( Env, Start, End, Amount, Vacation )
	
	addComon ( Env, Start, End, Env.ExtendedVacation, Amount, Vacation, "Vacation" );
	
EndProcedure

Procedure addPaternityVacation ( Env, Start, End, Amount, Vacation )
	
	addComon ( Env, Start, End, Env.PaternityVacation, Amount, Vacation, "Vacation" );
	
EndProcedure

Procedure addChildCare ( Env, Start, End, Amount, Vacation )
	
	addComon ( Env, Start, End, Env.ChildCare, Amount, Vacation, "Vacation" );
	
EndProcedure

Procedure addExtraChildCare ( Env, Start, End, Amount, Vacation )
	
	addComon ( Env, Start, End, Env.ExtraChildCare, Amount, Vacation, "Vacation" );
	
EndProcedure

Procedure addSick ( Env, Start, End, Amount, Sick )
	
	addComon ( Env, Start, End, Env.Sick, Amount, Sick, "Sick Leave" );
	
EndProcedure

Procedure addTax ( Env, Start, End, Amount, Tax )
	
	Click ( "#TaxesContextMenuAdd" );
	With ( "Tax" );
	Put ( "#Employee", Env.employeeCode );
	Put ( "#Tax", Tax );
	Put ( "#Expenses", Env.ExpenseMethod );
	Put ( "#Department", Env.Department );
	Put ( "#DateStart", Start +"/2019" );
	Put ( "#Account", "5331" );
	Put ( "#DateEnd", End +"/2019" );
	Put ( "#Result", Amount );
	Click ( "#FormOK" );
	
EndProcedure

Procedure setParameter ( Parameter, Code )
	
	OpenMenu ( "Settings / Application" );
	form = With ( "Application Settings" );
	Activate ( "!AccountingPage" );
	date = Format ( BegOfYear ( CurrentDate () ), "DLF=D" );
	Put ( "!SetupDate", date );
	table = Activate ( "!Settings" );
	search = new Map ();
	search [ "Parameter" ] = Parameter;
	table.GotoRow ( search, RowGotoDirection.Down );
	field = table.GetObject ( , "Parameter", "SettingsDescription" );
	field.Activate ();
	table.Choose ();
	With ( Parameter + ": Setup" );
	Put ( "!Value", Code );
	Put ( "#SetupDate", "01/01/2019" );
	Click ( "!FormOK" );
	With ( form );
	Click ( "!FormWriteAndClose" );
	
EndProcedure