
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = new Structure ( "Individual", CommandParameter );
	OpenForm ( "Document.TimeEntry.ListForm", new Structure ( "Filter", p ), CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
