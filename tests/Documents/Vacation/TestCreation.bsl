// - Create Employee
// - Create Compensation
// - Create Vacation Compensation
// - Create Vacation (01.01.2019 - 01.02.2019)
// - Create Vacation (15.01.2019 - 15.02.2019) and check intersection error occur
// - Create Vacation (02.02.2019 - 15.02.2019) and check intersection error not occur
// - Check Results

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6AA05C" );
env = getEnv ( id );
createEnv ( env );

// *****************************
// Intersection Error Occur
// *****************************

Commando ( "e1cib/command/Document.Vacation.Create" );
With ( "Vacation (cr*" );
Click ( "#EmployeesAdd" );
Set ( "#EmployeesEmployee", Env.Employee );
Set ( "#EmployeesDateStart", "01/15/2019" );
Set ( "#EmployeesDateEnd", "02/15/2019" );
Put ( "#EmployeesCompensation", Env.VacationCompensation );
Click ( "#FormPostAndClose" );

Click ( "OK", Forms.Get1C () );
errors = FindMessages ( "*already exists*" );
if ( errors.Count () = 0 ) then
	Stop ( "Expected periods intersection error" );	
endif;
Close ();
With ();
Click ( "No" );

// *****************************
// Intersection Error Not Occur
// *****************************

Commando ( "e1cib/command/Document.Vacation.Create" );
With ( "Vacation (cr*" );
Click ( "#EmployeesAdd" );
Set ( "#EmployeesEmployee", Env.Employee );
Set ( "#EmployeesDateStart", "02/02/2019" );
Set ( "#EmployeesDateEnd", "02/15/2019" );
Put ( "#EmployeesCompensation", Env.VacationCompensation );
Click ( "#FormPostAndClose" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "DateStart", "01/01/2019" );
	p.Insert ( "DateEnd", "02/01/2019" );
	p.Insert ( "Employee", "Employee " + ID );
	p.Insert ( "Compensation", "Monthly " + ID );
	p.Insert ( "VacationCompensation", "Vacation " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Employee
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );

	// *****************************
	// Create Compensation
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Compensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );

	// *****************************
	// Create Vacation Compensation
	// *****************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.VacationCompensation;
	p.Method = "Vacation";
	p.Base.Add ( Env.Compensation );
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// *****************************
	// Create Vacation
	// *****************************
	
	Commando ( "e1cib/command/Document.Vacation.Create" );
	With ( "Vacation (cr*" );
	Click ( "#EmployeesAdd" );
	Set ( "#EmployeesEmployee", Env.Employee );
	Set ( "#EmployeesDateStart", Env.DateStart );
	Set ( "#EmployeesDateEnd", Env.DateEnd );
	Put ( "#EmployeesCompensation", Env.VacationCompensation );
	Click ( "#FormPostAndClose" );
	
	Call ( "Common.StampData", id );

EndProcedure