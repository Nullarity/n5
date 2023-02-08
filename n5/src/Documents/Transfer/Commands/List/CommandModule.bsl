
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	OpenForm ( "Document.Transfer.ListForm", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
