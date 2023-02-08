
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )

	OpenForm ( "Document.TimeEntry.ObjectForm", , CommandExecuteParameters.Source, true, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
