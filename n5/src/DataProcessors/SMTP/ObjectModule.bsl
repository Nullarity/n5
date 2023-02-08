var Email export;
var ErrorMessage export;
var SMTP;
var Env;
var Mail;
var TemptFolder;
var IMAP;

Function Send () export
	
	writeInProcess ();
	initEnv ();
	getData ();
	initMail ();
	fillHeader ();
	setBody ();
	attachFiles ();
	attachTable ();
	if ( not SMTP.SendEmail ( Mail ) ) then
		writeError ( SMTP.LastErrorText );
		SMTP.CloseSmtpConnection ();
		return false;
	endif; 
	InternalCalls.WriteSuccessfull ( Email );
	SMTP.CloseSmtpConnection ();
	if ( Env.Fields.Protocol = Enums.Protocols.IMAP
		and Env.Fields.SentFolder <> "" ) then
		appendSent ();
	endif; 
	if ( FileSystem.Exists ( TemptFolder ) ) then
		DeleteFiles ( TemptFolder );
	endif; 
	return true;
	
EndFunction

Procedure writeInProcess ()
	
	r = InformationRegisters.EmailStatuses.CreateRecordManager ();
	r.Email = Email;
	r.Status = Enums.EmailStatuses.Processing;
	r.Write ();
	
EndProcedure 

Procedure initEnv ()
	
	Env = new Structure ();
	InternalCalls.SQLInit ( Env );
	
EndProcedure

Procedure getData ()
	
	sqlFields ();
	sqlAttachments ();
	Env.Q.SetParameter ( "Ref", Email );
	InternalCalls.Perform ( Env );
	
EndProcedure 

Procedure sqlFields ()
	
	s = "
	|// @Fields
	|select Documents.Cc as Cc, Documents.Mailbox as Mailbox, Documents.Sender as Sender,
	|	Documents.SenderName as SenderName, Documents.Receiver as Receiver, Documents.Subject as Subject,
	|	Documents.MessageID as MessageID, Documents.Table as Table, Documents.TableDescription as TableDescription,
	|	Documents.TableType as TableType, Documents.Mailbox.FolderID as SignatureID,
	|	Documents.Mailbox.SMTPPassword as SMTPPassword, Documents.Mailbox.SMTPPort as SMTPPort, Documents.ServerMessageID as ServerMessageID,
	|	Documents.Mailbox.SMTPSecureAuthenticationOnly as SMTPSecureAuthenticationOnly, Documents.Mailbox.SMTPServerAddress as SMTPServerAddress,
	|	Documents.Mailbox.SMTPUser as SMTPUser, Documents.Mailbox.SMTPUseSSL as SMTPUseSSL, Documents.Mailbox.Timeout as Timeout,
	|	Documents.Mailbox.Protocol as Protocol, Documents.Mailbox.IMAPPort as IMAPPort, Documents.Mailbox.IMAPUseSSL as IMAPUseSSL,
	|	Documents.Mailbox.IMAPSecureAuthenticationOnly as IMAPSecureAuthenticationOnly, Documents.Mailbox.IMAPServerAddress as IMAPServerAddress,
	|	Documents.Mailbox.IMAPUser as IMAPUser, Documents.Mailbox.IMAPPassword as IMAPPassword, Documents.Mailbox.SentFolder as SentFolder
	|from Document.OutgoingEmail as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlAttachments ()
	
	s = "
	|// #Attachments
	|select Attachments.File as File
	|from Document.OutgoingEmail.Attachments as Attachments
	|where Attachments.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure initMail ()
	
	SMTP = CoreLibrary.Chilkat ( "MailMan" );
	SMTP.SmtpHost = Env.Fields.SMTPServerAddress;
	SMTP.SmtpUsername = Env.Fields.SMTPUser;
	SMTP.SmtpPassword = Env.Fields.SMTPPassword;
	SMTP.SmtpPort = Env.Fields.SMTPPort;
	SMTP.SmtpSsl = Env.Fields.SMTPUseSSL;
	SMTP.ConnectTimeout = Env.Fields.Timeout;
	SMTP.AutoGenMessageId = false;
	Mail = new COMObject ( "Chilkat_9_5_0.Email" );
	
EndProcedure 

Procedure fillHeader ()
	
	Mail.Subject = Env.Fields.Subject;
	Mail.FromAddress = Env.Fields.Sender;
	Mail.FromName = Env.Fields.SenderName;
	addresses = Mailboxes.GetAddresses ( Env.Fields.Receiver );
	for each address in addresses do
		Mail.AddTo ( address.Name, address.Email );
	enddo; 
	addresses = Mailboxes.GetAddresses ( Env.Fields.Cc );
	for each address in addresses do
		Mail.AddCC ( address.Name, address.Email );
	enddo; 
	Mail.AddHeaderField ( "Message-ID", "<" + Env.Fields.ServerMessageID + ">" );
	
EndProcedure 

Procedure setBody ()
	
	html = EmailsSrv.GetHTML ( Email, Env.Fields.MessageID, Env.Fields.Mailbox );
	document = Conversion.HTMLToDocument ( html );
	folder = EmailsSrv.GetFolder ( Env.Fields.MessageID, Env.Fields.Mailbox );
	folderURL = Lower ( EmailsSrv.GetFolderURL ( Env.Fields.MessageID, Env.Fields.Mailbox ) );
	signatureFolder = CKEditorSrv.GetFolder ( Env.Fields.SignatureID );
	signatureFolderURL = CKEditorSrv.GetFolderURL ( Env.Fields.SignatureID );
	for each image in Document.Images do
		imageURL = Lower ( image.Src );
		cid = undefined;
		if ( Find ( imageURL, folderURL ) = 1 ) then
			path = StrReplace ( StrReplace ( imageURL, folderURL, folder ), "/", "\" );
			cid = Mail.AddRelatedFile ( path );
		elsif ( Find ( imageURL, signatureFolderURL ) = 1 ) then
			path = StrReplace ( StrReplace ( imageURL, signaturefolderURL, signaturefolder ), "/", "\" );
			cid = Mail.AddRelatedFile ( path );
		endif; 
		if ( cid <> undefined ) then
			image.Src = "cid:" + cid;
		endif; 
	enddo; 
	Mail.SetHtmlBody ( Conversion.DocumentToHTML ( document ) );

EndProcedure 

Procedure attachFiles ()
	
	table = Env.Attachments;
	folder = EmailsSrv.GetAttachmentsFolder ( Env.Fields.MessageID, Env.Fields.Mailbox ) + "\";
	i = 0;
	for each row in table do
		result = Mail.AddFileAttachment ( folder + row.File );
		if ( result <> undefined ) then
			Mail.SetAttachmentFileName ( i, row.File );
			i = i + 1;
		endif; 
	enddo; 
	
EndProcedure 

Procedure attachTable ()
	
	if ( Env.Fields.TableType.IsEmpty () ) then
		return;
	endif; 
	TemptFolder = GetTempFileName ();
	CreateDirectory ( TemptFolder );
	filePath = TemptFolder + "\Attachment." + FileSystem.TableExtension ( Env.Fields.TableType );
	tabDoc = Env.Fields.Table.Get ();
	tabDoc.Write ( filePath, FileSystem.SpreadsheetType ( Env.Fields.TableType ) );
	Mail.AddFileAttachment ( filePath )

EndProcedure 

Procedure writeError ( Error )
	
	ErrorMessage = Error;
	rm = InformationRegisters.EmailStatuses.CreateRecordManager ();
	rm.Email = Email;
	rm.Details = ErrorMessage;
	rm.Status = Enums.EmailStatuses.Error;
	rm.Write ();
	
EndProcedure 

Procedure appendSent ()
	
	initIMAP ();
	if ( connectIMAP () ) then
		if ( not copyToSent () ) then
			writeError ( IMAP.LastErrorText );
		endif; 
	else
		writeError ( IMAP.LastErrorText );
	endif; 
	IMAP.Disconnect ();
	
EndProcedure 

Procedure initIMAP ()
	
	IMAP = CoreLibrary.Chilkat ( "Imap" );
	
EndProcedure 

Function connectIMAP ()
	
	IMAP.ConnectTimeout = Env.Fields.Timeout;
	IMAP.Port = Env.Fields.IMAPPort;
	IMAP.Ssl = Env.Fields.IMAPUseSSL;
	IMAP.StartTls = Env.Fields.IMAPSecureAuthenticationOnly;
	result = IMAP.Connect ( Env.Fields.IMAPServerAddress );
	if ( not result ) then
		return false;
	endif; 
	if ( yahoo () ) then
		responce = IMAP.SendRawCommand ( "ID (""GUID"" ""1"")" );
		if ( responce = undefined ) then
			return false;
		endif; 
	endif; 
	result = IMAP.Login ( Env.Fields.IMAPUser, Env.Fields.IMAPPassword );
	if ( not result ) then
		return false;
	endif; 
	return true;
	
EndFunction 

Function yahoo ()
	
	return Find ( Env.Fields.IMAPServerAddress, ".yahoo." ) > 0;
	
EndFunction 

Function copyToSent ()
	
	result = IMAP.AppendMail ( Env.Fields.SentFolder, Mail );
	return ? ( result = 0, false, true );

EndFunction 
