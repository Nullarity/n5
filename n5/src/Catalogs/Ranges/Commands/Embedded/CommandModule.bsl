
&AtClient
Procedure CommandProcessing ( Item, ExecuteParameters )

	p = new Structure ( "Item", Item );
	OpenForm ( "Catalog.Ranges.ListForm", new Structure ( "Filter", p ), ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );

EndProcedure
