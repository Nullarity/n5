Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27B8B70C" );
env = getEnv ( id );
createEnv ( env );

// Open reports
Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
list = With ( "Regulatory Reports" );

// Create Report
Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", id );
Pause ( 1 );
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
	Commando ( "e1cib/command/Catalog.Reports.Command.Show" );
	Pause ( 1 );
	list = With ();
	
	// Show masters and create a new one
	Click ( "#ListShowMasters" );
	Click ( "#ListCreate" );
	
	With ( "Regulatory Reports (cr*" );
	
	Set ( "#Description", id );
	Set ( "#Name", id );
	
	Click ( "#FormWriteAndClose" );
	Pause ( 1 );
	
	// Design report
	With ( list );
	Click ( "#Design" );
	p = Call ( "RegulatoryReports.Load.Params" );
	p.Path = "RegulatoryReports.CreateMasterReport.Example";
	Call ( "RegulatoryReports.Load", p );
	
	// Save and build
	Click ( "#Build" );
	
	Close ();
	
	RegisterEnvironment ( id );
	
EndProcedure
