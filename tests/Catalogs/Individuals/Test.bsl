Call ( "Common.Init" );
CloseAll ();

env = getEnv ();

MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Individuals" );
list = With ( "Individuals" );
Click ( "#FormCreate" );

With ( "Individuals (cr*" );

// Address field should be disabled for new objects
CheckState ( "#Write", "Visible" );
CheckState ( "#Address", "Enable", false );

fill ( Env );
Click ( "#FormWrite" );

// Address field should be enabled
CheckState ( "#Write", "Visible", false );
CheckState ( "#Address", "Enable", true );

Close ();

// Create a new object with the same names
With ( list );
Click ( "#FormCreate" );

form = With ( "Individuals (cr*" );

fill ( Env );

Click ( "#FormWrite" );
With ( );
Click ( "Yes" );

With ( form );

// Check the same message for saving existed object
Click ( "#FormWrite" );
With ( );
Click ( "Yes" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "25145D6A#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "FirstName", id );
	p.Insert ( "LastName", "L_" + id );
	p.Insert ( "Patronymic", "P_" + id );
	return p;

EndFunction

Procedure fill ( Env )

	Set ( "#FirstName", Env.FirstName );
	Set ( "#LastName", Env.LastName );
	Set ( "#Patronymic", Env.Patronymic );
	
EndProcedure