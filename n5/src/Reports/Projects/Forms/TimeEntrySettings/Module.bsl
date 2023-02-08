// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setFieldsByDefault ();
	
EndProcedure

&AtServer
Procedure setFieldsByDefault ()
	
	FilterByProject = true;
	FilterByPerformer = true;
	FilterByTasks = true;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	Close ( getParams () );
	
EndProcedure

&AtClient
Function getParams ()
	
	p = new Structure ();
	p.Insert ( "FilterByPerformer", FilterByPerformer );
	p.Insert ( "FilterByTasks", FilterByTasks );
	return p;
	
EndFunction 