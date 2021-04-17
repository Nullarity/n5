// - Create Employee
// - Create Compensation
// - Create Sick Compensation
// - Create Sick Leave (01.01.2019 - 05.01.2019)
// - Create Sick Leave (03.01.2019 - 10.01.2019) and check intersection error occur
// - Create Sick Leave (07.01.2019 - 12.01.2019) and check intersection error not occur
// - Create Sick Leave and check filling when click "Extension"

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B6AA076" );
env = getEnv ( id );
createEnv ( env );

// **********************************
// Intersection Error Occur
// **********************************

Commando ( "e1cib/command/Document.SickLeave.Create" );
Set ( "#Employee", env.Employee );
Set ( "#DateStart", "01/03/2019" );
Set ( "#DateEnd", "01/10/2019" );
Set ( "#SeniorityAmendment", 80 );
Set ( "#Compensation", env.SickCompensation );
Click ( "#FormPostAndClose" );
Click ( "OK", Forms.Get1C () );
errors = FindMessages ( "*already exists*" );
if ( errors.Count () = 0 ) then
	Stop ( "Expected periods intersection error" );	
endif;
Close ();
With ();
Click ( "No" );

// **********************************
// Intersection Error Not Occur
// **********************************

Commando ( "e1cib/command/Document.SickLeave.Create" );
Set ( "#Employee", env.Employee );
Set ( "#DateStart", "01/07/2019" );
Set ( "#DateEnd", "01/12/2019" );
Set ( "#SeniorityAmendment", 80 );
Set ( "#Compensation", env.SickCompensation );
Click ( "#FormPostAndClose" );

// **********************************
// Check Extension
// **********************************

Commando ( "e1cib/command/Document.SickLeave.Create" );
Set ( "#Employee", env.Employee );
Click ( "#Extension" );
Check ( "#DateStart", "1/13/2019 12:00:00 AM" );
Check ( "#Compensation", env.SickCompensation );
Close ();
With ();
Click ( "No" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "DateStart", "01/01/2019" );
	p.Insert ( "DateEnd", "01/05/2019" );
	p.Insert ( "Employee", "Employee " + ID );
	p.Insert ( "Compensation", "Monthly " + ID );
	p.Insert ( "SickCompensation", "Sick Days " + ID );
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

	// *************************
	// Create Compensation
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Compensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );

	// ****************************
	// Create Sick Compensation
	// ****************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.SickCompensation;
	p.Method = "Sick Days";
	p.Base.Add ( Env.Compensation );
	Call ( "CalculationTypes.Compensations.Create", p );
	
	// **********************************
	// Create Sick Leave
	// **********************************

	Commando ( "e1cib/command/Document.SickLeave.Create" );
	Set ( "#Employee", Env.Employee );
	Set ( "#DateStart", Env.DateStart );
	Set ( "#DateEnd", Env.DateEnd );
	Set ( "#SeniorityAmendment", 80 );
	Set ( "#Compensation", Env.SickCompensation );
	Click ( "#FormPostAndClose" );
	
	Call ( "Common.StampData", id );

EndProcedure