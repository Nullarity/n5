// Create Command: 1 Performer
// Run a new 1C session with Performer
// Open & complete his task
// Connect to the Creator's session
// Open task, check status and return it to Performer
// Connect to the Performer's session
// Open & complete his task again
// Close Performer's session
// Connect to the Creator's session
// Open task, check status and complete it
// Open Commands list and check if Command is completed

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A078" );
env = getEnv ( id );                                                

// Create Command
Commando("e1cib/command/BusinessProcess.Command.Create");
form = With("Command (create)");
Set("#Description", env.CommandDescription);

// Set performer
Click ( "#PerformersAdd" );
Choose ( "#PerformersPerformer" );
With("Select data type");
GotoRow("#TypeTree", "", "Users");
Click ( "#OK" );
Close ( "Users" );
With(form);
Put ( "#PerformersPerformer", env.Performer );
Click ( "#FormStartAndClose" );

// Run a new 1C session with Performer
performerPort = env.PerformerPort;
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
p.User = env.Performer;
p.IBase = env.Infobase;
p.Port = performerPort;
p.Parameters = "/len /Z""0C931F556B""";
Call("Tester.Run", p);

// Open & complete his task
Call ( "Tasks.UserTask.ListByCommand", id );
Click("#FormChange");
With ();
//Click("#FormComplete","Task *");
Click("#FormComplete");
With ();
//Click("Yes", DialogsTitle);
Click ( "OK" );

// Connect to the Creator's session
Disconnect();
creatorPort = env.CreatorPort;
Connect(, creatorPort);

// Open task, check status and return it to Performer
Call ( "Tasks.UserTask.ListByCommand", id );
Click("#FormChange");
With ();
Click("#FormRepeat");
With("Notes");
Set("#Notes", "Bad result");
Click("#FormOK");
Close("User Tasks");

// Connect to the Performer's session
Connect(, performerPort);

// Open & complete his task again
Close("User Tasks");
Call ( "Tasks.UserTask.ListByCommand", id );
Click("#FormChange");
With ();
Click("#FormComplete");
With ();
Click("#FormOK");

//Click("Yes", DialogsTitle);

// Close Performer's session
Disconnect(true);

// Connect to the Creator's session
Connect(, creatorPort);

// Open task, check status and complete it
Call ( "Tasks.UserTask.ListByCommand", id );
Click("#FormChange");
With ();
Click("#FormComplete");
With ();
//Click("#FormOK");
Click("Yes", DialogsTitle);

// Open Commands list and check if Command is completed
Call ( "BusinessProcesses.Command.ListByDescription", id );
Check("#Completed", "Yes");

// Check completed task
With("User Tasks");
Click("#FormChange");
With();
CheckState("#Memo, #Section, #Appearance", "ReadOnly");
CheckState("#FormComplete, #FormDelete, #FormGiveBack, #FormRepeat, #FormTerminate", "Visible", false);

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Responsible", "admin" );
	p.Insert ( "Performer", "Accountant" );
	p.Insert ( "CommandDescription", "Change contract date " + ID );
	port = AppData.Port;
	p.Insert ( "CreatorPort", port );
	p.Insert ( "PerformerPort", port + 1 );
	p.Insert ( "Infobase" );
	p.Infobase = AppName;
	return p;
	
EndFunction
