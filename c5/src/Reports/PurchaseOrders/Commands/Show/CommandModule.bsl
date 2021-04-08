
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "PurchaseOrders" );
	p.Filters = new Array ();
	filterItem = DC.CreateFilter ( "Vendor" );
	filterItem.RightValue = CommandParameter;
	p.Filters.Add ( filterItem );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure
