
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	OpenForm ( "Catalog.Tenants.Form.Activation", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
