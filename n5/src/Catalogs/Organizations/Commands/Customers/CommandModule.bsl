
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	OpenForm ( "Catalog.Organizations.Form.Customers", new Structure ( "UserAction" ), CommandExecuteParameters.Source, "Customers", CommandExecuteParameters.Window );
	
EndProcedure
