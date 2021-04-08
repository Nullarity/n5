
&AtClient
Procedure CommandProcessing ( IncomingEmail, CommandExecuteParameters )

	openList ( IncomingEmail, CommandExecuteParameters )
	
EndProcedure

&AtClient
Procedure openList ( IncomingEmail, CommandExecuteParameters )
	
	p = new Structure ( "Filter", new Structure () );
	p.Filter.Insert ( "IncomingEmail", IncomingEmail );
	OpenForm ( "Document.OutgoingEmail.ListForm", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure 
