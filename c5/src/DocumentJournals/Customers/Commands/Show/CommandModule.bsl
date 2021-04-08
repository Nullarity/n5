
&AtClient
Procedure CommandProcessing ( Customer, ExecuteParameters )
	
	p = new Structure ( "Customer", Customer );
	OpenForm ( "DocumentJournal.Customers.ListForm", new Structure ( "Filter", p ), ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );
	
EndProcedure
