
&AtClient
Procedure CommandProcessing ( Document, CommandExecuteParameters )
	
	if ( TypeOf ( Document ) = Type ( "DocumentRef.IncomingEmail" ) ) then
		p = new Structure ( "Command, FillingValues", Enum.MailCommandsForward (), new Structure () );
		p.FillingValues.Insert ( "IncomingEmail", Document );
	else
		p = new Structure ( "Command, OutgoingEmail", Enum.MailCommandsForwardOutgoingEmail (), Document );
	endif; 
	OpenForm ( "Document.OutgoingEmail.ObjectForm", p, CommandExecuteParameters.Source, Document, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure
