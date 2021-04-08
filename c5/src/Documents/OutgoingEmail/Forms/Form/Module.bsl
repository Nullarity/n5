&AtServer
var Env;
&AtServer
var EmailDocument;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	loadSenders ();
	setLabel ();
	getStatus ();
	setDefaultButton ();
	loadTable ( CurrentObject );
	loadBody ();
	loadSizes ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadSenders ()
	
	table = getSenders ();
	list = Items.Sender.ChoiceList;
	for each sender in table do
		list.Add ( sender.Email, Mailboxes.GetAddressPresentation ( sender.Email, sender.Name ) );
		Senders.Add ( sender.Email, sender.Name );
	enddo; 
	OneSender = ( table.Count () = 1 );
	
EndProcedure 

&AtServer
Function getSenders ()
	
	s = "
	|select -1 as LN, Mailboxes.Email as Email, Mailboxes.Box as Name
	|from Catalog.Mailboxes as Mailboxes
	|where Mailboxes.Ref = &Mailbox
	|union all 
	|select OtherSenders.LineNumber, OtherSenders.Email, OtherSenders.Presentation
	|from Catalog.Mailboxes.OtherSenders as OtherSenders
	|where OtherSenders.Ref = &Mailbox
	|order by LN
	|";
	q = new Query ( s );
	q.SetParameter ( "Mailbox", Object.Mailbox );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Procedure setLabel ()
	
	Label = MailboxesSrv.GetLabel ( Object.Ref );
	
EndProcedure 

&AtServer
Procedure getStatus ()
	
	r = InformationRegisters.EmailStatuses.CreateRecordManager ();
	r.Email = Object.Ref;
	r.Read ();
	Status = r.Status;
	Details = r.Details;
	
EndProcedure 

&AtServer
Procedure setDefaultButton ()
	
	if ( Status = Enums.EmailStatuses.Error ) then
		Items.FormRepost.DefaultButton = true;
	else
		Items.FormSendEmail.DefaultButton = true;
	endif; 
	
EndProcedure 

&AtServer
Procedure loadTable ( CurrentObject )
	
	TabDoc = CurrentObject.Table.Get ();
	
EndProcedure

&AtServer
Procedure loadBody ()
	
	html = EmailsSrv.GetHTML ( Object.Ref, Object.MessageID, Object.Mailbox );
	CKEditorSrv.InitEmail ( TextEditor, Object, html, Object.Posted );
	
EndProcedure 

&AtServer
Procedure loadSizes ()
	
	for each row in Object.Attachments do
		row.FileSize = Conversion.BytesToSize ( row.Size );
	enddo; 
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		copy = not Parameters.CopyingValue.IsEmpty ();
		setDate ();
		setMessageID ();
		setCreator ();
		if ( Parameters.Command = Enum.MailCommandsReply () ) then
			replyToMessage ();
		elsif ( Parameters.Command = Enum.MailCommandsForward ()
			or Parameters.Command = Enum.MailCommandsForwardOutgoingEmail () ) then
			forwardMessage ();
		else
			initMailbox ();
			if ( Parameters.Command = Enum.MailCommandsSendDocuments () ) then
				sendDocuments ();
			elsif ( copy ) then
				copyMessage ();
			else
				applyEmailParams ();
				setEmailDocument ( false );
				if ( addSignature () ) then
					insertParagraph ();
				endif;
				initTextEditor ();
			endif; 
		endif; 
		if ( not copy ) then
			setSender ();
		endif; 
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|IncomingEmail show filled ( Object.IncomingEmail );
	|Receiver Cc Subject TableType TableDescription TabDoc Label lock Object.Posted;
	|FormSendEmail FormWrite FormReread FormDelete FormUndoPosting AttachmentsUpload AttachmentsUpload1 AttachmentsRemove AttachmentsContextMenuRemove show not Object.Posted;
	|FormDataProcessorMailDelete show filled ( Object.Ref );
	|FormRepost show Object.Posted and Status = Enum.EmailStatuses.Error;
	|Attachments show ( not Object.Posted or Object.AttachmentsCount > 0 );
	|Details show Status = Enum.EmailStatuses.Error;
	|Processing show Status = Enum.EmailStatuses.Processing;
	|Sender lock ( Object.Posted or OneSender )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setDate ()
	
	Object.Date = CurrentSessionDate ();
	
EndProcedure 

&AtServer
Procedure setMessageID ()
	
	Object.ServerMessageID = String ( new UUID () ) + "@" + Cloud.Domain ();
	Object.MessageID = Conversion.StringToHash ( Object.ServerMessageID );
	
EndProcedure 

&AtServer
Procedure setCreator ()
	
	Object.Creator = SessionParameters.User;
	
EndProcedure 

&AtServer
Procedure initMailbox ()
	
	if ( Object.Mailbox.IsEmpty () ) then
		setMailbox ( MailboxesSrv.Default () );
	else
		loadSenders ();
	endif; 
	
EndProcedure 

&AtServer
Procedure setMailbox ( Mailbox )
	
	Object.Mailbox = Mailbox;
	loadSenders ();
	
EndProcedure 

&AtServer
Procedure setSender ()
	
	fields = DF.Values ( Object.Mailbox, "Email, Box" );
	Object.Sender = fields.Email;
	Object.SenderName = fields.Box;
	if ( Parameters.Command = Enum.MailCommandsReply ()
		or Parameters.Command = Enum.MailCommandsForward () ) then
		received = Env.Fields.Receiver;
		for each item in Items.Sender.ChoiceList do
			actualSender = StrFind ( received, item.Value ) > 0
			and item.Value <> Object.Sender;
			if ( actualSender ) then
				Object.Sender = item.Value;
				Object.SenderName = item.Presentation;
				break;
			endif; 
		enddo; 
	endif;
	
EndProcedure 

&AtServer
Procedure setEmailDocument ( Attachments )
	
	if ( Parameters.Command = 0
		or Parameters.Command = Enum.MailCommandsSendDocuments () ) then
		html = "<html><head></head><body></body></html>";
	else
		html = copyEmail ( Env.Fields.Document, Env.Fields.MessageID, Attachments );
	endif; 
	EmailDocument = Conversion.HTMLToDocument ( html );

EndProcedure 

&AtServer
Function copyEmail ( Email, MessageID, Attachments )
	
	folder = EmailsSrv.GetFolder ( MessageID, Object.Mailbox );
	folderURL = EmailsSrv.GetFolderURL ( MessageID, Object.Mailbox );
	folder2 = EmailsSrv.GetFolder ( Object.MessageID, Object.Mailbox );
	folderURL2 = EmailsSrv.GetFolderURL ( Object.MessageID, Object.Mailbox );
	FileSystem.CopyFolder ( folder, folder2, Attachments );
	html = EmailsSrv.GetHTML ( Email, Object.MessageID, Object.Mailbox, , true );
	html = StrReplace ( html, folderURL, folderURL2 );
	DeleteFiles ( folder2 + "\" + Email.UUID () );
	return html;

EndFunction

&AtServer
Procedure insertParagraph ()
	
	body = HTMLDoc.GetNode ( EmailDocument, EmailDocument.DocumentElement, "body" );
	if ( body.FirstChild = undefined ) then
		return;
	endif; 
	paragraph = EmailDocument.CreateElement ( "p" );
	body.InsertBefore ( paragraph, body.FirstChild );
	
EndProcedure 

#region Filling

&AtServer
Procedure replyToMessage ()

	incomingWasRead ();
	SQL.Init ( Env );
	getData ();
	setReplyHeader ();
	setEmailDocument ( false );
	shiftToRight ();
	reply ();
	addSignature ();
	insertParagraph ();
	initTextEditor ( true );
	
EndProcedure 

&AtServer
Procedure incomingWasRead ()
	
	IncomingEmailIsRead = Documents.IncomingEmail.IsNew ( Object.IncomingEmail );
	if ( IncomingEmailIsRead ) then
		Documents.IncomingEmail.MarkAsRead ( Object.IncomingEmail );
	endif; 
	
EndProcedure 

&AtServer
Procedure getData ()
	
	if ( Parameters.Command = Enum.MailCommandsForwardOutgoingEmail () ) then
		document = Parameters.OutgoingEmail;
		name = "OutgoingEmail";
	else
		document = Object.IncomingEmail;
		name = "IncomingEmail";
	endif; 
	s = "
	|// @Fields
	|select Documents.Subject as Subject, Documents.Cc as Cc, Documents.Mailbox as Mailbox,
	|	Documents.SenderName as SenderName, Documents.ReceiverName as ReceiverName, Documents.Sender as Sender, Documents.Receiver as Receiver,
	|	Documents.Date as Date, Documents.MessageID as MessageID, Documents.Ref as Document
	|from Document." + name + " as Documents
	|where Documents.Ref = &Ref
	|";
	if ( Parameters.Command = Enum.MailCommandsForward ()
		or Parameters.Command = Enum.MailCommandsForwardOutgoingEmail () ) then
		s = s + "
		|;
		|// #Attachments
		|select Attachments.File as File, Attachments.Size as Size, Attachments.Extension as Extension
		|from Document." + name + ".Attachments as Attachments
		|where Attachments.Ref = &Ref
		|order by Attachments.LineNumber
		|";
	endif; 
	Env.Selection.Add ( s );
	Env.Q.SetParameter ( "Ref", document );
	SQL.Perform ( Env );

EndProcedure 

&AtServer
Procedure setReplyHeader ()
	
	fields = Env.Fields;
	setMailbox ( fields.Mailbox );
	Object.Subject = getSubject ( "Re:" );
	Object.Receiver = adjustAddress ( fields.Sender );
	Object.Cc = adjustAddress ( fields.Cc, true );

EndProcedure 

&AtServer
Function getSubject ( Prefix )
	
	s = Lower ( Left ( Env.Fields.Subject, StrLen ( Prefix ) ) );
	if ( s = Lower ( Prefix ) ) then
		return Env.Fields.Subject;
	else
		return Prefix + " " + Env.Fields.Subject;
	endif; 
	
EndFunction 

&AtServer
Function adjustAddress ( Address, ExcludeMe = false )
	
	result = new Array ();
	list = Mailboxes.GetAddresses ( Address );
	p = new Structure ( "User, Email", SessionParameters.User );
	for each item in list do
		if ( ExcludeMe
			and Senders.FindByValue ( item.Email ) <> undefined ) then
			continue;
		endif; 
		p.Email = item.Email;
		presentation = InformationRegisters.AddressBook.Get ( p ).Presentation;
		if ( presentation = "" ) then
			presentation = Mailboxes.GetAddressPresentation ( item.Email, item.Name );
		endif; 
		result.Add ( presentation );
	enddo; 
	return StrConcat ( result, ", " );
	
EndFunction 

&AtServer
Procedure initTextEditor ( Focus = false )
	
	if ( EmailDocument = undefined ) then
		html = "";
	else
		html = Conversion.DocumentToHTML ( EmailDocument );
	endif; 
	CKEditorSrv.InitEmail ( TextEditor, Object, html, , Focus );
	
EndProcedure 

&AtServer
Procedure shiftToRight ()
	
	body = HTMLDoc.GetNode ( EmailDocument, EmailDocument.DocumentElement, "body" );
	quote = EmailDocument.CreateElement ( "blockquote" );
	style = EmailDocument.CreateAttribute ( "style" );
	style.Value = "font-style: italic; margin: 0 0 0 0.8ex; border-left: 2px #ccc solid; padding-left: 1ex;";
	quote.Attributes.SetNamedItem ( style );
	for each child in body.ChildNodes do
		clone = child.CloneNode ( true );
		quote.AppendChild ( clone );
	enddo; 
	HTMLDoc.ClearNode ( body );
	body.AppendChild ( quote );

EndProcedure 

&AtServer
Procedure reply ()
	
	p = new Structure ();
	p.Insert ( "Address", Mailboxes.GetAddressPresentation ( Env.Fields.Sender, Env.Fields.SenderName, false ) );
	p.Insert ( "Date", Env.Fields.Date );
	body = HTMLDoc.GetNode ( EmailDocument, EmailDocument.DocumentElement, "body" );
	paragraph = EmailDocument.CreateElement ( "p" );
	paragraph.AppendChild ( EmailDocument.CreateTextNode ( Output.Reply ( p ) ) );
	if ( body.FirstChild = undefined ) then
		body.AppendChild ( paragraph );
	else
		body.InsertBefore ( paragraph, body.FirstChild );
	endif; 
	
EndProcedure 

&AtServer
Function addSignature ()
	
	signature = Conversion.HTMLToDocument ( CKEditorSrv.GetHTML ( DF.Pick ( Object.Mailbox, "FolderID" ) ) );
	if ( signature.DocumentElement = undefined ) then
		return false;
	endif; 
	signatureBody = HTMLDoc.GetNode ( signature, signature.DocumentElement, "body" );
	body = HTMLDoc.GetNode ( EmailDocument, EmailDocument.DocumentElement, "body" );
	for each child in signatureBody.ChildNodes do
		body.AppendChild ( child.CloneNode ( true ) );
	enddo; 
	return true;

EndFunction

&AtServer
Procedure forwardMessage ()
	
	if ( Parameters.Command = Enum.MailCommandsForward () ) then
		incomingWasRead ();
	endif; 
	SQL.Init ( Env );
	getData ();
	setForwardHeader ();
	setEmailDocument ( true );
	shiftToRight ();
	forward ();
	addSignature ();
	insertParagraph ();
	forwardAttachments ();
	loadSizes ();
	initTextEditor ( true );
	
EndProcedure 

&AtServer
Procedure setForwardHeader ()
	
	Object.Subject = getSubject ( "Fw:" );
	setMailbox ( Env.Fields.Mailbox );
	
EndProcedure 

&AtServer
Procedure forward ()
	
	p = new Structure ();
	if ( Parameters.Command = Enum.MailCommandsForwardOutgoingEmail () ) then
		p.Insert ( "Email", Mailboxes.GetAddressPresentation ( Env.Fields.Sender, Env.Fields.SenderName, false ) );
	else
		p.Insert ( "Email", Mailboxes.GetAddressPresentation ( Env.Fields.Receiver, Env.Fields.ReceiverName, false ) );
	endif; 
	p.Insert ( "From", Mailboxes.GetAddressPresentation ( Env.Fields.Sender, Env.Fields.SenderName ) );
	p.Insert ( "To", Mailboxes.GetAddressPresentation ( Env.Fields.Receiver, Env.Fields.ReceiverName ) );
	p.Insert ( "Cc", Env.Fields.Cc );
	p.Insert ( "Date", Env.Fields.Date );
	p.Insert ( "Subject", Env.Fields.Subject );
	body = HTMLDoc.GetNode ( EmailDocument, EmailDocument.DocumentElement, "body" );
	paragraph = EmailDocument.CreateElement ( "p" );
	paragraph.AppendChild ( EmailDocument.CreateTextNode ( Output.Forward ( p ) ) );
	if ( body.FirstChild = undefined ) then
		body.AppendChild ( paragraph );
	else
		body.InsertBefore ( paragraph, body.FirstChild );
	endif; 
	
EndProcedure 

&AtServer
Procedure forwardAttachments ()
	
	for each attachment in Env.Attachments do
		row = Object.Attachments.Add ();
		FillPropertyValues ( row, attachment );
	enddo; 
	
EndProcedure 

&AtServer
Procedure sendDocuments ()
	
	SQL.Init ( Env );
	getDocumentsData ();
	loadDocuments ();
	addSignature ();
	insertParagraph ();
	loadSizes ();
	initTextEditor ();
	
EndProcedure 

&AtServer
Procedure getDocumentsData ()
	
	s = "
	|// #Documents
	|select Documents.Subject as Subject, Documents.FolderID as FolderID, Documents.IsEmpty as IsEmpty
	|from Document.Document as Documents
	|where Documents.Ref in ( &Documents )
	|;
	|// #Files
	|select Files.File as File, Files.Size as Size, Files.Extension as Extension
	|from InformationRegister.Files as Files
	|where Files.Document in ( &Documents )
	|order by Files.File
	|";
	Env.Selection.Add ( s );
	Env.Q.SetParameter ( "Documents", Parameters.Documents );
	SetPrivilegedMode ( true );
	SQL.Perform ( Env );
	SetPrivilegedMode ( false );

EndProcedure 

&AtServer
Procedure loadDocuments ()
	
	Object.Subject = StrConcat ( Env.Documents.UnloadColumn ( "Subject" ), ", " );
	Object.Attachments.Load ( Env.Files );
	bodyEmpty = true;
	for each row in Env.Documents do
		folder = CKEditorSrv.GetFolder ( row.FolderID );
		folder2 = EmailsSrv.GetAttachmentsFolder ( Object.MessageID, Object.Mailbox );
		FileSystem.CopyFolder ( folder, folder2 );
		if ( bodyEmpty and not row.IsEmpty ) then
			bodyEmpty = false;
			folderURL = CKEditorSrv.GetFolderURL ( row.FolderID );
			folderURL2 = EmailsSrv.GetAttachmentsFolderURL ( Object.MessageID, Object.Mailbox );
			html = CKEditorSrv.GetHTML ( row.FolderID, true );
			html = StrReplace ( html, folderURL, folderURL2 );
			EmailDocument = Conversion.HTMLToDocument ( html );
		endif; 
		DeleteFiles ( folder2 + "\" + row.FolderID );
	enddo; 
	if ( bodyEmpty ) then
		setEmailDocument ( false );
		initTextEditor ();
	endif; 

EndProcedure 

&AtServer
Procedure copyMessage ()
	
	html = copyEmail ( Parameters.CopyingValue, Parameters.CopyingValue.MessageID, true );
	EmailDocument = Conversion.HTMLToDocument ( html );
	TabDoc = Parameters.CopyingValue.Table.Get ();
	loadSizes ();
	initTextEditor ();

EndProcedure 

#endregion

&AtServer
Procedure applyEmailParams ()
	
	emailParams = undefined;
	if ( not Parameters.Property ( "EmailParams", emailParams ) ) then
		return;
	endif; 
	Object.Subject = emailParams.Subject;
	Object.TableDescription = emailParams.TableDescription;
	TabDoc = GetFromTempStorage ( emailParams.TableAddress );
	Object.TableType = Enums.TableTypes.PDF;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( Object.Mailbox.IsEmpty () ) then
		Output.MailboxIsNotConfigured ( ThisObject );
		return;
	endif; 
	if ( IncomingEmailIsRead ) then
		Notify ( Enum.MessageEmailIsRead () );
	endif; 

EndProcedure

&AtClient
Procedure MailboxIsNotConfigured ( Answer, Params ) export
	
	Close ();
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	OpenForm ( "Catalog.Mailboxes.ObjectForm" );
	
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( Exit ) then
		Cancel = true;
		return;
	endif; 
	CKEditor.CheckModified ( ThisObject, Items.TextEditor );
	
EndProcedure

&AtClient
Procedure OnClose ( Exit )
	
	if ( Exit ) then
		return;
	endif; 
	if ( Object.Ref.IsEmpty () ) then
		EmailsSrv.Clean ( Object.MessageID, Object.Mailbox );
	endif; 
	CKEditorSrv.RemoveScript ( Object.MessageID );
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	CKEditor.SaveHTML ( WriteParameters, Items.TextEditor );
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	setReceiverName ( CurrentObject );
	storeTable ( CurrentObject );
	setAttachmentsCount ( CurrentObject );
	storeContent ( CurrentObject, WriteParameters );
	
EndProcedure

&AtServer
Procedure setReceiverName ( CurrentObject )
	
	CurrentObject.ReceiverName = Mailboxes.GetNames ( CurrentObject.Receiver );
	
EndProcedure 

&AtServer
Procedure storeTable ( CurrentObject )
	
	CurrentObject.Table = new ValueStorage ( TabDoc, new Deflation ( 9 ) );
	
EndProcedure

&AtServer
Procedure setAttachmentsCount ( CurrentObject )
	
	CurrentObject.AttachmentsCount = CurrentObject.Attachments.Count ();
	
EndProcedure 

&AtServer
Procedure storeContent ( CurrentObject, WriteParameters )
	
	if ( WriteParameters.TextEditor <> undefined ) then
		CurrentObject.Content = CKEditorSrv.GetText ( WriteParameters.TextEditor );
		CurrentObject.Brief = DataProcessors.Email.BriefBody ( CurrentObject.Content );
	endif; 
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	storeBody ( CurrentObject, WriteParameters );
	saveReply ( CurrentObject );
	MailboxesSrv.SaveLabel ( CurrentObject.Ref, Label );
	
EndProcedure

&AtServer
Procedure storeBody ( CurrentObject, WriteParameters )
	
	if ( WriteParameters.TextEditor = undefined ) then
		return;
	endif; 
	path = EmailsSrv.GetFolder ( Object.MessageID, Object.Mailbox ) + "\" + CurrentObject.Ref.UUID ();
	writer = new TextWriter ( path );
	writer.Write ( WriteParameters.TextEditor );
	writer.Close ();
	
EndProcedure

&AtServer
Procedure saveReply ( CurrentObject )
	
	if ( Parameters.Command <> Enum.MailCommandsReply ()
		and Parameters.Command <> Enum.MailCommandsForward () ) then
		return;
	endif; 
	r = InformationRegisters.Replies.CreateRecordManager ();
	r.IncomingEmail = Object.IncomingEmail;
	r.OutgoingEmail = CurrentObject.Ref;
	r.Action = Parameters.Command;
	r.Write ();
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	if ( writeMode ( WriteParameters ) = DocumentWriteMode.Posting ) then
		return;
	endif; 
	loadSizes ();
	addToAddresssBook ();
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
EndProcedure

&AtServer
Function writeMode ( WriteParameters )
	
	if ( WriteParameters.Property ( "РежимЗаписи" ) ) then
		return WriteParameters.РежимЗаписи;
	else
		return WriteParameters.WriteMode;
	endif; 
	
EndFunction 

&AtServer
Procedure addToAddresssBook ()
	
	addresses = Mailboxes.GetAddresses ( Object.Receiver + "," + Object.Cc );
	if ( addresses = undefined ) then
		return;
	endif; 
	for each pair in addresses do
		Mailboxes.AddAddress ( pair.Email, pair.Name );
	enddo; 
	
EndProcedure 

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	CKEditor.ResetDirty ( Items.TextEditor );
	
EndProcedure

&AtClient
Procedure ChoiceProcessing ( SelectedValue, Source )
	
	if ( TypeOf ( SelectedValue ) = Type ( "DocumentRef.Document" ) ) then
		attachDocument ( SelectedValue );
	endif; 
	
EndProcedure

&AtServer
Procedure attachDocument ( val Document )
	
	SQL.Init ( Env );
	getDocumentFiles ( Document );
	if ( Env.Files.Count () = 0 ) then
		Output.DocumentIsEmpty ();
		return;
	endif; 
	loadFiles ();
	
EndProcedure 

&AtServer
Procedure getDocumentFiles ( Document )
	
	s = "
	|// #Files
	|select Files.File as File, Files.Size as Size, Files.Extension as Extension,
	|	Files.Document.FolderID as FolderID, Files.Date as Date
	|from InformationRegister.Files as Files
	|where Files.Document = &Document
	|order by Files.File
	|";
	Env.Selection.Add ( s );
	Env.Q.SetParameter ( "Document", Document );
	SQL.Perform ( Env );

EndProcedure

&AtServer
Procedure loadFiles ()
	
	search = new Structure ( "File" );
	for each row in Env.Files do
		search.File = row.File;
		found = Object.Attachments.FindRows ( search );
		if ( found.Count () > 0 ) then
			Output.DocumentAlreadyAttached ( new Structure ( "File", row.File ) );
			continue;
		endif; 
		attachment = Object.Attachments.Add ();
		FillPropertyValues ( attachment, row );
		attachment.FileSize = Conversion.BytesToSize ( row.Size );
		source = CKEditorSrv.GetFolder ( row.FolderID ) + "\" + row.File;
		destination = EmailsSrv.GetAttachmentsFolder ( Object.MessageID, Object.Mailbox ) + "\" + row.File;
		CopyFile ( source, destination );
	enddo; 

EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure SendEmail ( Command )
	
	saveAndPost ();
	
EndProcedure

&AtClient
Procedure saveAndPost ()
	
	p = new Structure ();
	p.Insert ( "WriteMode", DocumentWriteMode.Posting );
	if ( not Write ( p ) ) then
		return;
	endif; 
	send ( Object.Ref );
	Close ();
	
EndProcedure 

&AtServer
Procedure send ( val Ref )
	
	jobKey = "SendEmail" + UserName ();
	startEmailsSending ( jobKey, Ref, true, Label, Object.Mailbox );
	
EndProcedure 

&AtServerNoContext
Procedure startEmailsSending ( val JobKey, val Email, val IsNew, val Label, val Mailbox )
	
	p = new Array ();
	p.Add ( JobKey );
	p.Add ( Email );
	p.Add ( IsNew );
	p.Add ( Label );
	p.Add ( Mailbox );
	Jobs.Run ( "MailboxesSrv.Send", p, JobKey );
	
EndProcedure 

&AtClient
Procedure Repost ( Command )
	
	sendAgain ();
	
EndProcedure

&AtClient
Procedure sendAgain ()
	
	jobKey = "SendEmail" + UserName ();
	startEmailsSending ( jobKey, Object.Ref, false, Label, Object.Mailbox );
	Progress.Open ( jobKey, ThisObject, new NotifyDescription ( "EmailWasSent", ThisObject ), true );
	
EndProcedure 

&AtClient
Procedure EmailWasSent ( Result, Params ) export
	
	if ( Result ) then
		Close ();
	else
		showError ();
	endif; 
	
EndProcedure 

&AtServer
Procedure showError ()
	
	getStatus ();
	Appearance.Apply ( ThisObject );

EndProcedure 

&AtClient
Procedure ReceiverStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	OpenForm ( "Catalog.AddressBook.ChoiceForm", new Structure ( "MultipleSelection", true ), Item );
	
EndProcedure

&AtClient
Procedure ReceiverChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	EmailsTip.FixEmail ( SelectedValue );

EndProcedure

&AtClient
Procedure ReceiverAutoComplete ( Item, Text, ChoiceData, Parameters, Wait, StandardProcessing )
	
	EmailsTip.ShowFull ( Text, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure CcAutoComplete ( Item, Text, ChoiceData, Parameters, Wait, StandardProcessing )
	
	EmailsTip.ShowFull ( Text, ChoiceData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure CopyStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	OpenForm ( "Catalog.AddressBook.ChoiceForm", new Structure ( "MultipleSelection", true ), Item );
	
EndProcedure

&AtClient
Procedure CcChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	EmailsTip.FixEmail ( SelectedValue );

EndProcedure

&AtClient
Procedure SenderOnChange ( Item )
	
	setSenderName ();
	
EndProcedure

&AtClient
Procedure setSenderName ()
	
	item = Senders.FindByValue ( Object.Sender );
	if ( item = undefined ) then
		return;
	endif; 
	Object.SenderName = item.Presentation;
	
EndProcedure 

&AtClient
Procedure TextEditorDocumentComplete ( Item )
	
	if ( EditorBegun ) then
		return;
	endif; 
	EditorBegun = true;
	focusEditor ();
	
EndProcedure

&AtClient
Procedure focusEditor ()
	
	if ( Parameters.Command <> Enum.MailCommandsReply () ) then
		return;
	endif; 
	webWindow = CKEditor.GetWindow ( Items.TextEditor );
	if ( CKEditor.IsReady ( webWindow ) ) then
		webWindow.Focus ();
	endif; 
	
EndProcedure 

&AtClient
Procedure TextEditorOnClick ( Item, EventData, StandardProcessing )
	
	href = EventData.Href;
	if ( href = undefined ) then
		return;
	endif; 
	StandardProcessing = false;
	if ( CKEditor.Action ( href, Enum.EditorActionSave () ) )then
		SaveDocument ();
	elsif ( CKEditor.Action ( href, Enum.EditorActionSaveAndClose () ) )then
		SaveAndPostDocument ();
	elsif ( CKEditor.Action ( href, Enum.EditorActionCancel () ) )then
		cancelEditing ();
	elsif ( CKEditor.Action ( href, Enum.EditorActionFiles () ) )then
		finishedUpload ();
	else
		StandardProcessing = true;
	endif; 
	
EndProcedure

&AtClient
Procedure saveDocument ()
	
	Write ();
	
EndProcedure 

&AtClient
Procedure saveAndPostDocument ()
	
	saveAndPost ();
	
EndProcedure 

&AtClient
Procedure cancelEditing ()
	
	Close ();
	
EndProcedure 

&AtClient
Procedure finishedUpload ()

	webWindow = CKEditor.GetWindow ( Items.TextEditor );
	if ( CKEditor.IsReady ( webWindow ) ) then
		webWindow.GetFile ();
		addFile ( webWindow.FileName, webWindow.FileSize );
	endif; 

EndProcedure 

&AtClient
Procedure addFile ( Name, Size )
	
	file = FileSystem.GetFileName ( Name );
	rows = Object.Attachments.FindRows ( new Structure ( "File", file ) );
	if ( rows.Count () > 0 ) then
		return;
	endif; 
	row = Object.Attachments.Add ();
	row.File = file;
	row.Extension = FileSystem.GetExtensionIndex ( Name );
	row.Size = ? ( Size = -1, getSize ( Name ), Size );
	row.FileSize = Conversion.BytesToSize ( row.Size );
	row.Date = SessionDate ( CurrentDate () );
	Items.Attachments.CurrentRow = row.GetID ();
	Modified = true;
	
EndProcedure 

&AtServerNoContext
Function getSize ( val Name )
	
	file = new File ( Name );
	return file.Size ();
	
EndFunction 

// *****************************************
// *********** Table Attachments

&AtClient
Procedure Upload ( Command )
	
	webWindow = CKEditor.GetWindow ( Items.TextEditor );
	if ( CKEditor.IsReady ( webWindow ) ) then
		webWindow.AddFiles ();
	endif; 
	
EndProcedure

&AtClient
Procedure Remove ( Command )
	
	Attachments.Remove ( attachmentParams ( Enum.AttachmentsCommandsRemove () ) );
	
EndProcedure

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

&AtClient
Procedure UploadDocument ( Command )
	
	OpenForm ( "Document.Document.ChoiceForm", , ThisObject );
	
EndProcedure
