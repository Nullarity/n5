
&AtClient
Procedure CommandProcessing ( Item, ExecuteParameters )
	
	p = new Structure ( "Item", Item );
	OpenForm ( "Catalog.Features.ListForm", p, ExecuteParameters.Source, ExecuteParameters.Uniqueness,
		ExecuteParameters.Window, ExecuteParameters.URL );
	
EndProcedure
