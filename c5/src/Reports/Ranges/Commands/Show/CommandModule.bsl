
&AtClient
Procedure CommandProcessing ( Parameter, CommandExecuteParameters )
	
	openReport ( Parameter, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openReport ( Item, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "Ranges" );
	p.Filters = new Array ();
	filter = DC.CreateFilter ( "Range", Item );
	p.Filters.Add ( filter );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure 