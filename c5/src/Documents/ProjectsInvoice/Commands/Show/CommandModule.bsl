
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	openList ( CommandParameter, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openList ( CommandParameter, CommandExecuteParameters )
	
	p = new Structure ( "Filter", new Structure () );
	p.Filter.Insert ( "Customer", CommandParameter );
	OpenForm ( "Document.Invoice.ListForm", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure 
