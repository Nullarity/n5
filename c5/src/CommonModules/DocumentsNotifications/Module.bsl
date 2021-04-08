
Procedure Send ( Document, Receivers, Comment ) export
	
	env = getFields ( Document, Comment );
	getAddresses ( env, Receivers );
	if ( env.Addresses.Count () = 0 ) then
		return;
	endif; 
	profile = MailboxesSrv.SystemProfile ();
	message = getMessage ( env );
	try
		MailboxesSrv.Post ( profile, message );
	except
		WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, Metadata.Documents.Document, Env.Document, ErrorDescription () );
	endtry
	
EndProcedure

Function getFields ( Document, Comment )
	
	fields = DF.Values ( Document, "Creator, Subject, Book.Description" );
	fields.Insert ( "Document", Document );
	fields.Insert ( "Comment", Comment );
	return fields;
	
EndFunction 

Procedure getAddresses ( Env, Receivers )
	
	addresses = getUsersAndGroups ( Receivers );
	parts = new Array ();
	if ( addresses.Everybody ) then
		parts.Add ( "
		|select Users.Description as User, Users.Email as Email
		|from Catalog.Users as Users
		|where not Users.DeletionMark
		|and not Users.AccessDenied
		|and not Users.AccessRevoked
		|and Users.Ref <> &Creator
		|" );
	else
		if ( addresses.Users.Count () > 0 ) then
			parts.Add ( "
			|select Users.Description as User, Users.Email as Email
			|from Catalog.Users as Users
			|where Users.Ref in ( &Users )
			|and not Users.DeletionMark
			|and not Users.AccessDenied
			|and not Users.AccessRevoked
			|and Users.Ref <> &Creator
			|" );
		endif; 
		if ( addresses.Groups.Count () > 0 ) then
			parts.Add ( "
			|select Users.User.Description as User, Users.User.Email as Email
			|from InformationRegister.UsersAndGroupsDocuments as Users
			|where Users.UserGroup in ( &Groups )
			|and not Users.User.DeletionMark
			|and not Users.UserGroup.DeletionMark
			|and not Users.User.AccessDenied
			|and not Users.User.AccessRevoked
			|and Users.User.Ref <> &Creator
			|" );
		endif; 
	endif; 
	q = new Query ( StrConcat ( parts, " union " ) );
	q.SetParameter ( "Users", addresses.Users );
	q.SetParameter ( "Groups", addresses.Groups );
	q.SetParameter ( "Creator", Env.Creator );
	Env.Insert ( "Addresses", q.Execute ().Unload () );
	
EndProcedure

Function getUsersAndGroups ( Receivers )
	
	result = new Structure ( "Everybody, Users, Groups", false, new Array (), new Array () );
	result.Everybody = Receivers.Find ( Catalogs.UserGroupsDocuments.Everybody ) <> undefined;
	if ( result.Everybody ) then
		return result;
	endif; 
	typeUser = Type ( "CatalogRef.Users" );
	for each receiver in Receivers do
		if ( TypeOf ( receiver ) = typeUser ) then
			result.Users.Add ( receiver );
		else
			result.Groups.Add ( receiver );
		endif; 
	enddo; 
	return result;
	
EndFunction 

Function getMessage ( Env )
	
	message = new InternetMailMessage ();
	message.From = Cloud.Noreply ();
	for each row in Env.Addresses do
		address = message.To.Add ( row.Email );
		address.DisplayName = row.User;
	enddo; 
	message.Subject = ? ( Env.BookDescription = null, "", Env.BookDescription + ", " ) + Env.Subject;
	p = new Structure ();
	p.Insert ( "User", SessionParameters.User );
	p.Insert ( "Subject", Env.Subject );
	p.Insert ( "URL", Conversion.ObjectToURL ( Env.Document ) );
	if ( IsBlankString ( Env.Comment ) ) then
		comment = "";
	else
		comment = Chars.LF + Output.CreatorComment ( new Structure ( "Comment", Env.Comment ) ) + Chars.LF;
	endif; 
	p.Insert ( "Comment", comment );
	message.Texts.Add ( Output.SubscriptionNotificationBody ( p ) );
	return message;
	
EndFunction 
