
Function Default () export
	
	SetPrivilegedMode ( true );
	s = "
	|select 1 as Ordering, top 1 UserSettings.Mailbox as Mailbox
	|from Catalog.UserSettings as UserSettings
	|where UserSettings.Owner = &User
	|union
	|select top 1 2, Mailboxes.Ref
	|from Catalog.Mailboxes as Mailboxes
	|where Mailboxes.Owner = &User
	|and not Mailboxes.DeletionMark
	|order by Ordering
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	return q.Execute ().Unload () [ 0 ].Mailbox;
	
EndFunction 

Function SystemProfile () export
	
	profile = new InternetMailProfile ();
	profile.SMTPServerAddress = Cloud.SMTPServer ();
	profile.SMTPUser = Cloud.SMTPUser ();
	profile.SMTPPassword = Cloud.SMTPPassword ();
	profile.SMTPUseSSL = Cloud.SMTPSSL ();
	profile.SMTPPort = Cloud.SMTPPort ();
	return profile;
	
EndFunction 

Procedure Receive () export
	
	SetPrivilegedMode ( true );
	MailChecking.WriteStatus ( Output.ReceivingProfiles () );
	profile = getBoxes ();
	count = 0;
	error = false;
	errorMessage = "";
	for each box in profile.Boxes do
		MailChecking.WriteStatus ( Output.CheckingMailbox ( new Structure ( "Mailbox", box.Description ) ) );
		if ( box.Protocol = Enums.Protocols.IMAP ) then
			error = not getByIMAP ( box, profile, count, errorMessage );
		else
			error = not getByPOP3 ( box, profile, count, errorMessage );
		endif; 
		if ( error ) then
			break;
		endif; 
	enddo; 
	outgoing = getOutgoing ();
	if ( outgoing = undefined ) then
		if ( error ) then
			MailChecking.WriteStatus ( errorMessage, true, count, getTotal (), 1 );
		else
			MailChecking.WriteStatus ( Output.Loaded ( new Structure ( "Count", count ) ), true, count, getTotal () );
		endif; 
	else
		MailChecking.WriteStatus ( Output.OutgoingError ( new Structure ( "Outgoing", outgoing ) ), true, count, getTotal (), 2, outgoing );
	endif; 
	
EndProcedure 

Function getBoxes ()
	
	s = "
	|select Boxes.Description as Description, Boxes.Ref as Ref, Boxes.POP3Password as POP3Password, Boxes.POP3BeforeSMTP as POP3BeforeSMTP,
	|	Boxes.POP3Port as POP3Port, Boxes.POP3SecureAuthenticationOnly as POP3SecureAuthenticationOnly,
	|	Boxes.POP3ServerAddress as POP3ServerAddress, Boxes.POP3UseSSL as POP3UseSSL, Boxes.Leave as Leave,
	|	Boxes.Timeout as Timeout, Boxes.POP3User as POP3User, not Boxes.Leave as Remove, Boxes.Protocol as Protocol,
	|	Boxes.IMAPPassword as IMAPPassword, Boxes.IMAPPort as IMAPPort, Boxes.IMAPSecureAuthenticationOnly as IMAPSecureAuthenticationOnly,
	|	Boxes.IMAPServerAddress as IMAPServerAddress, Boxes.IMAPUser as IMAPUser, Boxes.IMAPUseSSL as IMAPUseSSL
	|from Catalog.Mailboxes as Boxes
	|where not Boxes.DeletionMark
	|and Boxes.Owner = &User
	|order by Boxes.Code
	|;
	|select Users.TimeZone as TimeZone
	|from Catalog.Users as Users
	|where Users.Ref = &User
	|;
	|select OtherSenders.Ref as Box, OtherSenders.Email as Email
	|from Catalog.Mailboxes.OtherSenders as OtherSenders
	|where not OtherSenders.Ref.DeletionMark
	|and OtherSenders.Ref.Owner = &User
	|union all 
	|select Boxes.Ref, Boxes.Email
	|from Catalog.Mailboxes as Boxes
	|where not Boxes.DeletionMark
	|and Boxes.Owner = &User
	|order by Box
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	data = q.ExecuteBatch ();
	result = new Structure ();
	result.Insert ( "Boxes", data [ 0 ].Unload () );
	result.Insert ( "TimeZone", data [ 1 ].Unload () [ 0 ].TimeZone );
	result.Insert ( "Senders", getSenders ( data [ 2 ].Unload () ) );
	return result;
	
EndFunction 

Function getSenders ( Table )
	
	senders = new Map ();
	for each row in Table do
		if ( senders [ row.Box ] = undefined ) then
			senders [ row.Box ] = new Array ();
		endif; 
		senders [ row.Box ].Add ( Lower ( row.Email ) );
	enddo; 
	return senders;
	
EndFunction 

Function getByIMAP ( Box, Profile, Count, ErrorMessage )
	
	imap = DataProcessors.IMAP.Create ();
	imap.Profile = Profile;
	imap.Box = Box;
	imap.Count = Count;
	imap.ErrorMessage = "";
	result = imap.Load ();
	ErrorMessage = imap.ErrorMessage;
	Count = imap.Count;
	return result;
	
EndFunction 

Function getByPOP3 ( Box, Profile, Count, ErrorMessage )
	
	pop3 = DataProcessors.POP3.Create ();
	pop3.Box = Box;
	pop3.Profile = Profile;
	pop3.Count = Count;
	pop3.ErrorMessage = "";
	result = pop3.Load ();
	ErrorMessage = pop3.ErrorMessage;
	Count = pop3.Count;
	return result;
	
EndFunction 

Function getTotal ()
	
	s = "
	|select count ( NewMail.IncomingEmail ) as Total
	|from InformationRegister.NewMail as NewMail
	|where NewMail.User = &User
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	return q.Execute ().Unload () [ 0 ].Total;
	
EndFunction 

Function getOutgoing ()
	
	s = "
	|select top 1 EmailStatuses.Email as Email
	|from InformationRegister.EmailStatuses as EmailStatuses
	|	//
	|	// Filter by Mailboxes
	|	//
	|	join Catalog.Mailboxes as Mailboxes
	|	on Mailboxes.Owner = &User
	|	and not Mailboxes.DeletionMark
	|	and Mailboxes.Ref = EmailStatuses.Email.Mailbox
	|where EmailStatuses.Status = value ( Enum.EmailStatuses.Error )
	|and not EmailStatuses.Email.DeletionMark
	|order by EmailStatuses.Email.Date
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Email );
	
EndFunction 

Procedure AttachMails ( Label, LabelType, Filter ) export
	
	SetPrivilegedMode ( true );
	if ( Filter = undefined ) then
		table = initTable ();
	else
		table = getMarkedEmail ( Label, LabelType, Filter );
	endif; 
	CollectionsSrv.Join ( table, getFixedEmails ( Label, LabelType ) );
	mailbox = DF.Pick ( Label, "Owner" );
	labels = new Array ();
	labels.Add ( Label );
	for each row in table do
		attachToLabels ( row.Ref, false, labels, mailbox );
	enddo; 
	
EndProcedure 

Function getMarkedEmail ( Label, LabelType, Filter )
	
	result = new ValueTable ();
	schema = getSchema ( LabelType );
	composer = new DataCompositionTemplateComposer ();
	settingsComposer = new DataCompositionSettingsComposer ();
	variant = schema.SettingVariants.Default.Settings;
	settingsComposer.LoadSettings ( variant );
	processor = new DataCompositionProcessor ();
	settingsComposer.LoadUserSettings ( Filter );
	setUser ( settingsComposer );
	template = composer.Execute ( schema, settingsComposer.GetSettings (), , , Type ( "DataCompositionValueCollectionTemplateGenerator" ) );
	processor.Initialize ( template );
	outputProcessor = new DataCompositionResultValueCollectionOutputProcessor ();
	outputProcessor.SetObject ( result );
	outputProcessor.Output ( processor, false );
	return result;
	
EndFunction 

Function initTable ()
	
	result = new ValueTable ();
	result.Columns.Add ( "Ref" );
	return result
	
EndFunction 

Function getSchema ( LabelType )
	
	if ( LabelType = Enums.LabelTypes.Incoming ) then
		return Catalogs.MailLabels.GetTemplate ( "IncomingEmails" );
	else
		return Catalogs.MailLabels.GetTemplate ( "OutgoingEmails" );
	endif; 
	
EndFunction 

Function getFixedEmails ( Label, LabelType )
	
	s = "
	|select Labels.Email as Ref
	|from InformationRegister.FixedMailLabels as Labels
	|where Labels.Label = &Label
	|";
	q = new Query ( s );
	q.SetParameter ( "Label", Label );
	return q.Execute ().Unload ();
	
EndFunction 

Procedure setUser ( SettingsComposer )
	
	creator = DC.GetParameter ( settingsComposer, "User" );
	creator.Use = true;
	creator.Value = SessionParameters.User;
	
EndProcedure 

Procedure attachToLabels ( Email, IsNew, Labels, Mailbox )
	
	if ( Labels.Count () = 0 ) then
		if ( IsNew ) then
			return;
		endif; 
		id = undefined;
	else
		id = labelsToKey ( Labels, Mailbox );
	endif;
	obj = Email.GetObject ();
	obj.Key = id;
	obj.DataExchange.Load = true;
	obj.Write ();
		
EndProcedure

Function labelsToKey ( Labels, Mailbox )
	
	id = findKey ( Labels, Mailbox );
	if ( id = undefined ) then
		obj = Catalogs.MailKeys.CreateItem ();
		obj.Owner = Mailbox;
		table = obj.Labels;
		for each label in Labels do
			row = table.Add ();
			row.Label = label;
		enddo; 
		obj.Write();
		id = obj.Ref;
	endif; 
	return id;
	
EndFunction 

Function findKey ( Labels, Mailbox )
	
	s = "
	|select top 1 Labels.Ref as Ref
	|from (
	|	select MailKeys.Ref as Ref, case when Labels.Label is null then -1 else 1 end as Count
	|	from Catalog.MailKeys.Labels as MailKeys
	|		//
	|		// LabelsCount
	|		//
	|		left join (
	|			select Labels.Ref as Label
	|			from Catalog.MailLabels as Labels
	|			where Labels.Ref in ( &Labels )
	|		) as Labels
	|		on Labels.Label = MailKeys.Label
	|	where MailKeys.Ref.Owner = &Mailbox
	|	union all
	|	select MailKeys.Ref, -1
	|	from Catalog.MailKeys as MailKeys,
	|		 Catalog.MailLabels as MailLabels
	|	where MailKeys.Owner = &Mailbox
	|	and MailLabels.Ref in ( &Labels )
	|) as Labels
	|group by Labels.Ref
	|having sum ( Labels.Count ) = 0
	|";
	q = new Query ( s );
	q.SetParameter ( "Labels", Labels );
	q.SetParameter ( "Mailbox", Mailbox );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction

Procedure AttachLabels ( Email, IsNew, FixedLabel, Mailbox ) export
	
	SetPrivilegedMode ( true );
	if ( FixedLabel.IsEmpty () ) then
		labelType = getLabelType ( Email );
		list = getLabels ( Mailbox, labelType );
		labels = evaluateLabels ( Email, LabelType, list );
	else
		labels = new Array ();
		labels.Add ( FixedLabel );
	endif;
	attachToLabels ( Email, IsNew, labels, Mailbox );
	
EndProcedure 

Function getLabelType ( Email )
	
	if ( TypeOf ( Email ) = Type ( "DocumentRef.IncomingEmail" ) ) then
		return Enums.LabelTypes.Incoming;
	else
		return Enums.LabelTypes.Outgoing;
	endif; 
	
EndFunction 

Function getLabels ( Mailbox, LabelType )
	
	s = "
	|select MailLabels.Ref as Ref, MailLabels.Filter as Filter
	|from Catalog.MailLabels as MailLabels
	|where MailLabels.User = &User
	|and not MailLabels.DeletionMark
	|and not MailLabels.System
	|and MailLabels.Owner = &Mailbox
	|and MailLabels.LabelType = &LabelType
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Mailbox", Mailbox );
	q.SetParameter ( "LabelType", LabelType );
	table = q.Execute ().Unload ();
	return table;
	
EndFunction 

Function evaluateLabels ( Email, LabelType, Labels )
	
	schema = getSchema ( LabelType );
	composer = new DataCompositionTemplateComposer ();
	settingsComposer = new DataCompositionSettingsComposer ();
	variant = schema.SettingVariants.Default.Settings;
	settingsComposer.LoadSettings ( variant );
	setEmail ( Email, settingsComposer );
	resultType = Type ( "DataCompositionValueCollectionTemplateGenerator" );
	processor = new DataCompositionProcessor ();
	list = new Array ();
	for each label in Labels do
		filter = label.Filter.Get ();
		if ( filter = undefined ) then
			continue;
		endif; 
		settingsComposer.LoadUserSettings ( filter );
		reference = label.Ref;
		setLabel ( reference, settingsComposer );
		template = composer.Execute ( schema, settingsComposer.GetSettings (), , , resultType );
		processor.Initialize ( template );
		outputProcessor = new DataCompositionResultValueCollectionOutputProcessor ();
		result = new ValueTable ();
		outputProcessor.SetObject ( result );
		outputProcessor.Output ( processor, false );
		if ( result.Count () = 1 ) then
			list.Add ( label );
		endif;
	enddo; 
	return list;
	
EndFunction

Procedure setEmail ( Email, SettingsComposer )
	
	param = DC.GetParameter ( SettingsComposer, "Email" );
	param.Use = true;
	param.Value = Email;
	
EndProcedure 

Procedure setLabel ( Label, SettingsComposer )
	
	param = DC.GetParameter ( SettingsComposer, "Label" );
	param.Use = true;
	param.Value = Label;
	
EndProcedure 

Function GetLabel ( Email ) export
	
	return InformationRegisters.FixedMailLabels.Get ( new Structure ( "Email", Email ) ).Label;
	
EndFunction

Procedure SaveLabel ( Email, Label ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.FixedMailLabels.CreateRecordManager ();
	r.Email = Email;
	if ( Label.IsEmpty () ) then
		r.Delete ();
	else
		r.Read ();
		if ( r.Label <> Label ) then
			r.Email = Email;
			r.Label = Label;
			r.Write ();
		endif; 
	endif; 
	
EndProcedure 

Procedure MarkEmails ( Emails, Label, FromTrash ) export
	
	SetPrivilegedMode ( true );
	for each document in Emails do
		if ( FromTrash ) then
			resetDeletionMark ( document );
		endif; 
		writeFixedLabel ( document, label );
		MailboxesSrv.AttachLabels ( document, false, Label, DF.Pick ( document, "Mailbox" ) );
	enddo; 
	
EndProcedure 

Procedure resetDeletionMark ( Email )
	
	obj = Email.GetObject ();
	obj.SetDeletionMark ( false );
	
EndProcedure 

Procedure writeFixedLabel ( Email, Label )
	
	r = InformationRegisters.FixedMailLabels.CreateRecordManager ();
	r.Email = Email;
	r.Label = Label;
	r.Write ();
	
EndProcedure 

Procedure DeleteEmails ( JobKey, Emails ) export
	
	SetPrivilegedMode ( true );
	box = getBox ( Emails );
	if ( box.Protocol = Enums.Protocols.IMAP ) then
		deleteThroughIMAP ( JobKey, box, Emails );
	endif; 

EndProcedure 

Function getBox ( Emails )
	
	s = "
	|select Boxes.POP3Password as POP3Password, Boxes.POP3BeforeSMTP as POP3BeforeSMTP,
	|	Boxes.POP3Port as POP3Port, Boxes.POP3SecureAuthenticationOnly as POP3SecureAuthenticationOnly,
	|	Boxes.POP3ServerAddress as POP3ServerAddress, Boxes.POP3UseSSL as POP3UseSSL, Boxes.Leave as Leave,
	|	Boxes.Timeout as Timeout, Boxes.POP3User as POP3User, not Boxes.Leave as Remove, Boxes.Protocol as Protocol,
	|	Boxes.IMAPPassword as IMAPPassword, Boxes.IMAPPort as IMAPPort, Boxes.IMAPSecureAuthenticationOnly as IMAPSecureAuthenticationOnly,
	|	Boxes.IMAPServerAddress as IMAPServerAddress, Boxes.IMAPUser as IMAPUser, Boxes.IMAPUseSSL as IMAPUseSSL, Boxes.Email as Email
	|from Catalog.Mailboxes as Boxes
	|where Boxes.Ref = &Mailbox
	|";
	q = new Query ( s );
	q.SetParameter ( "Mailbox", DF.Pick ( Emails [ 0 ], "Mailbox" ) );
	return q.Execute ().Unload () [ 0 ];
	
EndFunction 

Procedure deleteThroughIMAP ( JobKey, Box, Emails )

	IMAP = initIMAP ();
	if ( not connect ( JobKey, IMAP, Box ) ) then
		IMAP.Disconnect ();
		return;
	endif;
	label = undefined;
	set = undefined;
	references = undefined;
	table = getIDs ( Emails );
	for each row in table do
		if ( label <> row.Label ) then
			if ( label <> undefined ) then
				if ( not IMAP.SetFlags ( Set, "Deleted", 1 ) ) then
					Progress.Put ( IMAP.LastErrorText, JobKey, true );
					IMAP.Disconnect ();
					return;
				endif;
			endif; 
			references = new Array ();
			set = new COMObject ( "Chilkat_9_5_0.MessageSet" );
			set.HasUids = true;
			label = row.Label;
			result = IMAP.SelectMailbox ( label );
			if ( not result ) then
				Progress.Put ( IMAP.LastErrorText, JobKey, true );
				IMAP.Disconnect ();
				return;
			endif; 
		endif;
		set.InsertId ( row.UID );
		references.Add ( row.Email );
	enddo; 
	if ( set <> undefined and set.Count > 0 ) then
		if ( not IMAP.SetFlags ( Set, "Deleted", 1 ) ) then
			Progress.Put ( IMAP.LastErrorText, JobKey, true );
			IMAP.Disconnect ();
			return;
		endif; 
	endif; 
	IMAP.Disconnect ();
	
EndProcedure 

Function initIMAP ()
	
	obj = CoreLibrary.Chilkat ( "Imap" );
	return obj;
	
EndFunction 

Function connect ( JobKey, IMAP, Box )
	
	IMAP.ConnectTimeout = Box.Timeout;
	IMAP.Port = Box.IMAPPort;
	IMAP.Ssl = Box.IMAPUseSSL;
	IMAP.StartTls = Box.IMAPSecureAuthenticationOnly;
	result = IMAP.Connect ( Box.IMAPServerAddress );
	if ( not result ) then
		Progress.Put ( IMAP.LastErrorText, JobKey, true );
		return false;
	endif; 
	result = IMAP.Login ( Box.IMAPUser, Box.IMAPPassword );
	if ( not result ) then
		Progress.Put ( IMAP.LastErrorText, JobKey, true );
		return false;
	endif; 
	return true;
	
EndFunction 

Function getIDs ( Emails )
	
	s = "
	|select MailLabels.UID as UID, MailLabels.Label.Description as Label, MailLabels.Email as Email
	|from InformationRegister.MailLabels as MailLabels
	|where MailLabels.Email in ( &Emails )
	|order by Label, UID
	|";
	q = new Query ( s );
	q.SetParameter ( "Emails", Emails );
	return q.Execute ().Unload ();
	
EndFunction 

Procedure DeleteDocuments ( Emails ) export
	
	SetPrivilegedMode ( true );
	BeginTransaction ();
	for each document in Emails do
		obj = document.GetObject ();
		obj.SetDeletionMark ( true );
	enddo; 
	CommitTransaction ();
	
EndProcedure 

Procedure Send ( JobKey, Email, IsNew, Label, Mailbox ) export
	
	SetPrivilegedMode ( true );
	if ( IsNew ) then
		MailboxesSrv.AttachLabels ( Email, IsNew, Label, Mailbox );
	endif; 
	obj = DataProcessors.SMTP.Create ();
	obj.Email = Email;
	if ( not obj.Send () ) then
		Progress.Put ( obj.ErrorMessage, JobKey, true );
	endif;
	
EndProcedure 

Procedure Post ( Profile, Message ) export
	
	SetPrivilegedMode ( true );
	mail = new InternetMail ();
	mail.Logon ( Profile );
	mail.Send ( Message );
	mail.Logoff ();
	
EndProcedure 

Procedure WriteSuccessfull ( Email ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.EmailStatuses.CreateRecordManager ();
	r.Email = Email;
	r.Details = "";
	r.Status = Enums.EmailStatuses.Successfull;
	r.Write ();
	
EndProcedure 
