
&AtClient
Procedure CommandProcessing ( Parameter, CommandExecuteParameters )
	
	openReport ( Parameter, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openReport ( Item, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "Stock" );
	p.Filters = new Array ();
	filter = DC.CreateFilter ( "Item", , DataCompositionComparisonType.InListByHierarchy );
	filter.RightValue = new ValueList ();
	filter.RightValue.LoadValues ( Item );
	p.Filters.Add ( filter );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure 