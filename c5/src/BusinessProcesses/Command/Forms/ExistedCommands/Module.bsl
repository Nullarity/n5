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
Procedure NewCommand ( Command )
	
	createCommand ();
	
EndProcedure

&AtClient
Procedure createCommand ()
	
	callback = new NotifyDescription ( "CommandClosed", ThisObject );
	values = new Structure ( "Source", Parameters.Source );
	OpenForm ( "BusinessProcess.Command.ObjectForm", new Structure ( "FillingValues", values ), ThisObject, , , , callback );
	
EndProcedure

&AtClient
Procedure CommandClosed ( Result, Params ) export
	
	Close ();
	
EndProcedure
