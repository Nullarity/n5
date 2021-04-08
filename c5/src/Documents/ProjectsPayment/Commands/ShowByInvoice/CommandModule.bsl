
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	openList ( CommandParameter, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openList ( CommandParameter, CommandExecuteParameters )
	
	p = new Structure ( "Filter", new Structure () );
	p.Filter.Insert ( "Invoice", CommandParameter );
	OpenForm ( "Document.ProjectsPayment.ListForm", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure 