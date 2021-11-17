Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "286E30ED" );
__.Insert ( "CurrentID", id );
env = getEnv ( id );
createEnv ( env );

// ***********************************
// Create Report for Junuary
// ***********************************

// Open reports
Commando ( "e1cib/command/Catalog.Reports.Command.Show", false );
Pause(2);
list = With ( "Regulatory Reports" );

// Create Report
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", id );
Click ( "#FormChoose" );

// Select period
With ( list );
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Set ( "#DateBegin", "01/01/2017" );
Set ( "#DateEnd", "01/31/2017" );
Click ( "#Select" );

// Check fields calculation
With ( list );
Set ( "#ReportField [R1C2]", 1 );
Set ( "#ReportField [R2C2]", 2 );
Check ( "#ReportField [R3C2]", 3 );

// ***********************************
// Create Report for February
// ***********************************

CloseAll ();

// Open reports
Commando ( "e1cib/command/Catalog.Reports.Command.Show", false );
Pause(2);
list = With ( "Regulatory Reports" );

// Create Report
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", id );
Click ( "#FormChoose" );

// Select period
With ( list );
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Set ( "#DateBegin", "02/01/2017" );
Set ( "#DateEnd", "02/28/2017" );
Click ( "#Select" );

// Check fields calculation
With ( list );
Set ( "#ReportField [R1C2]", 3 );
Set ( "#ReportField [R2C2]", 4 );
Check ( "#ReportField [R3C2]", 7 );
Check ( "#ReportField [R1C6]", 3 );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Master Report
	// *************************
	
	// Open reports
	Commando ( "e1cib/command/Catalog.Reports.Command.Show", false );
	Pause(2);
	list = With ( "Regulatory Reports" );
	
	// Show masters and create a new one
	Click ( "#ListShowMasters" );
	Click ( "#ListCreate" );
	
	With ( "Regulatory Reports (cr*" );
	
	Set ( "#Description", id );
	Set ( "#Name", id );
	
	Click ( "#FormWriteAndClose" );
	
	// Design report
	With ( list );
	Pause ( 1 );
	Click ( "#Design" );
	p = Call ( "RegulatoryReports.Load.Params" );
	p.Path = "RegulatoryReports.CreateLinkedReports.Example";
	p.BeforeSavingScript = "RegulatoryReports.CreateLinkedReports.ChangeIDofReportModule";
	Call ( "RegulatoryReports.Load", p );
	
	// Save and build
	Click ( "#Build" );
	
	Close ();
	
	RegisterEnvironment ( id );
	
EndProcedure
