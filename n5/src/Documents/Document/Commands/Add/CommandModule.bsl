
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )

	OpenForm ( "Document.Document.ObjectForm", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
