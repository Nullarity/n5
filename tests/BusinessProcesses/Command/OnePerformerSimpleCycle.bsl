// Create Command: 1 Performer
// Run a new 1C session with Performer
// Open & complete his task
// Close 1C
// Open task, check status and complete the process
// Open Commands list and check if Command is completed

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A077" );
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
p.Parameters = "/Z 0C931F556B";
p.Port = port;
Call("Tester.Run", p);

// Open & complete his task
Call ( "Tasks.UserTask.ListByCommand", id );
Click("#FormChange");
Click("#FormComplete", "Change contract date *");
Click("OK", "Notes");
Disconnect(true);
Connect(, AppData.Port);

// Open task, check status and complete process
Call ( "Tasks.UserTask.ListByCommand", id );
tasksList = With();
Click("#FormChange");
Click("#FormComplete", "Change contract date *");
Click("Yes", DialogsTitle);

// Open Commands list and check if Command is completed
Call ( "BusinessProcesses.Command.ListByDescription", id );
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
	p.Insert ( "CommandDescription", "Change contract date " + ID );
	p.Insert ( "Port", AppData.Port + 1 );
	p.Insert ( "Infobase" );
	p.Infobase = AppName;
	return p;
	
EndFunction
