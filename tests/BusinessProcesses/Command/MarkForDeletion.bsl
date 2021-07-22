// Create Command
// Open list and mark for deletion

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "273350D9" );
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

// Open Commands list and mark for deletion
Call ( "BusinessProcesses.Command.ListByDescription", id );
Click("#FormSetDeletionMark");
Click("Yes", "1?:*");

// Check deletion irreversibility
Click("#FormSetDeletionMark");
Click("Yes", "1?:*");

// This closing window should contain the text: Failed to save "Command..."
Close("1?:*");
Close("Internal Commands");

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Responsible", "admin" );
	p.Insert ( "Performer", "accountant" );
	p.Insert ( "CommandDescription", "Deletion testing " + ID );
	return p;
	
EndFunction

