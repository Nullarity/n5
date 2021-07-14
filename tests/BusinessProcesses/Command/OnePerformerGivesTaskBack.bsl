// Create Command: 1 Performer
// Run a new 1C session with Performer
// Open & give his task back
// Connect to the Creator's session
// Open task, check status and return it to Performer with additional details
// Connect to the Performer's session
// Open & complete his task this time
// Close Performer's session
// Connect to the Creator's session
// Open task, check status and complete it
// Open Commands list and check if Command is completed

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A076" );
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
Disconnect();
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

// Open & give his task back
Call ( "Tasks.UserTask.ListByCommand", id );
Click("#FormChange");
Click("#FormGiveBack", "Change cont*");
With("Reason for Return");
Set("#Reason", "No much info");
Click("#FormOK");

// Connect to the Creator's session
Disconnect();
creatorPort = env.CreatorPort;
Connect(, creatorPort);

// Open task, check status and return it to Performer with additional details
Call ( "Tasks.UserTask.ListByCommand", id );
Click("#FormChange");
Click("#FormRepeat", "No much info *");
With("Notes");
Set("#Notes", "Add more info");
Click("#FormOK");
Close("User Tasks");

// Connect to the Performer's session
Connect(, performerPort);

// Open & complete his task this time
Close("User Tasks");
Call ( "Tasks.UserTask.ListByCommand", id );
Click("#FormChange");
Click("#FormComplete", "Add more info *");
Click("OK", "Notes");

// Close Performer's session
Disconnect(true);

// Connect to the Creator's session
Connect(, creatorPort);

// Open task, check status and complete it
Call ( "Tasks.UserTask.ListByCommand", id );
Click("#FormChange");
Click("#FormComplete","Add more info *");
Click("Yes", DialogsTitle);

// Open Commands list and check if Command is completed
Commando("e1cib/list/BusinessProcess.Command");
With("Internal Commands");
Check("#Completed", "Yes");

// Check completed task
With("User Tasks");
Click("#FormChange");
With("Add more info *");
CheckState("#Memo, #Section, #Appearance", "ReadOnly");
CheckState("#FormComplete, #FormDelete, #FormGiveBack, #FormRepeat, #FormTerminate", "Visible", false);

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
	p.Insert ( "Infobase" );
	p.Infobase = AppName;
	return p;
	
EndFunction
