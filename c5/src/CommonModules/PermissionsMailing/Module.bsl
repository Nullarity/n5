Procedure Send ( Document, Reason ) export
	
	profile = MailboxesSrv.SystemProfile ();
	for each receiver in getReceivers () do
		message = createMessage ( Document, Reason, receiver );
		try
			MailboxesSrv.Post ( profile, message );
		except
			WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, , Document, ErrorDescription () );
		endtry
	enddo;
	
EndProcedure

Function createMessage ( Document, Reason, Receiver )
	
	message = new InternetMailMessage ();
	message.From = Cloud.Noreply ();
	message.To.Add ( Receiver.Email );
	info = new Structure ( "User, Receiver, Document, Customer, Reason, Yes, No" );
	info.User = TrimAll ( "" + SessionParameters.User );
	info.Customer = DF.Pick ( Document, "Customer.Description" );
	info.Reason = Reason;
	login = TrimAll ( Receiver.Login );
	info.Receiver = login;
	info.Document = "" + Document;
	service = Cloud.RemoteActionsService () + "/hs/RemoteActions?ID=" + Document.UUID () + "&User=" + login + "&Action=";
	info.Yes = service + Conversion.EnumItemToName ( Enums.AllowDeny.Allow );
	info.No = service + Conversion.EnumItemToName ( Enums.AllowDeny.Deny );
	message.Subject = Output.SalesRequestSubject ( info );
	body = Output.SalesRequestBody ( info );
	message.Texts.Add ( body, InternetMailTextType.HTML );
	return message;
	
EndFunction

Function getReceivers ()
	
	s = "
	|select Users.Email as Email, Users.Code as Login
	|from Catalog.Users as Users
	|where not Users.DeletionMark
	|and not Users.AccessDenied
	|and not Users.AccessRevoked
	|and Users.Rights.RoleName = ""ApproveSales""
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction

Procedure NotifyUser ( Params ) export
	
	creator = Params.Creator;
	receiver = DF.Pick ( creator, "Email" );
	if ( IsBlankString ( receiver ) ) then
		return;
	endif;
	info = new Structure ( "Creator, Document, Resolution, Responsible, Customer" );
	FillPropertyValues ( info, Params );
	info.Responsible = TrimAll ( Params.Responsible );
	info.Creator = TrimAll ( Params.Creator );
	document = Params.Document;
	info.Customer = DF.Pick ( document, "Customer.Description" );
	profile = MailboxesSrv.SystemProfile ();
	message = new InternetMailMessage ();
	message.From = Cloud.Noreply ();
	message.To.Add ( receiver );
	if ( Params.Resolution = Enums.AllowDeny.Allow ) then
		message.Subject = Output.SalesNotifyUserSubject1 ( info );
		body = Output.SalesNotifyUserBody1 ( info );
	else
		message.Subject = Output.SalesNotifyUserSubject2 ( info );
		body = Output.SalesNotifyUserBody2 ( info );
	endif;
	message.Texts.Add ( body, InternetMailTextType.HTML );
	try
		MailboxesSrv.Post ( profile, message );
	except
		WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, , Document,
			ErrorDescription () );
	endtry
	
EndProcedure
