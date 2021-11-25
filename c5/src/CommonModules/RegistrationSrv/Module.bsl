Procedure Send ( User ) export

	env = getEnv ( User );
	tempFolder = GetTempFileName ();
	profile = MailboxesSrv.SystemProfile ();
	message = getRegistrationDataMessage ( env, tempFolder );
	try
		MailboxesSrv.Post ( profile, message );
	except
		WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, Metadata.CommonModules.RegistrationSrv, , ErrorDescription () );
	endtry;
	releaseFiles ( message );
	DeleteFiles ( tempFolder );
	
EndProcedure 

Function getEnv ( User )
	
	userData = DF.Values ( User, "Description, Email, Login.MustChangePassword as MustChangePassword" );
	env = new Structure ();
	env.Insert ( "Company", String ( Constants.Company.Get () ) );
	login = userData.Description;
	env.Insert ( "PasswordIsSet", InfoBaseUsers.FindByName ( login ).PasswordIsSet );
	env.Insert ( "MustChangePassword", userData.MustChangePassword );
	env.Insert ( "User", login );
	env.Insert ( "Email", userData.Email );
	env.Insert ( "TenantCode", DF.Pick ( SessionParameters.Tenant, "Code" ) );
	env.Insert ( "AdminEmail", DF.Pick ( Constants.MainUser.Get (), "Email" ) );
	return env;
	
EndFunction 

Function getRegistrationDataMessage ( Env, TempFolder )
	
	message = new InternetMailMessage ();
	message.From = Cloud.Noreply ();
	message.To.Add ( Env.Email );
	fillRegistrationDataMessage ( Env, message );
	attachFile ( Env, message, TempFolder );
	return message;
	
EndFunction 

Procedure fillRegistrationDataMessage ( Env, Message )
	
	messageParams = new Structure ();
	messageParams.Insert ( "Website", Cloud.Website () );
	messageParams.Insert ( "Support", Cloud.Support () );
	messageParams.Insert ( "Forum", Cloud.Forum () );
	messageParams.Insert ( "Info", Cloud.Info () );
	messageParams.Insert ( "TenantCode", Env.TenantCode );
	messageParams.Insert ( "User", Env.User );
	messageParams.Insert ( "TenantURL", Cloud.GetTenantURL ( Env.TenantCode ) );
	messageParams.Insert ( "AdminEmail", Env.AdminEmail );
	messageParams.Insert ( "ThinClientURL", Cloud.ThinClientURL () );
	messageParams.Insert ( "Company", Env.Company );
	if ( Env.PasswordIsSet ) then
		password = Output.Password2 ( messageParams );
	else
		if ( Env.MustChangePassword ) then
			password = Output.Password1 ();
		else
			password = Output.Password3 ();
		endif; 
	endif; 
	messageParams.Insert ( "Password", password );
	Message.Subject = Output.RegistrationDataEmailSubject ( messageParams );
	Message.Texts.Add ( Output.RegistrationDataEmailBody ( messageParams ) );
	
EndProcedure 

Procedure attachFile ( Env, Message, TempFolder )
	
	CreateDirectory ( TempFolder );
	filePath = TempFolder + "\Infobase.v8i";
	file = new TextWriter ( filePath );
	textParams = new Structure ();
	textParams.Insert ( "TenantCode", Env.TenantCode );
	textParams.Insert ( "ApplicationURL", Cloud.ApplicationURL () );
	text = Output.ApplicationShortcut ( textParams );
	file.Write ( text );
	file.Close ();
	Message.Attachments.Add ( filePath );

EndProcedure 

Procedure releaseFiles ( Message )
	
	Message = undefined;
	
EndProcedure 
