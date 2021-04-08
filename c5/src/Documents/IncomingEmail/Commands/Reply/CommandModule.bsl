
&AtClient
Procedure CommandProcessing ( IncomingEmail, CommandExecuteParameters )
	
	p = new Structure ( "Command, FillingValues", Enum.MailCommandsReply (), new Structure () );
	p.FillingValues.Insert ( "IncomingEmail", IncomingEmail );
	OpenForm ( "Document.OutgoingEmail.ObjectForm", p, CommandExecuteParameters.Source, IncomingEmail, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
