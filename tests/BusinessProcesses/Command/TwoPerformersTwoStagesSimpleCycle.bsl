// Create Command: 1 Performer 2 Stages
// Run a new 1C session with Performer
// Open & complete all tasks
// Connect to the Creator's session
// Open tasks and complete all of them

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2D091DAE" );
env = getEnv ( id );

createCommand(env);
run1c (env);
Connect ( , Env.PerformerPort );
completeAll (env, 1);
Disconnect(true);
Connect(, env.CreatorPort);
completeAll (env, 2);
checkFinish ( id );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Responsible", "admin" );
	p.Insert ( "Performer", "accountant" );
	p.Insert ( "CommandDescription", "Change contract date " + ID );
	port = AppData.Port;
	p.Insert ( "CreatorPort", port );
	p.Insert ( "PerformerPort", port + 1 );
	p.Insert ( "Infobase", __.IBase );
	return p;
	
EndFunction

Procedure createCommand(Env)
	
	// Create Command
	Commando("e1cib/command/BusinessProcess.Command.Create");
	form = With();
	Set("#Description", env.CommandDescription);
	
	// Set performer
	table = Get("#Performers");
	stage = 1;
	for i = 1 to 2 do
		Click ( "#PerformersAdd" );
		Choose ( "#PerformersPerformer" );
		With("Select data type");
		GotoRow("#TypeTree", "", "Users");
		Click ( "#OK" );
		Close ( "Users" );
		With(form);
		Put ( "#PerformersPerformer", env.Performer );
		Next();
		Set("#PerformersStage", stage, table);
		Click ( "#PerformersAdd" );
		Choose ( "#PerformersPerformer" );
		With("Select data type");
		GotoRow("#TypeTree", "", "Users");
		Click ( "#OK" );
		Close ( "Users" );
		With(form);
		Put ( "#PerformersPerformer", env.Performer );
		Next();
		Set("#PerformersStage", stage, table);
		stage = stage + 1;
	enddo;
	Click ( "#FormStartAndClose" );
	
EndProcedure

Procedure run1c (Env)
	
	// Run a new 1C session with Performer
	Disconnect();
	performerPort = Env.PerformerPort;
	try
		Connect ( , performerPort );
		connected = true;
	except
		connected = false;	
	endtry;
	if ( connected ) then
		CloseAll();
		Disconnect(true);
	endif;
	p = Call ("Tester.Run.Params");
	p.User = Env.Performer;
	p.IBase = Env.Infobase;
	p.Port = performerPort;
	p.Parameters = "/Z 0C931F556B";
	Call("Tester.Run", p);
	
EndProcedure

Procedure completeAll(Env, Method)
	
	// Method 1: 4 tasks, because each performer is mandatory
	// Method 2: 2 tasks will be completed in one shot
	for i = 1 to ? ( Method = 1, 4, 1 ) do
		openTask();
		Click("#FormComplete", "Change contract date *");
		if ( Method = 1 ) then
			Click("OK", "Notes");
		else // Final competion
			Click("Yes", DialogsTitle);
		endif;
	enddo;
	
EndProcedure

Procedure openTask ()
	
	With("*20*");
	if ( not Get("#Panel").CurrentVisible () ) then
		Click("#ShowPanel");
	endif;
	Click("#UserTasksContextMenuRefresh");
	table = Get("#UserTasks");
	try
		table.GotoFirstRow();
	except
	endtry;
	table.Choose();
	
EndProcedure

Procedure checkFinish ( ID )
	
	// Open Commands list and check if Command is completed
	Call ( "BusinessProcesses.Command.ListByDescription", ID );
	Check("#Completed", "Yes");
	
EndProcedure