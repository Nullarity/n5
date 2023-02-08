// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setFilter ();
	
EndProcedure

&AtServer
Procedure setFilter ()
	
	DC.SetFilter ( List, "Source", Parameters.Source );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure NewTask ( Command )
	
	createTask ();
	
EndProcedure

&AtClient
Procedure createTask ()
	
	callback = new NotifyDescription ( "TaskClosed", ThisObject );
	values = new Structure ( "Source", Parameters.Source );
	OpenForm ( "Task.UserTask.ObjectForm", new Structure ( "FillingValues", values ), ThisObject, , , , callback );
	
EndProcedure

&AtClient
Procedure TaskClosed ( Result, Params ) export
	
	Close ();
	
EndProcedure
