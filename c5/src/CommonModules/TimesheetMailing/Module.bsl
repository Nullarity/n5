Function GetParams () export
	
	p = new Structure ();
	p.Insert ( "Action" );
	p.Insert ( "Email" );
	p.Insert ( "TimesheetURL" );
	p.Insert ( "UserSettingsURL" );
	p.Insert ( "Employee" );
	p.Insert ( "User" );
	p.Insert ( "TimesheetNumber" );
	return p;
	
EndFunction 

Procedure Send ( Params ) export

	profile = MailboxesSrv.SystemProfile ();
	message = getMessage ( Params );
	try
		MailboxesSrv.Post ( profile, message );
	except
		WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, Metadata.CommonModules.TimesheetMailing, , ErrorDescription () );
	endtry

EndProcedure 

Function getMessage ( Params )
	
	message = new InternetMailMessage ();
	message.From = Cloud.Noreply ();
	message.To.Add ( Params.Email );
	fillMessage ( Params, message );
	return message;
	
EndFunction 

Procedure fillMessage ( Params, Message )
	
	Params.Insert ( "Support", Cloud.Noreply () );
	Params.Insert ( "Website", Cloud.Website () );
	if ( Params.Action = "SendForApproval" ) then
		Message.Subject = Output.ApprovalEmailSubject ( Params );
		body = Output.ApprovalEmailBody ( Params );
	elsif ( Params.Action = "SendToRework" ) then
		Message.Subject = Output.ReworkTimesheetEmailSubject ( Params );
		body = Output.ReworkTimesheetEmailBody ( Params );
	elsif ( Params.Action = "SendRejectionToCreator" ) then
		Message.Subject = Output.RejectTimesheetEmailSubject ( Params );
		body = Output.RejectTimesheetEmailBody ( Params );
	elsif ( Params.Action = "SendCompletionToCreator" ) then
		Message.Subject = Output.TimesheetApprovalCompleteEmailSubject ( Params );
		body = Output.TimesheetApprovalCompleteEmailBody ( Params );
	endif; 
	body = body + Output.NotificationEmailFooter ( Params );
	Message.Texts.Add ( body );
	
EndProcedure 
