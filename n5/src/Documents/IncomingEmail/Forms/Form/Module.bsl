// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	setLabel ();
	markAsRead ();
	loadSizes ();
	showAttachedEmails ();
	Body = EmailsSrv.GetHTML ( Object.Ref, Object.MessageID, Object.Mailbox );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure setLabel ()
	
	Label = MailboxesSrv.GetLabel ( Object.Ref );
	
EndProcedure 

&AtServer
Procedure markAsRead ()
	
	IsNew = Documents.IncomingEmail.IsNew ( Object.Ref );
	if ( IsNew ) then
		Documents.IncomingEmail.MarkAsRead ( Object.Ref );
	endif; 
	
EndProcedure

&AtServer
Procedure loadSizes ()
	
	for each row in Object.Attachments do
		row.FileSize = Conversion.BytesToSize ( row.Size );
	enddo; 
	
EndProcedure 

&AtServer
Procedure showAttachedEmails ()
	
	Items.GroupAttachedEmails.Visible = ( Object.Emails.Count () > 0 );
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		Cancel = true;
		return;
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Attachments show Object.AttachmentsCount > 0
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( IsNew ) then
		Notify ( Enum.MessageEmailIsRead () );
	endif; 
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	MailboxesSrv.SaveLabel ( Object.Ref, Label );
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	loadSizes ();
	
EndProcedure

// *****************************************
// *********** Page Body

&AtClient
Procedure BodyOnClick ( Item, EventData, StandardProcessing )
	
	Emails.OpenLink ( EventData, StandardProcessing, Object.Mailbox, Object.Ref );
	
EndProcedure

// *****************************************
// *********** Table Attachments

&AtClient
Procedure AttachmentsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	Attachments.Command ( attachmentParams ( Enum.AttachmentsCommandsShow () ) );
	
EndProcedure

&AtClient
Function attachmentParams ( Command )
	
	p = Attachments.GetParams ();
	p.Command = Command;
	p.Control = Items.Attachments;
	p.Table = Object.Attachments;
	p.FolderID = Object.MessageID;
	p.Ref = Object.Ref;
	p.Mailbox = Object.Mailbox;
	p.Form = ThisObject;
	return p;
	
EndFunction 

&AtClient
Procedure DownloadFile ( Command )

	Attachments.Command ( attachmentParams ( Enum.AttachmentsCommandsDownload () ) );

EndProcedure

&AtClient
Procedure DownloadAllFiles ( Command )
	
	Attachments.Command ( attachmentParams ( Enum.AttachmentsCommandsDownloadAll () ) );
	
EndProcedure

// *****************************************
// *********** Page Emails

&AtClient
Procedure EmailsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	openEmail ();
	
EndProcedure

&AtClient
Procedure openEmail ()
	
	currentData = Items.Emails.CurrentData;
	ShowValue ( , currentData.Email );
	
EndProcedure 
