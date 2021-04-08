
&AtClient
Procedure CommandProcessing ( Emails, CommandExecuteParameters )
	
	markAsNew ( Emails );
	Notify ( Enum.MessageNewMail () );
	
EndProcedure

&AtServer
Procedure markAsNew ( val Emails )
	
	for each email in Emails do
		Documents.IncomingEmail.MarkAsNew ( email );
	enddo; 
	
EndProcedure 
