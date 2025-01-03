﻿// Calculate salary when employee has regular salary and addon on the Payroll level
// The addon should be calculated in "reverse" mode
// - Create two compensations: Monthly Payment (standard) and Bonus
// - Hire an employee
// - Create a Payroll & check amount
Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A0DL" ) );
getEnv ();
createEnv ();

#region createAndFillPayroll
Commando ( "e1cib/data/Document.Payroll" );
Put ("#Company", this.Company);
Click("#Button0", "1?:*"); // Yes
Put("#Date", this.Date);

Activate ( "#Additions" );
Additions = Get ( "#Additions" );
for each employee in this.Employees do
	Click ( "#AdditionsAdd" );
	Additions.EndEditRow ();
	Put ( "#AdditionsEmployee", employee.Name, Additions );
	Put ( "#AdditionsCompensation", this.Bonus, Additions );
	Set ( "#AdditionsRate", employee.BonusRate, Additions );
	Click ( "#AdditionsInHand", Additions );
enddo;

Click ( "#Fill" );
With ();
Click ( "#FormFill" );
Pause ( __.Performance * 4 );
With ();
Click("#FormPost");
Check ( "#Totals / Amount [ 1 ]", 13658.85 );
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

	#region newCompensations
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	compensation = this.MonthlyRate;
	p.Description = compensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	bonusCompensation = this.Bonus;
	p.Description = bonusCompensation;
	p.Method = "Fixed Amount";
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
	base.Add ( bonusCompensation );
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
	base.Add ( bonusCompensation );
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
	base.Add ( bonusCompensation );
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
		p.InHand = true;
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
	dateStart = BegOfYear ( date )-86400;
	dateEnd = Date ( 1, 1, 1 );
	employees = new Array ();
	employees.Add ( newEmployee ( "Employee " + id, dateStart, dateEnd, 10000 ) );
	return employees;

EndFunction

Function newEmployee ( Name, DateStart, DateEnd, Rate )

	p = new Structure ( "Name, DateStart, DateEnd, Rate, BonusRate" );
	p.Name = Name;
	p.DateStart = DateStart;
	p.DateEnd = DateEnd;
	p.Rate = Rate;
	p.BonusRate = 2000;
	return p;

EndFunction
