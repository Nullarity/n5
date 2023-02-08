
&AtClient
Procedure CommandProcessing ( Item, ExecuteParameters )

	p = new Structure ( "Owner", Item );
	OpenForm ( "Catalog.Series.ListForm", new Structure ( "Filter", p ), ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );

EndProcedure
