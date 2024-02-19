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
	info = new Structure ( "User, Receiver, Document, Customer, Reason, Yes, No, Amount" );
	info.User = TrimAll ( "" + SessionParameters.User );
	data = DF.Values ( Document, "Document as Source, Document.Amount as Amount, Document.Currency.Description as Currency, Customer.Description as Customer" );
	info.Customer = data.Customer;
	info.Amount = Conversion.NumberToMoney ( data.Amount, data.Currency );
	info.Reason = Reason;
	login = TrimAll ( Receiver.Login );
	info.Receiver = login;
	info.Document = "" + data.Source;
	responsible = Receiver.Ref;
	actions = InformationRegisters.RemoteActions;
	info.Yes = actions.Create ( Enums.RemoteActions.PermissionAllow, Document, responsible );
	info.No = actions.Create ( Enums.RemoteActions.PermissionDeny, Document, responsible );
	message.Subject = Output.SalesRequestSubject ( info );
	body = Output.SalesRequestBody ( info );
	message.Texts.Add ( body, InternetMailTextType.HTML );
	return message;

EndFunction

Function getReceivers ()
	
	access = """" + Metadata.Roles.ApproveSales.Name + """";
	s = "
	|select min ( Users.Ref ) as Ref, min ( Users.Code ) as Login, Users.Email as Email
	|from Catalog.Users as Users
	|where not Users.DeletionMark
	|and not Users.AccessDenied
	|and not Users.AccessRevoked               
	|and Users.Ref in (
	|	select Rights.Ref as User
	|	from Catalog.Users.Rights as Rights
	|	where Rights.RoleName = " + access + "
	|	union
	|	select Memberships.User
	|	from InformationRegister.Membership as Memberships
	|	//
	|	// Group Rights
	|	//
	|	join Catalog.Membership.Rights as GroupRights
	|	on GroupRights.Ref = Memberships.Membership
	|	and GroupRights.RoleName = " + access + "
	|)
	|group by Users.Email
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
		WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, , document,
			ErrorDescription () );
	endtry
	
EndProcedure
