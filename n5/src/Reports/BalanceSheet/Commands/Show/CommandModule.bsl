
&AtClient
Procedure CommandProcessing ( Dimension, ExecuteParameters )
	
	p = ReportsSystem.GetParams ( "BalanceSheet" );
	p.Filters = getFilters ( Dimension );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, ExecuteParameters.Source, true, ExecuteParameters.Window );

EndProcedure

&AtClient
Function getFilters ( Dimension )
	
	filters = new Array ();
	filterItem = DC.CreateFilter ( "Dim1", ? ( TypeOf ( Dimension ) = Type ( "CatalogRef.Employees" ),
		DF.Pick ( Dimension, "Individual" ), Dimension ) );
	filters.Add ( filterItem );
	return filters;
	
EndFunction
