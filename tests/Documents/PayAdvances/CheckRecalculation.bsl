// Test employee payment in advance for regular and reversed salary
// - Hire two employees. The Employee1 will have gross (standard) compensations, the second "In Hand"
// - Create a Pay Advances
// - Recalc in different ways and check results

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A0E4" ) );
getEnv ();
createEnv ();

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
#endregion

#region recalcAll
Click ( "#Calculate" );
Click ( "#Button0", DialogsTitle ); // Yes
Pause ( __.Performance * 3 );
Check ( "#Totals / Amount [ 1 ]", 5000 );
Check ( "#Totals / Income Tax [ 1 ]", 333.6 );
Check ( "#Totals / Net [ 1 ]", 4216.4 );
Check ( "#Totals / Amount [ 2 ]", 5978.52 );
Check ( "#Totals / Net [ 2 ]", 5000 );
#endregion

#region recalcTaxes
Click ( "#CalculateTaxes" );
Click ( "#Button0", DialogsTitle ); // Yes
Pause ( __.Performance * 3 );
Check ( "#Totals / Amount [ 1 ]", 5000 );
Check ( "#Totals / Income Tax [ 1 ]", 333.6 );
Check ( "#Totals / Net [ 1 ]", 4216.4 );
Check ( "#Totals / Amount [ 2 ]", 5978.52 );
Check ( "#Totals / Net [ 2 ]", 5000 );
#endregion

#region recalcManualResults
Activate ( "#PageCalculations" ); // Calculations
Compensations = Get ( "#Compensations" );
Compensations.GotoFirstRow ();
Compensations.Choose ();
With ();
Click ( "#Edit" );
Set ( "#Result", 10000 );
Click ( "#FormOK" );

With ();

Compensations.GotoNextRow ();
Compensations.Choose ();
With ();
Click ( "#Edit" );
Set ( "#Result", 15000 );
Click ( "#FormOK" );
With ();

Click ( "#Calculate1" ); // Recalc All
Click ( "#Button0", DialogsTitle ); // Yes
Pause ( __.Performance * 3 );

Check ( "#Totals / Amount [ 1 ]", 10000 );
Check ( "#Totals / Medical [ 1 ]", 900 );
Check ( "#Totals / Amount [ 2 ]", 15000 );
Check ( "#Totals / Medical [ 2 ]", 1350 );
#endregion


#region recalcTaxesForManualCompensations
Activate ( "#PageCalculations" ); // Calculations
Compensations = Get ( "#Compensations" );
Compensations.GotoFirstRow ();
Compensations.Choose ();
With ();
Set ( "#Result", 6000 );
Click ( "#FormOK" );

With ();

Compensations.GotoNextRow ();
Compensations.Choose ();
With ();
Set ( "#Result", 7000 );
Click ( "#FormOK" );
With ();

Click ( "#CalculateTaxes1" ); // Taxes Only
Click ( "#Button0", DialogsTitle ); // Yes
Pause ( __.Performance * 3 );

Check ( "#Totals / Amount [ 1 ]", 6000 );
Check ( "#Totals / Medical [ 1 ]", 540 );
Check ( "#Totals / Amount [ 2 ]", 7000 );
Check ( "#Totals / Medical [ 2 ]", 630 );
Check ( "#Totals / Income Tax [ 2 ]", 552 );
#endregion

#region recalcTaxesForManualTax
Activate ( "#PageCalculations" ); // Calculations
taxes = Get ( "#Taxes" );
taxes.GotoFirstRow ();
taxes.Choose ();
With ();
Click ( "#Edit" );
Set ( "#Result", 780 );
Click ( "#FormOK" );

With ();

Check ( "#Totals / Medical [ 1 ]", 780 );
Check ( "#Totals / Net [ 1 ]", 4777.2 );

Click ( "#CalculateTaxes" ); // Taxes Only
Click ( "#Button0", DialogsTitle ); // Yes
Pause ( __.Performance * 3 );

Check ( "#Totals / Medical [ 1 ]", 780 );

Click ( "#Calculate" ); // All
Click ( "#Button0", DialogsTitle ); // Yes
Pause ( __.Performance * 3 );

Check ( "#Totals / Medical [ 1 ]", 780 );
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate() );
	this.Insert ( "Company", "Company " + id );
	this.Insert ( "Department", "Department " + id );
	this.Insert ( "Employees", getEmployees () );
	this.Insert ( "MonthlyRate", "Monthly " + id );

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
	for each employee in this.Employees do
		p = Call ( "Catalogs.Employees.Create.Params" );
		p.Description = employee.Name;
		p.Company = this.Company;
		p.Deductions = "P";
		p.DeductionsDate = employee.DateStart;
		Call ( "Catalogs.Employees.Create", p );
	enddo;
	#endregion

	#region newDepartment
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = this.Department;
	p.Company = this.Company;
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
	date = Format ( BegOfYear ( this.Date ), "DLF=D" );;
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
	p.Method = "Income Tax";
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
	params.Company = this.Company;
	for each employee in this.Employees do
		p = Call ( "Documents.Hiring.Create.Row" );
		p.Employee = employee.Name;
		p.DateStart = Format ( employee.DateStart, "DLF=D" );
		p.DateEnd = Format ( employee.DateEnd, "DLF=D" );
		p.Department = department;
		p.Position = "Manager";
		p.Rate = employee.Rate;
		p.Compensation = monthlyRate;
		p.InHand = employee.InHand;
		params.Employees.Add ( p );
	enddo;
	params.Date = BegOfMonth ( this.Date );
	Call ( "Documents.Hiring.Create", params );
	#endregion
	
	RegisterEnvironment ( id );

EndProcedure

Function getEmployees ()

	id = this.ID;
	dateStart = BegOfMonth ( this.Date )-86400;
	dateEnd = Date ( 1, 1, 1 );
	employees = new Array ();
	employees.Add ( newEmployee ( "Employee1 " + id, dateStart, dateEnd, 10000, false ) );
	employees.Add ( newEmployee ( "Employee2 " + id, dateStart, dateEnd, 10000, true ) );
	return employees;

EndFunction

Function newEmployee ( Name, DateStart, DateEnd, Rate, InHand )

	p = new Structure ( "Name, DateStart, DateEnd, Rate, InHand" );
	p.Name = Name;
	p.DateStart = DateStart;
	p.DateEnd = DateEnd;
	p.Rate = Rate;
	p.InHand = InHand;
	return p;

EndFunction