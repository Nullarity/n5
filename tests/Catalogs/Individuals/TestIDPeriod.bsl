Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Individuals" );
With ( "Individuals" );
GotoRow ( "List", "Description", env.FullName );
Click ( "#FormChange" );
With ( env.FullName + " *" );

Click ( "IDs", GetLinks () );
With ( "IDs" );
Click ( "#FormCreate" );
With ( "Identity Documents (cr*" );

Set ( "#Type", "Passport" );

// Correct period
dateStart = "2/1/2012";
dateEnd = "2/1/2015";
Set ( "#Period", dateStart );
Set ( "#ValidTo", dateEnd );
Click ( "#FormWrite" );

// Wrong "Valid To"
Set ( "#Period", dateEnd );
Set ( "#ValidTo", dateStart );
Click ( "#FormWrite" );

msg = "Period is incorrect";
if ( FindMessages ( msg ).Count () <> 1 ) then
	Stop ( "<" + msg + "> error messages must be shown one time" );
endif;

CloseAll ();

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "250C9D50#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "FirstName", id );
	p.Insert ( "LastName", "L_" + id );
	p.Insert ( "Patronymic", "P_" + id );
	p.Insert ( "FullName", id + " " + p.Patronymic +  " " + p.LastName );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item
	// *************************
	
	createPerson ( Env );

	RegisterEnvironment ( id );

EndProcedure

Procedure createPerson ( Env )

	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Individuals" );
	With ( "Individuals (cr*" );
	Set ( "#FirstName", Env.FirstName );
	Set ( "#LastName", Env.LastName );
	Set ( "#Patronymic", Env.Patronymic );
	Click ( "#FormWriteAndClose" );
	
EndProcedure