
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )

	OpenForm ( "Catalog.Items.ListForm", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
