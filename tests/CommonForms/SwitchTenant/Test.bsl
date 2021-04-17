// Create Infobase
// Open List of Infobases
// Select infobase
// Check if selection was ok

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2B008A47" ) );
getEnv ();
createEnv ();

#region CreateInfobase



#endregion

// *************************
// Procedures
// *************************
Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Infobase1", id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	RegisterEnvironment ( id );

EndProcedure
