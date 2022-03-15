Procedure Send ( Document ) export
	
	profile = MailboxesSrv.SystemProfile ();
	data = getData ( Document );
	for each receiver in data.Receivers do
		message = createMessage ( Document, data, receiver );
		try
			MailboxesSrv.Post ( profile, message );
		except
			WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, , Document, ErrorDescription () );
		endtry
	enddo;
	
EndProcedure

Function getData ( Document )
	
	s = "
	|// #Receivers
	|select min ( Users.Ref ) as Ref, min ( Users.Code ) as Login, Users.Email as Email
	|from Catalog.Users as Users
	|where not Users.DeletionMark
	|and not Users.AccessDenied
	|and not Users.AccessRevoked
	|and Users.Rights.RoleName in ( """
	+ Metadata.Roles.Administrator.Name + """, """
	+ Metadata.Roles.RolesEdit.Name + """ )
	|group by Users.Email
	|;
	|// @Permission
	|select presentation ( Documents.Document ) as Document, Documents.Day as Day,
	|	Documents.Organization.Description as Organization, Documents.Company.Description as Company,
	|	Documents.Creator.Description as User
	|from Document.ChangesPermission as Documents
	|where Documents.Ref = &Ref
	|";
	data = SQL.Create ( s );
	q = data.Q;
	q.SetParameter ( "Ref", Document );
	SQL.Perform ( data );
	permission = data.Permission;
	day = Format ( permission.Day, "DLF=D" );
	details = new Structure ( "Day, User, Details",
		day,
		permission.User,
		Conversion.ValuesToString ( day, permission.Organization, permission.Document, permission.Company )
	 );
	return new Structure ( "Receivers, Details", data.Receivers, details );
	
EndFunction

Function createMessage ( Document, Data, Receiver )
	
	message = new InternetMailMessage ();
	message.From = Cloud.Noreply ();
	message.To.Add ( Receiver.Email );
	info = new Structure ( "User, Receiver, Day, Details, Yes, No" );
	FillPropertyValues ( info, Data.Details );
	login = TrimAll ( Receiver.Login );
	info.Receiver = login;
	responsible = Receiver.Ref;
	actions = InformationRegisters.RemoteActions;
	info.Yes = actions.Create ( Enums.RemoteActions.ChangesAllow, Document, responsible );
	info.No = actions.Create ( Enums.RemoteActions.ChangesDeny, Document, responsible );
	message.Subject = Output.ChangesRequestSubject ( info );
	body = Output.ChangesRequestBody ( info );
	message.Texts.Add ( body, InternetMailTextType.HTML );
	return message;

EndFunction

Procedure NotifyUser ( Params ) export
	
	creator = Params.Creator;
	receiver = DF.Pick ( creator, "Email" );
	if ( IsBlankString ( receiver ) ) then
		return;
	endif;
	info = new Structure ( "Permission, Responsible" );
	FillPropertyValues ( info, Params );
	profile = MailboxesSrv.SystemProfile ();
	message = new InternetMailMessage ();
	message.From = Cloud.Noreply ();
	message.To.Add ( receiver );
	if ( Params.Resolution = Enums.AllowDeny.Allow ) then
		message.Subject = Output.ChangesNotifyUserSubject1 ( info );
		body = Output.ChangesNotifyUserBody1 ( info );
	else
		message.Subject = Output.ChangesNotifyUserSubject2 ( info );
		body = Output.ChangesNotifyUserBody2 ( info );
	endif;
	message.Texts.Add ( body, InternetMailTextType.HTML );
	try
		MailboxesSrv.Post ( profile, message );
	except
		WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, , Params.Permission,
			ErrorDescription () );
	endtry
	
EndProcedure
