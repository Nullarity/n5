
&AtClient
Procedure CommandProcessing ( Item, ExecuteParameters )
	
	p = new Structure ( "Filter", new Structure ( "Item", Item ) );
	OpenForm ( "Catalog.BOM.ListForm", p, ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );
	
EndProcedure
