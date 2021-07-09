Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A4CFA4F" );
env = getEnv ( id );
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/list/Document.Termination" );
With ( "Terminations" );

p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = env.id;
Call ( "Common.Find", p );
With ( "Terminations" );
Click ( "#FormChange" );
With ( "Termination #*" );
Click ( "#FormDocumentTerminationTermination" );
With ( "Termination: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Employee1", "Employee #1: " + ID );
	p.Insert ( "Employee2", "Employee #2: " + ID );
	p.Insert ( "Department1", "Department #1: " + ID );
	p.Insert ( "Department2", "Department #2: " + ID );
	p.Insert ( "Compensation1", "Compensation #1: " + ID );
	p.Insert ( "AdditionalCompensation1", "Additional Compensation #1: " + ID );
	p.Insert ( "Compensation2", "Compensation #2: " + ID );
	p.Insert ( "AdditionalCompensation2", "Additional Compensation #2: " + ID );
	return p;
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
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee1;
	Call ( "Catalogs.Employees.Create", p );
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee2;
	Call ( "Catalogs.Employees.Create", p );
	
	// *************************
	// Create Departments
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department1;
	Call ( "Catalogs.Departments.Create", p );
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department2;
	Call ( "Catalogs.Departments.Create", p );
	
	// *************************
	// Create Compensations
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Compensation1;
	p.Method = "Hourly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.AdditionalCompensation1;
	p.Method = "Fixed Amount";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Compensation2;
	p.Method = "Hourly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.AdditionalCompensation2;
	p.Method = "Fixed Amount";
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// *************************
	// Create Hiring
	// *************************
	
	p = Call ( "Documents.Hiring.Create.Params" );
	date = AddMonth ( p.Date, -1 );
	p.Memo = id;
	p.Employees.Add ( employee ( env.Employee1, date, "Accountant", env.Compensation1, env.AdditionalCompensation1, env.Department1 ) );
	p.Employees.Add ( employee ( env.Employee2, date, "Administrator", env.Compensation2, env.AdditionalCompensation2, env.Department2 ) );
	Call ( "Documents.Hiring.Create", p );

	// *************************
	// Create Termination
	// *************************
	
	MainWindow.ExecuteCommand ( "e1cib/data/Document.Termination" );
	With ( "Termination (create)" );
	date = CurrentDate ();
	Put ( "#Date", date );
	Put ( "#Memo", id );
	table = Activate ( "#Employees" );
	d = "" + Month ( date ) + "/" + Day ( date ) + "/" + Format ( Year ( date ), "NG=" );
	for each row in p.Employees do
		Click ( "#EmployeesAdd" );
		Put ( "#EmployeesEmployee", row.Employee );
		Put ( "#EmployeesDate", d );
	enddo;
	Click ( "#FormPostAndClose" );
	
	RegisterEnvironment ( id );

EndProcedure

Function employee ( Employee, Date, Position, Compensation, AdditionalCompensation, Department );

	row = Call ( "Documents.Hiring.Create.Row" );
	row.Employee = Employee;
	row.DateStart = Date;
	row.Position = Position;
	row.Compensation = Compensation;
	row.Department = Department;
	r = Call ( "Documents.Hiring.Create.RowAdditional" );
	r.Compensation = AdditionalCompensation;
	row.RowsAdditions.Add ( r );
	return row;

EndFunction


