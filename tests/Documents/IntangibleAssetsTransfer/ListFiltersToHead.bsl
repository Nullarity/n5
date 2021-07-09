// Description:
// Set filters in document list form and create a new document.
// Checks the automatic header filling process

Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

Commando ( "e1cib/list/Document.IntangibleAssetsTransfer" );
With ( "Intangible Assets Transfers" );

Set ( "#SenderFilter", Env.Sender );
Set ( "#ResponsibleFilter", Env.Responsible );

Click ( "#FormCreate" );
With ( "Intangible Assets Transfer (create)" );
Check ( "#Sender", Env.Sender );
Check ( "#Responsible", Env.Responsible );

// ****************************
// Procedures
// ****************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "618472079#" );
	env = new Structure ();
	env.Insert ( "ID", id );
	env.Insert ( "Sender", "_Division " + id );
	env.Insert ( "Responsible", "_Employee " + id );
	return env;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Sender;
	Call ( "Catalogs.Departments.Create", p );
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Responsible;
	Call ( "Catalogs.Employees.Create", p );

	RegisterEnvironment ( id );

EndProcedure
