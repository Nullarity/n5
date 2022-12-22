// Test if addons will appear in Payroll document
// when they were paid in advance

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A13D" ) );
getEnv ();
createEnv ();

#region createPayroll
Commando ( "e1cib/data/Document.Payroll" );
Put ("#Company", this.Company);
Click("#Button0", "1?:*"); // Yes
Set("#Period", "Other");
Click ( "Yes", Forms.Get1C () );
dateStart = BegOfMonth ( this.Date );
Set ( "#DateStart", Format ( dateStart, "DLF=D" ) );
Set ( "#DateEnd", Format ( EndOfMonth ( dateStart ), "DLF=D" ) );
Activate ( "#Totals" );
Click ( "#Fill" );
With ();
Click ( "#FormFill" );
Pause ( __.Performance * 4 );
With ();
Check ( "#Totals / Amount [ 1 ]", 10500 );
Check ( "#Compensations / Result [ 2 ]", 500 );
Click ( "#FormPost" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate() );
	this.Insert ( "Company", "Company " + id );
	this.Insert ( "Department", "Department " + id );
	this.Insert ( "Employee", "Employee" + id );
	this.Insert ( "Salary", "Monthly " + id );
	this.Insert ( "Bonus", "Bonus " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	#region newCompany
	Call ( "Catalogs.Companies.Create", this.Company );
	#endregion

	#region newEmployee
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = this.Employee;
	p.Company = this.Company;
	p.Deductions = "P";
	p.DeductionsDate = BegOfMonth ( this.Date )-86400;
	Call ( "Catalogs.Employees.Create", p );
	#endregion

	#region newDepartment
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = this.Department;
	p.Company = this.Company;
	Call ( "Catalogs.Departments.Create", p );
	#endregion

	#region newCompensations
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = this.Salary;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = this.Bonus;
	p.Method = "Fixed Amount";
	Call ( "CalculationTypes.Compensations.Create", p );
	#endregion

	#region Hiring
	department = this.Department;
	params = Call ( "Documents.Hiring.Create.Params" );
	params.Company = this.Company;
	p = Call ( "Documents.Hiring.Create.Row" );
	p.Employee = this.Employee;
	dateStart = BegOfMonth ( this.Date );
	p.DateStart = Format ( dateStart, "DLF=D" );
	p.Department = this.Department;
	p.Position = "Manager";
	p.Rate = 10000;
	p.Compensation = this.Salary;
	params.Employees.Add ( p );
	params.Date = dateStart;
	Call ( "Documents.Hiring.Create", params );
	#endregion
	
	#region createAndFillPayAdvances
	Commando ( "e1cib/data/Document.PayAdvances" );
	Put ("#Company", this.Company);
	Click("#Button0", "1?:*"); // Yes
	Activate ( "#Totals" );
	Put ("#Account", "2421");
	Click ( "#Fill" );
	With ();
	Click ( "#FormFill" );
	Pause ( __.Performance * 3 );
	With ();
	Compensations = Get ( "#Compensations" );
	Click ( "#CompensationsAdd" );
	With ();
	Put ( "#Employee", this.Employee );
	Put ( "#Compensation", this.Bonus );
	Put ( "#Account", "5311" );
	Set ( "#Amount", 500 );
	Click ( "#FormOK" );
	With ();
	Click ( "#Calculate1" );
	With ( "Contabilizare" );
	Click ( "#Button0", DialogsTitle );
	Pause ( __.Performance * 3 );
	With ();
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
