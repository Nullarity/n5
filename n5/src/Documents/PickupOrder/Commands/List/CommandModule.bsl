
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	OpenForm ( "Document.PickupOrder.ListForm", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
