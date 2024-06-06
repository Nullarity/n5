
&AtClient
Procedure CommandProcessing ( PurchaseOrder, CommandExecuteParameters )
	
	openReport ( PurchaseOrder, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openReport ( PurchaseOrder, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "PurchaseOrder" );
	p.Filters = new Array ();
	p.Filters.Add ( DC.CreateParameter ( "Ref", PurchaseOrder ) );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure 