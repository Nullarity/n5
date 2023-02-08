
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	OpenForm ( "Catalog.Organizations.Form.Vendors", , CommandExecuteParameters.Source, "Vendors", CommandExecuteParameters.Window );
	
EndProcedure
