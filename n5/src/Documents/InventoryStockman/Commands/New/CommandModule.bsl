
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	OpenForm ( "Document.InventoryStockman.ObjectForm", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
