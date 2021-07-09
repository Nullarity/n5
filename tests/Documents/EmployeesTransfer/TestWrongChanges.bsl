// Scenario:
// 1. Hire employee with 1 bonus
// 2. Create Employee Transfer and try:
// - change bonus without actual changes
// - add the same bonus
// - remove nonexistent bonus

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "28482382" );
env = getEnv ( id );
createEnv ( env );

// *******************************
// Create a new Employees Transfer
// *******************************

StandardProcessing = false;
Commando ( "e1cib/command/Document.EmployeesTransfer.Create" );
form = With ( "Employees Transfer (cr*" );

Click ( "#EmployeesAdd" );
With ( "Employee" );
Put ( "#Employee", "_Employee1 " + id );

// ****************************************
// Change main compensation without changes
// ****************************************

Put ( "#Currency", __.LocalCurrency ); // Select the same currency
findError ( "*already*", form );

// **********************************
// Return back and add existed bonus1
// **********************************

Click ( "#EmployeesEdit" );
With ( "Employee" );
employee = Env.Employees [ 0 ].Name;
Put ( "#Employee", employee );
addons = Get ( "#ObjectAdditions" );
GotoRow ( addons, "Compensation", Env.Bonus1 );
Put ( "#ObjectAdditionsAction", "Add", addons );
findError ( "*already*", form );

// *****************************************
// Return back and remove nonexistent bonus2
// *****************************************

Click ( "#EmployeesEdit" );
With ( "Employee" );
addons = Get ( "#ObjectAdditions" );
GotoRow ( addons, "Compensation", Env.Bonus1 );
Put ( "#ObjectAdditionsAction", "Remove", addons );
Put ( "#ObjectAdditionsCompensation", Env.Bonus2, addons );
findError ( "*does not have*", form );

Close ();
Click ( "No", Forms.Get1C () );

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
	p.Insert ( "Rate", 3000 );
	p.Insert ( "Employees", getEmployees ( p ) );
	p.Insert ( "Bonus1", "Bonus1 " + id );
	p.Insert ( "Bonus1Rate", 3 );
	p.Insert ( "Bonus2", "Bonus2 " + id );
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
	if ( EnvironmentExists ( id ) ) then
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

	// ****************
	// Create Positions
	// ****************

	position = Env.Position;
	p = Call ( "Catalogs.Positions.Create.Params" );
	p.Description = position;
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

		employees.Add ( p );
	enddo;
	
	date = Env.Date;
	params.Date = date;
	Call ( "Documents.Hiring.Create", params );

	RegisterEnvironment ( id );

EndProcedure

Procedure findError ( Text, Form )
	
	Click ( "#FormOK" );
	With ( Form );
	Click ( "#FormPost" );
	Call ( "Common.CheckPostingError", Text );
	
EndProcedure