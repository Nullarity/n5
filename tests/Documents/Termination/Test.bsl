Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25A6C2B6" );
env = getEnv ( id );
createEnv ( env );

// *************************
// Create Termination
// *************************

Commando ( "e1cib/command/Document.Termination.Create" );
With ( "Termination (cr*" );

terminationDate = Format ( EndOfMonth ( env.Date ), "DLF=D" );
for each row in env.Employees do
	Click ( "#EmployeesAdd" );
	Set ( "#EmployeesEmployee", row.Name );
	Set ( "#EmployeesDate", terminationDate );
enddo;

Click ( "#FormPost" );

// Copy document and check error message
Click ( "#FormCopy" );
With ( "Termination (cr*" );
Click ( "#FormPost" );
Call ( "Common.CheckPostingError", "_Employee1* already terminated" );
Close ();

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	date = CurrentDate ();
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", date );
	p.Insert ( "Department", "_Department " + ID );
	p.Insert ( "Employees", getEmployees ( p ) );
	p.Insert ( "MonthlyRate", "_Monthly " + ID );
	return p;

EndFunction

Function getEmployees ( Env )

	id = Env.ID;
	date = Env.Date;
	dateStart = BegOfMonth ( date );
	dateEnd = Date ( 1, 1, 1 );
	
	employees = new Array ();
	employees.Add ( newEmployee ( "_Employee1 " + id, dateStart, dateEnd, 1000, 2 ) );
	employees.Add ( newEmployee ( "_Employee2 " + id, dateStart, dateEnd, 1000, 5 ) );
	return employees;

EndFunction

Function newEmployee ( Name, DateStart, DateEnd, Rate, Overtime )

	p = new Structure ( "Name, DateStart, DateEnd, Rate, Overtime" );
	p.Name = Name;
	p.DateStart = DateStart;
	p.DateEnd = DateEnd;
	p.Rate = Rate;
	p.Overtime = Overtime;
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

	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );

	// *************************
	// Create Compensation
	// *************************
	
	mainCompensation = Env.MonthlyRate;
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = mainCompensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );

	// *************************
	// Hiring
	// *************************
	
	department = Env.Department;
	params = Call ( "Documents.Hiring.Create.Params" );
	employees = params.Employees;
	for each employee in Env.Employees do
		// Main compensation
		p = Call ( "Documents.Hiring.Create.Row" );
		p.Employee = employee.Name;
		p.DateStart = Format ( employee.DateStart, "DLF=D" );
		p.DateEnd = Format ( employee.DateEnd, "DLF=D" );
		p.Department = department;
		p.Position = "Manager";
		p.Rate = employee.Rate;
		p.Compensation = mainCompensation;

		employees.Add ( p );
	enddo;
	
	date = Env.Date;
	params.Date = date;
	Call ( "Documents.Hiring.Create", params );
	
	Call ( "Common.StampData", id );

EndProcedure

