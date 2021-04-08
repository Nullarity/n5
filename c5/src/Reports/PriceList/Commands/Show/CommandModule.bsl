
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	openReport ( CommandParameter, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openReport ( CommandParameter, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "PriceList" );
	p.Filters = new Array ();
	filterItem = DC.CreateFilter ( "Item", , DataCompositionComparisonType.InListByHierarchy );
	filterItem.RightValue = new ValueList ();
	filterItem.RightValue.LoadValues ( CommandParameter );
	p.Filters.Add ( filterItem );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure 
