
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	OpenForm ( "Document.Quote.ObjectForm", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
