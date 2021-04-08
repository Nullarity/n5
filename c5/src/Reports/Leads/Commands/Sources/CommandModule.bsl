
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	openReport ( CommandParameter, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openReport ( CommandParameter, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "Leads" );
	p.Variant = "#Sources";
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure 
