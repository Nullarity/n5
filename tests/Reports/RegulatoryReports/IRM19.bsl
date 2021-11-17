
Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6FF185" );
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
GotoRow ( "#List", "Description", "IRM19" );
Click ( "#FormChoose" );

With ( list );
Pause (1);
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", "01/01/2019" );
Put ( "#DateEnd", "01/10/2019" );
Click ( "#Select" );

With ( list );
Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Company", "Company " + ID );
	p.Insert ( "Department", "Department " + ID );
	p.Insert ( "Position", "Position " + ID );
	p.Insert ( "Employees", getEmployees ( ID ) );
	p.Insert ( "Salary", "Salary " + ID );
	p.Insert ( "PaternityVacation", "Paternity Vacation " + ID );
	p.Insert ( "ChildCare", "Child Care " + ID );
	p.Insert ( "ExtraChildCare", "Extra Child Care " + ID );
	return p;
	
EndFunction

Function getEmployees ( ID )
	
	result = new Array;
	for i = 1 to 3 do
		result.Add ( getEmployee ( ID, i ) );
	enddo;
	return result;

EndFunction

Function getEmployee ( ID, Number )
	
	result = new Structure ( "Name, PIN, SIN" );
	result.Name = "Employee" + Number + " " + ID;
	result.PIN = "PIN" + Number + " " + ID;
	result.SIN = "SIN" + Number + " " + ID;
	return result;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	createCompany ( Env );
	createCompensations ( Env );
	createDepartment ( Env );
	createPosition ( Env );
	createEmployees ( Env );
	createHiring ( Env );
	createVacations ( Env );
	setDefaulValues ( Env );
	RegisterEnvironment ( id );
	
EndProcedure

Procedure createCompany ( Env )
	
	p = Call ( "Catalogs.Companies.Create.Params" );
	p.Description = Env.Company;
	Call ( "Catalogs.Companies.Create", p );

EndProcedure

Procedure createCompensations ( Env )
	
	createCompensation ( Env.Salary, "Monthly Rate" );
	createCompensation ( Env.ChildCare, "Child Care" );
	createCompensation ( Env.ExtraChildCare, "Extra Child Care" );
	createCompensation ( Env.PaternityVacation, "Paternity Vacation" );

EndProcedure

Procedure createCompensation ( Name, Method )
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Name;
	p.Method = Method;
	Call ( "CalculationTypes.Compensations.Create", p );
	
EndProcedure

Procedure createDepartment ( Env ) 
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	p.Company = Env.Company;
	Call ( "Catalogs.Departments.Create", p );
	
EndProcedure

Procedure createPosition ( Env )
	
	p = Call ( "Catalogs.Positions.Create.Params" );
	p.Description = Env.Position;
	Call ( "Catalogs.Positions.Create", p );	

EndProcedure

Procedure createEmployees ( Env )
	
	company = Env.Company;
	for each employee in Env.Employees do
		p = Call ( "Catalogs.Employees.Create.Params" );
		p.Description = employee.Name;
		p.Company = company;
		p.PIN = employee.PIN;
		p.SIN = employee.SIN;
		Call ( "Catalogs.Employees.Create", p );
	enddo;

EndProcedure

Procedure createHiring ( Env )
	
	id = Env.ID;
	params = Call ( "Documents.Hiring.Create.Params" );
	params.Date = "01/01/2019";
	params.Company = Env.Company;
	employees = params.Employees;
	department = Env.Department;
	position = Env.Position;
	compensation = Env.Salary;
	for each employee in Env.Employees do
		p = Call ( "Documents.Hiring.Create.Row" );
		p.Employee = employee.Name;
		p.DateStart = "01/01/2019";
		p.Department = department;
		p.Position = position;
		p.Compensation = compensation;
		p.Rate = 5000;
		employees.Add ( p );
	enddo;
	Call ( "Documents.Hiring.Create", params );

EndProcedure

Procedure createVacations ( Env )
	
	p = new Structure ( "Employee, DateStart, DateEnd, Compensation" );
	p.Employee = Env.Employees [ 0 ].Name;
	p.DateStart = "01/05/2019";
	p.DateEnd = "01/07/2022";
	p.Compensation = Env.ChildCare;
	createVacation ( Env, p );
	p.Employee = Env.Employees [ 1 ].Name;
	p.DateStart = "01/03/2019";
	p.DateEnd = "01/03/2020";
	p.Compensation = Env.ExtraChildCare;
	createVacation ( Env, p );
	p.Employee = Env.Employees [ 2 ].Name;
	p.DateStart = "01/09/2019";
	p.DateEnd = "04/09/2019";
	p.Compensation = Env.PaternityVacation;
	createVacation ( Env, p );

EndProcedure

Procedure createVacation ( Env, Params )
	
	Commando ( "e1cib/command/Document.Vacation.Create" );
	With ( "Vacation (cr*" );
	Put ( "#Company", Env.Company );
	Click ( "Yes", Forms.Get1C () );
	Click ( "#EmployeesAdd" );
	Set ( "#EmployeesEmployee", Params.Employee );
	Set ( "#EmployeesDateStart", Params.DateStart );
	Set ( "#EmployeesDateEnd", Params.DateEnd );
	Put ( "#EmployeesCompensation", Params.Compensation );
	Click ( "#FormPostAndClose" );	

EndProcedure

Procedure setDefaulValues ( Env )

	Commando ( "e1cib/command/Catalog.Reports.Command.Show", false );
	Pause ( 1 );
	list = With ();
	Put ( "#CompanyFilter", Env.Company );
	Click ( "#ListCreate" );
	
	With ();
	GotoRow ( "#List", "Description", "Значения по умолчанию" );
	Click ( "#FormChoose" );
	
	form = With ( "Значения по умолчанию" );
	Pause ( 1 );
	Set ( "#ReportField[CNAS]", "CNAS: " + env.ID );
	Set ( "#ReportField[TaxAdministration]", "TaxAdministration: " + env.ID );
	Close ( form );

EndProcedure
