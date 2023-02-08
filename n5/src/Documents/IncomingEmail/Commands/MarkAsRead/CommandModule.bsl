
&AtClient
Procedure CommandProcessing ( Emails, CommandExecuteParameters )
	
	markAsRead ( Emails );
	Notify ( Enum.MessageEmailIsRead () );
	
EndProcedure

&AtServer
Procedure markAsRead ( val Emails )
	
	for each email in Emails do
		Documents.IncomingEmail.MarkAsRead ( email );
	enddo; 
	
EndProcedure 
