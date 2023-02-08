
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = new Structure ( "Customer", CommandParameter );
	OpenForm ( "Document.Timesheet.ListForm", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
