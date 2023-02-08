var Box export;
var Profile export;
var Count export;
var ErrorMessage export;
var Stream;
var POP3;
var Set;
var IDs;

Function Load () export
	
	init ();
	initStream ();
	loadEmails ();
	POP3.Pop3EndSession ();
	return true;

EndFunction

Procedure init ()
	
	POP3 = CoreLibrary.Chilkat ( "MailMan" );
	POP3.MailHost = Box.POP3ServerAddress;
	POP3.PopUsername = Box.POP3User;
	POP3.PopPassword = Box.POP3Password;
	POP3.MailPort = Box.POP3Port;
	POP3.PopSsl = Box.POP3UseSSL;
	POP3.Pop3Stls = Box.POP3SecureAuthenticationOnly;
	POP3.ConnectTimeout = Box.Timeout;
	
EndProcedure 

Procedure writeError ()
	
	ErrorMessage = POP3.LastErrorText;
	
EndProcedure 

Procedure initStream ()
	
	Stream = new COMObject ( "SAPI.spFileStream" );
	
EndProcedure 

Function loadEmails ()
	
	if ( Box.Leave ) then
		Set = POP3.GetAllHeaders ( 0 );
	else
		Set = POP3.TransferMail ();
	endif; 
	if ( Set = undefined ) then
		writeError ();
		return false;
	endif;
	extractIDs ();
	bound = Set.MessageCount - 1;
	i = 0;
	portion = 100;
	while ( i <= bound ) do
		j = Min ( bound, i + portion );
		MailChecking.WriteStatus ( Output.LoadingMessages ( new Structure ( "Count, Total", Format ( j, "NG=" ), Format ( bound, "NG=" ) ) ) );
		for k = i to j do
			if ( IDs [ k ].Exists ) then
				continue;
			else
				downloadEmail ( k );
			endif; 
		enddo; 
		i = k + 1;
	enddo; 
	return true;
	
EndFunction 

Procedure extractIDs ()
	
	initIDs ();
	mails = getExistedEmails ();
	for each row in IDs do
		row.Exists = mails.Find ( row.ID, "ID" ) <> undefined;
	enddo; 
	
EndProcedure 

Procedure initIDs ()
	
	IDs = new ValueTable ();
	IDs.Columns.Add ( "ID", new TypeDescription ( "String" ) );
	IDs.Columns.Add ( "Exists", new TypeDescription ( "Boolean" ) );
	bound = Set.MessageCount - 1;
	for i = 0 to bound do
		row = IDs.Add ();
		row.ID = DataProcessors.Email.GetID ( Set.GetEmail ( i ), true );
	enddo; 
	
EndProcedure

Function getExistedEmails ()
	
	s = "
	|select Documents.MessageID as ID
	|from Document.IncomingEmail as Documents
	|where Documents.MessageID in ( &IDs )
	|and not Documents.DeletionMark
	|and Documents.Mailbox = &Mailbox
	|union all
	|select Documents.MessageID
	|from Document.OutgoingEmail as Documents
	|where Documents.MessageID in ( &IDs )
	|and not Documents.DeletionMark
	|and Documents.Mailbox = &Mailbox
	|";
	q = new Query ( s );
	q.SetParameter ( "IDs", IDs.UnloadColumn ( "ID" ) );
	q.SetParameter ( "Mailbox", Box.Ref );
	return q.Execute ().Unload ();
	
EndFunction 

Procedure downloadEmail ( Index )
	
	if ( Box.Leave ) then
		Mail = POP3.GetFullEmail ( Set.GetEmail ( Index ) );
	else
		Mail = Set.GetEmail ( Index );
	endif; 
	DataProcessors.Email.Load ( Box, Profile, Mail, Stream );
	Count = Count + 1;
	
EndProcedure 
