// Scenario:
// 1. Hire employee with 2 bonuses
// 2. Create Employee Transfer which:
// - change rate of main compensation
// - change bonus1
// - remove bonus2
// - add bonus3

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2CFA92FB" );
env = getEnv ( id );
createEnv ( env );

// *******************************
// Create a new Employees Transfer
// *******************************

Commando ( "e1cib/command/Document.EmployeesTransfer.Create" );
form = With ( "Employees Transfer (cr*" );

Click ( "#EmployeesAdd" );
With ( "Employee" );
Put ( "#Employee", "_Employee1 " + id );

// Check current information
Check ( "#Department", env.Department );
Check ( "#Position", env.Position );
Check ( "#Schedule", env.Schedule );
Check ( "#Compensation", env.MonthlyRate );
Check ( "#Rate", env.Rate );
Check ( "#Currency", __.LocalCurrency );

// Change rate & position
Set ( "#Position", env.NewPosition );
Set ( "#Rate", env.NewRate );

// Change bonus1
addons = Get ( "#ObjectAdditions" );
GotoRow ( addons, "Compensation", Env.Bonus1 );
Put ( "#ObjectAdditionsAction", "Change", addons );
Put ( "#ObjectAdditionsRate", Env.Bonus1NewRate, addons );

// Remove bonus2
GotoRow ( addons, "Compensation", Env.Bonus2 );
Put ( "#ObjectAdditionsAction", "Remove", addons );

// Add bonus3
Click ( "#ObjectAdditionsAdd" );

Put ( "#ObjectAdditionsAction", "Add", addons );
Put ( "#ObjectAdditionsRate", Env.Bonus3Rate, addons );
Put ( "#ObjectAdditionsCompensation", Env.Bonus3, addons );

Click ( "#FormOK" );

// Check records
With ( form );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Emp*" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = BegOfMonth ( CurrentDate () );
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", date );
	p.Insert ( "Department", "Administration" );
	p.Insert ( "Schedule", "General" );
	p.Insert ( "MonthlyRate", "_Monthly " + ID );
	p.Insert ( "Position", "_worker " + ID );
	p.Insert ( "NewPosition", "_manager " + ID );
	p.Insert ( "Rate", 3000 );
	p.Insert ( "NewRate", 3500 );
	p.Insert ( "Employees", getEmployees ( p ) );
	p.Insert ( "Bonus1", "Bonus1 " + id );
	p.Insert ( "Bonus1Rate", 3 );
	p.Insert ( "Bonus1NewRate", 5 );
	p.Insert ( "Bonus2", "Bonus2 " + id );
	p.Insert ( "Bonus2Rate", 15 );
	p.Insert ( "Bonus3", "Bonus3 " + id );
	p.Insert ( "Bonus3Rate", 7 );
	return p;

EndFunction

Function getEmployees ( Env )

	id = Env.ID;
	date = Env.Date;
	dateStart = BegOfMonth ( date );
	dateEnd = Date ( 1, 1, 1 );
	rate = Env.Rate;
	
	employees = new Array ();
	employees.Add ( newEmployee ( "_Employee1 " + id, dateStart, dateEnd, rate ) );
	employees.Add ( newEmployee ( "_Employee2 " + id, dateStart, dateEnd, rate ) );
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

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Employees
	// *************************
	
	for each employee in Env.Employees do
		p = Call ( "Catalogs.Employees.Create.Params" );
		p.Description = employee.Name;
		Call ( "Catalogs.Employees.Create", p );
	enddo;

	// *****************************
	// Create Compensation & Bonuses
	// *****************************
	
	mainCompensation = Env.MonthlyRate;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = mainCompensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );

	bonus1 = Env.Bonus1;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Bonus1;
	p.Method = "Percent";
	Call ( "CalculationTypes.Compensations.Create", p );

	bonus2 = Env.Bonus2;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = bonus2;
	p.Method = "Percent";
	Call ( "CalculationTypes.Compensations.Create", p );

	bonus3 = Env.Bonus3;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = bonus3;
	p.Method = "Percent";
	Call ( "CalculationTypes.Compensations.Create", p );

	// ****************
	// Create Positions
	// ****************

	position = Env.Position;
	p = Call ( "Catalogs.Positions.Create.Params" );
	p.Description = position;
	Call ( "Catalogs.Positions.Create", p );
	p.Description = Env.NewPosition;
	Call ( "Catalogs.Positions.Create", p );
	
	// ******
	// Hiring
	// ******
	
	department = Env.Department;
	schedule = Env.schedule;
	params = Call ( "Documents.Hiring.Create.Params" );
	employees = params.Employees;
	for each employee in Env.Employees do
		// Main compensation
		p = Call ( "Documents.Hiring.Create.Row" );
		p.Employee = employee.Name;
		p.DateStart = Format ( employee.DateStart, "DLF=D" );
		p.DateEnd = Format ( employee.DateEnd, "DLF=D" );
		p.Department = department;
		p.Position = position;
		p.Rate = employee.Rate;
		p.Compensation = mainCompensation;
		p.Schedule = schedule;
		
		// Bonus1
		additions = p.RowsAdditions;
		addon = Call ( "Documents.Hiring.Create.RowAdditional" );
		addon.Compensation = bonus1;
		addon.Rate = Env.Bonus1Rate;
		additions.Add ( addon );

		// Bonus2
		addon = Call ( "Documents.Hiring.Create.RowAdditional" );
		addon.Compensation = bonus2;
		addon.Rate = Env.Bonus2Rate;
		additions.Add ( addon );
		
		employees.Add ( p );
	enddo;
	
	date = Env.Date;
	params.Date = date;
	Call ( "Documents.Hiring.Create", params );

	Call ( "Common.StampData", id );

EndProcedure
