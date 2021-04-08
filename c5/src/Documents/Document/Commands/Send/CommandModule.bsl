
&AtClient
Procedure CommandProcessing ( Items, CommandExecuteParameters )
	
	if ( not checkDoubles ( Items ) ) then
		Output.DocumentFilesDuplicate ();
	else
		if ( MailChecking.ProfileExists () ) then
			openOutgoingEmail ( Items, CommandExecuteParameters );
		else
			Output.MailboxIsNotConfigured ( ThisObject );
		endif; 
	endif; 
	
EndProcedure

&AtServer
Function checkDoubles ( val Items )
	
	s = "
	|select top 1 1
	|from InformationRegister.Files as Files
	|where Files.Document in ( &Documents )
	|group by Files.File
	|having count ( distinct Files.File ) > 1
	|";
	q = new Query ( s );
	q.SetParameter ( "Documents", Items );
	return q.Execute ().IsEmpty ();
	
EndFunction 

&AtClient
Procedure openOutgoingEmail ( Items, CommandExecuteParameters )
	
	p = new Structure ();
	p.Insert ( "Command", Enum.MailCommandsSendDocuments () );
	p.Insert ( "Documents", Items );
	OpenForm ( "Document.OutgoingEmail.ObjectForm", p, CommandExecuteParameters.Source, , CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure 

&AtClient
Procedure MailboxIsNotConfigured ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	else
		OpenForm ( "Catalog.Mailboxes.ObjectForm" );
	endif; 
	
EndProcedure 
