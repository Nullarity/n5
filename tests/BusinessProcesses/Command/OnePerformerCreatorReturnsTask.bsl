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

id = Call ( "Common.ScenarioID", "27E763F0" );
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
p.Parameters = "/len /Z""FFD0B42561""";
Call("Tester.Run", p);

// Open & complete his task
Commando("e1cib/list/Task.UserTask");
With("User Tasks");
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
Commando("e1cib/list/Task.UserTask");
With("User Tasks");
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
Commando("e1cib/list/Task.UserTask");
With("User Tasks");
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
Commando("e1cib/list/Task.UserTask");
With("User Tasks");
Click("#FormChange");
With ();
Click("#FormComplete");
With ();
//Click("#FormOK");
Click("Yes", DialogsTitle);

// Open Commands list and check if Command is completed
Commando("e1cib/list/BusinessProcess.Command");
With("Internal Commands");
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
	p.Insert ( "CommandDescription", "Change contract date" );
	port = AppData.Port;
	p.Insert ( "CreatorPort", port );
	p.Insert ( "PerformerPort", port + 1 );
	p.Insert ( "Infobase" );
	if ( __.TestServer ) then
		p.Infobase = "Core, develop";
	else
		p.Infobase = "Core, sources";
	endif;
	return p;
	
EndFunction
