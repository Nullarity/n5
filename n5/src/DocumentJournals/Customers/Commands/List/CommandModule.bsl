
&AtClient
Procedure CommandProcessing ( Source, ExecuteParameters )
	
	OpenForm ( "DocumentJournal.Customers.ListForm", , ExecuteParameters.Source, ExecuteParameters.Uniqueness,
		ExecuteParameters.Window, ExecuteParameters.URL );
	
EndProcedure
