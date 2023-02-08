
&AtClient
Procedure CommandProcessing ( Parameter, CommandExecuteParameters )
	
	openReport ( Parameter, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openReport ( Value, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "VendorInvoices" );
	p.Filters = new Array ();
	if ( isItem ( Value ) ) then
		p.Variant = "#ByItems";
		filter = DC.CreateFilter ( "Item", Value );
	else
		filter = DC.CreateFilter ( "Ref", Value );
	endif;
	p.Filters.Add ( filter );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure

&AtClient
Function isItem ( Value )

	item = ? ( TypeOf ( Value ) = Type ( "Array" ), Value [ 0 ], Value );
	return TypeOf ( item ) = Type ( "CatalogRef.Items" );
	
EndFunction
