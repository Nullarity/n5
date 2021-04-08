
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )

	OpenForm ( "Document.Payment.ListForm", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
