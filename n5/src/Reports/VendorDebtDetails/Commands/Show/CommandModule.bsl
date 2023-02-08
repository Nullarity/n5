
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "VendorDebtDetails" );
	p.Filters = new Array ();
	parameterType = TypeOf ( CommandParameter );
	if ( parameterType = Type ( "CatalogRef.Organizations" ) ) then
		filterItem = DC.CreateFilter ( "Vendor" );
	else
		filterItem = DC.CreateFilter ( "Document" );
	endif; 
	filterItem.RightValue = CommandParameter;
	p.Filters.Add ( filterItem );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure
