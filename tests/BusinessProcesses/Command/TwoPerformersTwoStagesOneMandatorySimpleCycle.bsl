// Create Command: 2 Performers 2 Stages 1 Mandatory performer on each stage
// Run a new 1C session with Performer
// Open & complete all tasks
// Connect to the Creator's session
// Open tasks and complete all of them

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2D091CF1" );
env = getEnv ( id );

createCommand(env);
run1c (env);
completeAll (env, 1);
Disconnect(true);
Connect(, env.CreatorPort);
completeAll (env, 2);
checkFinish ();

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Responsible", "admin" );
	p.Insert ( "Performer1", "accountant" );
	p.Insert ( "Performer2", "director" );
	p.Insert ( "CommandDescription", "Change contract date" );
	port = AppData.Port;
	p.Insert ( "CreatorPort", port );
	p.Insert ( "PerformerPort", port + 1 );
	p.Insert ( "Infobase" );
	p.Infobase = AppName;
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
		Put ( "#PerformersPerformer", env.Performer1 );
		Next();
		Set("#PerformersStage", stage, table);
		Click ( "#PerformersAdd" );
		Choose ( "#PerformersPerformer" );
		With("Select data type");
		GotoRow("#TypeTree", "", "Users");
		Click ( "#OK" );
		Close ( "Users" );
		With(form);
		Put ( "#PerformersPerformer", env.Performer2 );
		Next ();
		Click("#PerformersMandatory");
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
	p.User = Env.Performer1;
	p.IBase = Env.Infobase;
	p.Port = performerPort;
	p.Parameters = "/Z 0C931F556B";
	Call("Tester.Run", p);
	
EndProcedure

Procedure completeAll(Env, Method)
	
	// Method 1: 2 tasks, because every second performer is not mandatory
	// Method 2: 2 tasks will be completed in one shot
	for i = 1 to ? ( Method = 1, 2, 1 ) do
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

Procedure checkFinish ()
	
	// Open Commands list and check if Command is completed
	Commando("e1cib/list/BusinessProcess.Command");
	With();
	Check("#Completed", "Yes");
	
EndProcedure