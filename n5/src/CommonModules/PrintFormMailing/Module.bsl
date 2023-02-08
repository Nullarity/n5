
Procedure Send ( Params ) export

	profile = MailboxesSrv.SystemProfile ();
	file = GetTempFileName ( "pdf" );
	message = getMessage ( Params, file );
	try
		MailboxesSrv.Post ( profile, message );
	except
		WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, Metadata.CommonModules.PrintFormMailing, , ErrorDescription () );
	endtry;
	DeleteFiles ( file );
	
EndProcedure 

Function getMessage ( Params, File )
	
	message = new InternetMailMessage ();
	message.From = Cloud.Noreply ();
	message.To.Add ( Params.Receiver );
	body = Output.PrintFormEmailBody ( new Structure ( "Company", Application.Company () ) );
	message.Subject = Params.Subject;
	message.Texts.Add ( body );
	stream = new MemoryStream ();
	Params.Spreadsheet.Write ( stream, SpreadsheetDocumentFileType.PDF );
	data = stream.CloseAndGetBinaryData (); 
	message.Attachments.Add ( data, Params.FileName + ".pdf" );

	return message;
	
EndFunction 
