
&AtClient
Procedure CommandProcessing ( Emails, CommandExecuteParameters )
	
	deleteEmails ( Emails );
	NotifyChanged ( TypeOf ( Emails [ 0 ] ) );
	Notify ( Enum.MessageEmailDeleted () );
	closeDocument ( CommandExecuteParameters.Source );
	
EndProcedure

&AtServer
Procedure deleteEmails ( val Emails )
	
	MailboxesSrv.DeleteDocuments ( Emails );
	startDeletion ( Emails );
	
EndProcedure 

&AtServer
Procedure startDeletion ( Emails )
	
	jobKey = "DeleteEmails" + UserName ();
	p = new Array ();
	p.Add ( jobKey );
	p.Add ( Emails );
	Jobs.Run ( "MailboxesSrv.DeleteEmails", p, jobKey );
	
EndProcedure 

&AtClient
Procedure closeDocument ( Form )
	
	formName = Form.FormName;
	if ( formName = "Document.IncomingEmail.Form.Form"
		or formName = "Document.OutgoingEmail.Form.Form" ) then
		Form.Close ();
	endif;
	
EndProcedure 
