
&AtClient
Procedure CommandProcessing ( CommandParameter, ExecuteParameters )
	
	OpenForm ( "Catalog.Servers.ListForm", , ExecuteParameters.Source,
		ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );
		
EndProcedure
