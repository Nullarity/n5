
&AtClient
Procedure CommandProcessing ( Source, ExecuteParameters )
	
	OpenForm ( "DocumentJournal.Vendors.ListForm", , ExecuteParameters.Source, ExecuteParameters.Uniqueness,
		ExecuteParameters.Window, ExecuteParameters.URL );
	
EndProcedure
