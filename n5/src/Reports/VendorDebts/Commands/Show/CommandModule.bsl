
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "VendorDebts" );
	p.GenerateOnOpen = true;
	p.Filters = new Array ();
	filterItem = DC.CreateFilter ( "Vendor" );
	filterItem.RightValue = CommandParameter;
	p.Filters.Add ( filterItem );
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure
