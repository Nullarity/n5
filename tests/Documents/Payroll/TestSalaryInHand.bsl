// Calculate salary using "In Hand" option

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A08Y" ) );
getEnv ();
createEnv ();

#region createAndFillPayroll
Commando ( "e1cib/data/Document.Payroll" );
Click ( "#Fill" );
With ();
table = Get ( "#UserSettings" );
GotoRow ( table, "Setting", "Department" );
Put ( "#UserSettingsValue", this.Department, table );
Click ( "#FormFill" );
Pause ( __.Performance * 4 );
With ();
//Check ( "#Compensations / Result [ 1 ]", 20000 );
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Department", "Department " + id );
	this.Insert ( "Employees", getEmployees () );
	this.Insert ( "MonthlyRate", "Monthly " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	#region newEmployee
	for each employee in this.Employees do
		p = Call ( "Catalogs.Employees.Create.Params" );
		p.Description = employee.Name;
		Call ( "Catalogs.Employees.Create", p );
	enddo;
	#endregion

	#region newDepartment
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = this.Department;
	Call ( "Catalogs.Departments.Create", p );
	#endregion

	#region newCompensation
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	compensation = this.MonthlyRate;
	p.Description = compensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	#endregion

	#region tax1
	date = Format ( BegOfMonth ( this.Date ), "DLF=D" );;
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = "Tax1: " + id;
	p.Method = "Medical Insurance";
	p.RateDate = date;
	p.Rate = 9;
	p.Account = "5331";
	base = p.Base;
	base.Add ( compensation );
	Call ( "CalculationTypes.Taxes.Create", p );
	#endregion
	
	#region tax2
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = "Tax2: " + id;
	p.Method = "Social Insurance";
	p.RateDate = date;
	p.Rate = 24;
	p.Account = "5331";
	base = p.Base;
	base.Add ( compensation );
	Call ( "CalculationTypes.Taxes.Create", p );
	#endregion

	#region tax3
	p = Call ( "CalculationTypes.Taxes.Create.Params" );
	p.Description = "Tax3: " + id;
	p.Method = "Income Tax (fixed percent)";
	p.RateDate = date;
	p.Rate = 12;
	p.Account = "5342";
	base = p.Base;
	base.Add ( compensation );
	Call ( "CalculationTypes.Taxes.Create", p );
	#endregion

	#region Hiring
	department = this.Department;
	monthlyRate = this.MonthlyRate;
	params = Call ( "Documents.Hiring.Create.Params" );
	for each employee in this.Employees do
		p = Call ( "Documents.Hiring.Create.Row" );
		p.Employee = employee.Name;
		p.DateStart = Format ( employee.DateStart, "DLF=D" );
		p.DateEnd = Format ( employee.DateEnd, "DLF=D" );
		p.Department = department;
		p.Position = "Manager";
		p.Rate = employee.Rate;
		p.InHand = true;
		p.Compensation = monthlyRate;
		params.Employees.Add ( p );
	enddo;
	params.Date = this.Date;
	Call ( "Documents.Hiring.Create", params );
	#endregion

	RegisterEnvironment ( id );

EndProcedure

Function getEmployees ()

	id = this.ID;
	date = this.Date;
	dateStart = BegOfMonth ( date );
	dateEnd = Date ( 1, 1, 1 );
	employees = new Array ();
	employees.Add ( newEmployee ( "Employee " + id, dateStart, dateEnd, 20000 ) );
	return employees;

EndFunction

Function newEmployee ( Name, DateStart, DateEnd, Rate )

	p = new Structure ( "Name, DateStart, DateEnd, Rate" );
	p.Name = Name;
	p.DateStart = DateStart;
	p.DateEnd = DateEnd;
	p.Rate = Rate;
	return p;

EndFunction
