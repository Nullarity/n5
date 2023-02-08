var Box export;
var Profile export;
var Count export;
var ErrorMessage export;
var Stream;
var IMAP;
var Env;
var Label;
var Labels;
var IMAPLabel;
var IMAPLabels;
var IDs;
var Set;
var Headers;
var MailLabels;
var LastUID;
var OldEmails;

Function Load () export
	
	init ();
	getLabels ();
	if ( not connect () ) then
		return error ();
	endif; 
	if ( not getIMAPLabels () ) then
		return error ();
	endif; 
	initStream ();
	for each IMAPLabel in IMAPLabels do
		setLabel ();
		if ( not loadEmails () ) then
			return error ();
		endif; 
	enddo; 
	IMAP.Disconnect ();
	return true;

EndFunction

Procedure init ()
	
	IMAP = CoreLibrary.Chilkat ( "Imap" );
	
EndProcedure 

Procedure getLabels ()
	
	s = "
	|select MailLabels.Ref as Ref, MailLabels.Description as Name, MailLabels.SortOrder as SortOrder, isnull ( UIDs.UID, 0 ) + 1 as NextUID, false as Exists
	|from Catalog.MailLabels as MailLabels
	|	//
	|	// UIDs
	|	//
	|	left join InformationRegister.UIDs as UIDs
	|	on UIDs.Label = MailLabels.Ref
	|where not MailLabels.DeletionMark
	|and MailLabels.LabelType = value ( Enum.LabelTypes.IMAP )
	|and MailLabels.User = &User
	|and MailLabels.Owner = &Box
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Box", Box.Ref );
	Labels = q.Execute ().Unload ();
	
EndProcedure 

Function connect ()
	
	IMAP.ConnectTimeout = Box.Timeout;
	IMAP.Port = Box.IMAPPort;
	IMAP.Ssl = Box.IMAPUseSSL;
	IMAP.StartTls = Box.IMAPSecureAuthenticationOnly;
	result = IMAP.Connect ( Box.IMAPServerAddress );
	if ( not result ) then
		ErrorMessage = IMAP.LastErrorText;
		return false;
	endif; 
	if ( yahoo () ) then
		responce = IMAP.SendRawCommand ( "ID (""GUID"" ""1"")" );
		if ( responce = undefined ) then
			ErrorMessage = IMAP.LastErrorText;
			return false;
		endif; 
	endif; 
	result = IMAP.Login ( Box.IMAPUser, Box.IMAPPassword );
	if ( not result ) then
		ErrorMessage = IMAP.LastErrorText;
		return false;
	endif; 
	return true;
	
EndFunction 

Function yahoo ()
	
	return Find ( Box.IMAPServerAddress, ".yahoo." ) > 0;
	
EndFunction 

Function error ()
	
	IMAP.Disconnect ();
	return false;
	
EndFunction 

Function getIMAPLabels ()
	
	IMAPLabels = initIMAPLabels ();
	list = IMAP.ListMailboxes ( "", "*" );
	if ( list = undefined ) then
		ErrorMessage = IMAP.LastErrorText;
		return false;
	endif; 
	bound = list.Count - 1;
	for i = 0 to bound do
		if ( not list.IsSelectable ( i ) ) then
			continue;
		endif; 
		row = IMAPLabels.Add ();
		row.Name = list.GetName ( i );
		row.SortOrder = i;
	enddo; 
	return true;
	
EndFunction 

Function initIMAPLabels ()
	
	table = new ValueTable ();
	table.Columns.Add ( "Name", new TypeDescription ( "String" ) );
	table.Columns.Add ( "SortOrder", new TypeDescription ( "Number" ) );
	return table;
	
EndFunction 

Procedure initStream ()
	
	Stream = new COMObject ( "SAPI.spFileStream" );
	
EndProcedure 

Procedure setLabel ()
	
	Label = Labels.Find ( IMAPLabel.Name, "Name" );
	if ( Label = undefined ) then
		newLabel ();
	else
		Label.Exists = true;
		if ( Label.SortOrder <> IMAPLabel.SortOrder ) then
			setSortOrder ();
		endif; 
	endif; 
	
EndProcedure 

Procedure newLabel ()
	
	obj = Catalogs.MailLabels.CreateItem ();
	obj.Description = IMAPLabel.Name;
	obj.SortOrder = IMAPLabel.SortOrder;
	obj.LabelType = Enums.LabelTypes.IMAP;
	obj.User = SessionParameters.User;
	obj.Owner = Box.Ref;
	obj.System = ( Lower ( IMAPLabel.Name ) = "inbox" );
	obj.Write ();
	Label = Labels.Add ();
	Label.Ref = obj.Ref;
	Label.Name = IMAPLabel.Name;
	Label.SortOrder = IMAPLabel.SortOrder;
	Label.NextUID = 1;
	Label.Exists = true;
	
EndProcedure

Procedure setSortOrder ()
	
	Label.SortOrder = IMAPLabel.SortOrder;
	obj = Label.Ref.GetObject ();
	obj.SortOrder = Label.SortOrder;
	obj.Write ();
	
EndProcedure 

Function loadEmails ()
	
	result = IMAP.SelectMailbox ( IMAPLabel.Name );
	if ( not result ) then
		ErrorMessage = IMAP.LastErrorText;
		return false;
	endif; 
	Set = IMAP.Search ( "UID " + Format ( Label.NextUID, "NG=;NZ=" ) + ":*", true );
	if ( Set = undefined ) then
		ErrorMessage = IMAP.LastErrorText;
		return false;
	endif;
	if ( not newMail () ) then
		return true;
	endif; 
	bound = Set.Count - 1;
	i = firstUnread ();
	portion = 99;
	while ( i <= bound ) do
		j = Min ( bound, i + portion );
		MailChecking.WriteStatus ( Output.LoadingMessages ( new Structure ( "Count, Total", IMAPLabel.Name + ", " + Format ( j + 1, "NG=;NZ=" ), Format ( bound + 1, "NG=;NZ=" ) ) ) );
		mailset = getMailSet ( i, j );
		Headers = IMAP.FetchHeaders ( mailset );
		if ( Headers = undefined ) then
			ErrorMessage = IMAP.LastErrorText;
			return false;
		endif; 
		extractIDs ();
		getOldEmails ();
		BeginTransaction ();
		attachAndExcludeOldEmails ();
		if ( IDs.Count () > 0 ) then
			if ( not loadNewEmails () ) then
				return false;
			endif;
		endif;
		writeLastUID ();
		CommitTransaction ();
		i = i + portion + 1;
	enddo; 
	return true;
	
EndFunction 

Function firstUnread ()
	
	i = Set.Count - 1;
	starter = Label.NextUID;
	while ( i >= 0 ) do
		if ( Set.GetId ( i ) <= starter ) then
			return i;
		endif; 
		i = i - 1;
	enddo;
	return 0;
	
EndFunction

Function newMail ()
	
	return ( Set.Count > 0 ) and ( Set.GetId ( Set.Count - 1 ) >= Label.NextUID );
	
EndFunction 

Function getMailSet ( Start, End )
	
	mailSet = new COMObject ( "Chilkat_9_5_0.MessageSet" );
	mailSet.HasUids = true;
	for i = Start to End do
		mailSet.InsertId ( Set.GetId ( i ) );
	enddo; 
	return mailSet;
	
EndFunction 

Procedure extractIDs ()
	
	IDs = initUIDs ();
	bound = Headers.MessageCount - 1;
	for i = 0 to bound do
		mail = Headers.GetEmail ( i );
		incoming = DataProcessors.Email.IsIncoming ( mail, Box.Ref, Profile.Senders );
		row = IDs.Add ();
		row.ID = DataProcessors.Email.GetID ( mail, incoming );
		row.UID = mail.GetImapUid ();
	enddo; 
	IDs.Sort ( "UID" );
	LastUID = IDs [ bound  ].UID;
	
EndProcedure 

Function initUIDs ()
	
	table = new ValueTable ();
	table.Columns.Add ( "ID", new TypeDescription ( "String" ) );
	table.Columns.Add ( "UID", new TypeDescription ( "Number" ) );
	return table;
	
EndFunction 

Procedure getOldEmails ()
	
	s = "
	|select Documents.Ref as Ref, Documents.MessageID as ID,
	|	case when Labels.Label is null then true else false end as NewLabel
	|from Document.IncomingEmail as Documents
	|	//
	|	// Labels
	|	//
	|	left join InformationRegister.MailLabels as Labels
	|	on Labels.Label = &Label
	|	and Labels.Email = Documents.Ref
	|where Documents.MessageID in ( &IDs )
	|and Documents.Mailbox = &Mailbox
	|and not Documents.DeletionMark
	|union all
	|select Documents.Ref, Documents.MessageID, case when Labels.Label is null then true else false end
	|from Document.OutgoingEmail as Documents
	|	//
	|	// Labels
	|	//
	|	left join InformationRegister.MailLabels as Labels
	|	on Labels.Label = &Label
	|	and Labels.Email = Documents.Ref
	|where Documents.MessageID in ( &IDs )
	|and Documents.Mailbox = &Mailbox
	|and not Documents.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "IDs", IDs.UnloadColumn ( "ID" ) );
	q.SetParameter ( "Mailbox", Box.Ref );
	q.SetParameter ( "Label", Label.Ref );
	Oldemails = q.Execute ().Unload ();
	
EndProcedure

Procedure attachAndExcludeOldEmails ()
	
	record = InformationRegisters.MailLabels.CreateRecordManager ();
	for each row in OldEmails do
		foundRow = IDs.Find ( row.ID, "ID" );
		if ( foundRow = undefined ) then
			continue;
		endif; 
		if ( row.NewLabel ) then
			record.Label = Label.Ref;
			record.Email = row.Ref;
			record.UID = foundRow.UID;
			record.Write ();
		endif; 
		IDs.Delete ( foundRow );
	enddo; 
	
EndProcedure 

Function loadNewEmails ()
	
	mailset = idsToSet ();
	bundle = IMAP.FetchBundle ( mailset );
	if ( bundle = undefined ) then
		ErrorMessage = IMAP.LastErrorText;
		return false;
	endif; 
	bound = bundle.MessageCount - 1;
	for i = 0 to bound do
		mail = bundle.GetEmail ( i );
		attachedEmails = new Array ();
		result = DataProcessors.Email.Load ( Box, Profile, mail, Stream, attachedEmails );
		if ( result.Error ) then
			ErrorMessage = result.ErrorText;
			return false;
		endif;
		attachNewEmail ( result.Document, result.UID );
		for each attachment in attachedEmails do
			attachNewEmail ( attachment.Document, attachment.UID );
		enddo; 
		Count = Count + 1;
	enddo; 
	return true;

EndFunction 

Function idsToSet ()
	
	mailSet = new COMObject ( "Chilkat_9_5_0.MessageSet" );
	for each row in IDs do
		mailSet.InsertId ( row.UID );
	enddo; 
	return mailSet;
	
EndFunction 

Procedure attachNewEmail ( Document, UID )
	
	record = InformationRegisters.MailLabels.CreateRecordManager ();
	record.Label = Label.Ref;
	record.Email = Document;
	record.UID = UID;
	record.Write ();
	
EndProcedure 

Procedure writeLastUID ()
	
	if ( LastUID = 0 ) then
		return;
	endif; 
	r = InformationRegisters.UIDs.CreateRecordManager ();
	r.Label = Label.Ref;
	r.UID = LastUID;
	r.Write ();
	
EndProcedure 
