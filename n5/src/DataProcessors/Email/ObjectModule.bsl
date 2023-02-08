#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Email export;
var Profile export;
var Stream export;
var Box export;
var AttachedEmails export;
var Folder;
var FolderURL;
var Document;
var Incoming;
var DocumentUUID;
var MessageID;
var LoadResult;

Function Load () export
	
	defineMessage ();
	Document = findDocument ();
	if ( Document <> undefined ) then
		LoadResult.Document = Document;
		return LoadResult;
	endif; 
	defineDocument ();
	fillHeader ();
	setContent ();
	setFolder ();
	if ( not unloadBody () ) then
		writeError ( Email.LastError );
		return LoadResult;
	endif;
	if ( not fillAttachments () ) then
		writeError ( Email.LastErrorText );
		return LoadResult;
	endif; 
	if ( not loadAttachedEmails () ) then
		return LoadResult;
	endif; 
	Document.Write ();
	if ( not Incoming ) then
		MailboxesSrv.WriteSuccessfull ( Document.Ref );
	endif; 
	LoadResult.Document = Document.Ref;
	LoadResult.UID = Email.GetImapUID ();
	return LoadResult;
	
EndFunction

Procedure defineMessage ()
	
	Incoming = DataProcessors.Email.IsIncoming ( Email, Box.Ref, Profile.Senders );
	MessageID = DataProcessors.Email.GetID ( Email, Incoming );
	
EndProcedure 

Function findDocument ()
	
	s = "
	|select Documents.Ref as Ref
	|from Document." + ? ( Incoming, "IncomingEmail", "OutgoingEmail" ) + " as Documents
	|where Documents.MessageID = &ID
	|and Documents.Mailbox = &Mailbox
	|";
	q = new Query ( s );
	q.SetParameter ( "ID", MessageID );
	q.SetParameter ( "Mailbox", Box.Ref );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );

EndFunction 

Procedure defineDocument ()
	
	DocumentUUID = new UUID ();
	if ( Incoming ) then
		Document = Documents.IncomingEmail.CreateDocument ();
		Document.SetNewObjectRef ( Documents.IncomingEmail.GetRef ( DocumentUUID ) );
	else
		Document = Documents.OutgoingEmail.CreateDocument ();
		Document.SetNewObjectRef ( Documents.OutgoingEmail.GetRef ( DocumentUUID ) );
		Document.Posted = true;
	endif; 
	
EndProcedure 

Procedure fillHeader ()
	
	Document.Mailbox = Box.Ref;
	Document.AttachmentsCount = Email.NumAttachments;
	Document.Creator = SessionParameters.User;
	Document.Date = ? ( Profile.TimeZone = "", Email.LocalDate, ToLocalTime ( Email.EmailDate, Profile.TimeZone ) );
	if ( Incoming ) then
		Document.Received = Email.LocalDate;
	endif; 
	Document.ServerMessageID = getSystemID ();
	Document.MessageID = MessageID;
	Document.Cc = getCc ();
	setReceiver ();
	Document.ReplyTo = Email.ReplyTo;
	Document.Sender = Email.From;
	Document.SenderName = Email.FromName;
	Mailboxes.AddAddress ( Email.FromAddress, Email.FromName );
	Document.Size = Email.Size;
	Document.Subject = Email.Subject;
	Document.Importance = getImportance ();
		
EndProcedure 

Function getSystemID ()
	
	id = Email.GetHeaderField ( "Message-ID" );
	return Mid ( id, 2, StrLen ( id ) - 2 );
	
EndFunction 

Function getCc ()
	
	bound = Email.NumCC - 1;
	list = new Array ();
	for i = 0 to bound do
		list.Add ( Email.GetCC ( i ) );
		Mailboxes.AddAddress ( Email.GetCcAddr ( i ), Email.GetCcName ( i ) );
	enddo; 
	return StrConcat ( list, ", " );
	
EndFunction 

Procedure setReceiver ()
	
	bound = Email.NumTo - 1;
	fullAddresses = new Array ();
	names = new Array ();
	for i = 0 to bound do
		fullAddresses.Add ( Email.GetTo ( i ) );
		name = Email.GetToName ( i );
		names.Add ( name );
	enddo; 
	Document.Receiver = StrConcat ( fullAddresses, ", " );
	Document.ReceiverName = StrConcat ( names, ", " );
	
EndProcedure

Function getImportance ()
	
	priority = Email.GetHeaderField ( "X-Priority" );
	if ( priority = 1 ) then
		return Enums.Importance.Highest;
	elsif ( priority = 2 ) then
		return Enums.Importance.Hight;
	elsif ( priority = 3 ) then
		return Enums.Importance.Normal;
	elsif ( priority = 4 ) then
		return Enums.Importance.Low;
	elsif ( priority = 5 ) then
		return Enums.Importance.Lowest;
	endif; 
	
EndFunction 

Procedure setContent ()
	
	extractor = CoreLibrary.Chilkat ( "HtmlToText" );
	Document.Content = Conversion.XMLToStandard ( extractor.ToText ( Email.Body ) );
	Document.Brief = DataProcessors.Email.BriefBody ( Document.Content );
	
EndProcedure 

Procedure setFolder ()
	
	Folder = EmailsSrv.GetFolder ( MessageID, Box.Ref );
	FolderURL = EmailsSrv.GetFolderURL ( MessageID, Box.Ref );
	if ( FileSystem.Exists ( Folder ) ) then
		DeleteFiles ( Folder );
	endif; 
	CreateDirectory ( Folder );
	
EndProcedure 

Function unloadBody ()
	
	Email.Charset = "utf-8";
	data = Email.AspUnpack2 ( "", Folder, FolderURL, true );
	if ( data = undefined ) then
		return false;
	endif;
	Stream.Format.Type = 1;
	Stream.Open ( Folder + "\" + DocumentUUID, 3 );
	Stream.Write ( data );
	Stream.Close ();
	return true;

EndFunction

Procedure writeError ( ErrorText )
	
	LoadResult.Error = true;
	LoadResult.ErrorText = ErrorText;
	
EndProcedure 

Function fillAttachments ()
	
	bound = Document.AttachmentsCount - 1;
	for i = 0 to bound do
		row = Document.Attachments.Add ();
		row.File = Email.GetAttachmentFileName ( i );
		row.Size = Email.GetAttachmentSize ( i );
		row.Extension = FileSystem.GetExtensionIndex ( row.File );
		removeDuplicate ( row.File );
	enddo; 
	result = Email.SaveAllAttachments ( Folder + "\" + Cloud.EmailAttachmentsFolder () );
	return result = 1;
	
EndFunction

Procedure removeDuplicate ( File )
	
	path = Folder + "\" + File;
	if ( FileSystem.Exists ( path ) ) then
		DeleteFiles ( path );
	endif; 
	
EndProcedure 

Function loadAttachedEmails ()

	bound = Email.NumAttachedMessages - 1;
	for i = 0 to bound do
		message = Email.GetAttachedMessage ( i );
		embeddedDocument = findMessage ( message );
		if ( embeddedDocument = undefined ) then
			result = DataProcessors.Email.Load ( Box, Profile, message, Stream, AttachedEmails );
			if ( result.Error ) then
				writeError ( result.ErrorMessage );
				return false;
			endif; 
			embeddedDocument = result.Document;
		endif; 
		row = Document.Emails.Add ();
		row.Email = embeddedDocument;
		if ( AttachedEmails <> undefined ) then
			AttachedEmails.Add ( new Structure ( "Document, UID", embeddedDocument, message.GetImapUid () ) );
		endif;
	enddo; 
	return true;
	
EndFunction

Function findMessage ( Email )
	
	s = "
	|select Documents.Ref as Ref
	|from Document.IncomingEmail as Documents
	|where Documents.MessageID = &ID
	|and Documents.Mailbox = &Mailbox
	|union all
	|select Documents.Ref
	|from Document.OutgoingEmail as Documents
	|where Documents.MessageID = &ID
	|and Documents.Mailbox = &Mailbox
	|";
	q = new Query ( s );
	q.SetParameter ( "ID", DataProcessors.Email.GetID ( Email, Incoming ) );
	q.SetParameter ( "Mailbox", Box.Ref );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );

EndFunction 

// *****************************************
// *********** Variables Initialization

LoadResult = new Structure ( "Document, UID, Error, ErrorText", undefined, 0, false, "" );

#endif