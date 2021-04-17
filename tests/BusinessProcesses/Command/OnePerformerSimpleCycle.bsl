// Create Command: 1 Performer
// Run a new 1C session with Performer
// Open & complete his task
// Close 1C
// Open task, check status and complete the process
// Open Commands list and check if Command is completed

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27B62AC3" );
env = getEnv ( id );

// Create Command
Commando("e1cib/command/BusinessProcess.Command.Create");
form = With();
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
port = env.Port;
try
	Connect ( , port );
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
p.Parameters = "/Z FFD0B42561";
p.Port = port;
Call("Tester.Run", p);

// Open & complete his task
Commando("e1cib/list/Task.UserTask");
With();
Click("#FormChange");
Click("#FormComplete", "Change contract date *");
Click("OK", "Notes");
Disconnect(true);
Connect(, AppData.Port);

// Open task, check status and complete process
Commando("e1cib/list/Task.UserTask");
tasksList = With();
Click("#FormChange");
Click("#FormComplete", "Change contract date *");
Click("Yes", DialogsTitle);

// Open Commands list and check if Command is completed
Commando("e1cib/list/BusinessProcess.Command");
With();
Check("#Completed", "Yes");

// Check completed task
With(tasksList);
Click("#FormChange");
With("Change contract date *");
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
	p.Insert ( "CommandDescription", "Change contract date" );
	p.Insert ( "Port", AppData.Port + 1 );
	p.Insert ( "Infobase" );
	p.Infobase = AppName;
	return p;
	
EndFunction
