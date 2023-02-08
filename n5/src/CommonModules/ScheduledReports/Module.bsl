Procedure Generate ( RecordKey ) export
	
	p = getParams ( RecordKey );
	name = getName ( p.ReportPath );
	report = Reporter.Make ( name, p.Variant, p.Settings.Get () );
	if ( report.Params.Empty
		and not p.SendEmpty ) then
		return;
	endif; 
	write ( p, report );
	
EndProcedure 

Function getParams ( RecordKey )
	
	s = "
	|select top 1 Schedule.*, Schedule.Report.Path as ReportPath
	|from InformationRegister.ScheduledReports as Schedule
	|where Schedule.RecordKey = &RecordKey
	|";
	q = new Query ( s );
	q.SetParameter ( "RecordKey", RecordKey );
	SetPrivilegedMode ( true );
	p = q.Execute ().Unload () [ 0 ];
	SetPrivilegedMode ( false );
	return p;
	
EndFunction 

Function getName ( ReportPath )
	
	return Mid ( ReportPath, Find ( ReportPath, "." ) + 1 );
	
EndFunction 

Procedure write ( Params, Report )
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.SendingReports.CreateRecordManager ();
	FillPropertyValues ( r, Params );
	r.Tenant = SessionParameters.Tenant;
	r.Data = new ValueStorage ( Report.Params.Result );
	r.Write ();
	SetPrivilegedMode ( false );
	
EndProcedure 

Procedure Send () export
	
	SetPrivilegedMode ( true );
	table = getTable ();
	if ( table.Count () = 0 ) then
		return;
	endif; 
	folder = GetTempFileName ();
	profile = MailboxesSrv.SystemProfile ();
	CreateDirectory ( folder );
	for each row in table do
		setTenant ( row );
		sendEmail ( row, profile, folder );
		clean ( row );
	enddo; 
	DeleteFiles ( folder );
	SetPrivilegedMode ( false );
	
EndProcedure 

Function getTable ()
	
	s = "
	|select SendingReports.*, SendingReports.Report.Path as ReportPath
	|from InformationRegister.SendingReports as SendingReports
	|order by SendingReports.Tenant
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction 

Procedure setTenant ( Row )
	
	SessionParameters.Tenant = Row.Tenant;
	SessionParameters.TenantUse = true;
	
EndProcedure 

Procedure sendEmail ( Row, Profile, TempFolder )

	message = new InternetMailMessage ();
	setSenderAndReceiver ( Row, message );
	setSubjectAndBody ( Row, message );
	attachFile ( Row, message, TempFolder );
	try
		MailboxesSrv.Post ( Profile, message );
	except
		WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, Metadata.ScheduledJobs.SendingReports, , ErrorDescription () );
	endtry
	
EndProcedure 

Procedure setSenderAndReceiver ( Row, Message )
	
	Message.From = Cloud.Noreply ();
	addresses = Conversion.StringToArray ( Row.Receiver );
	for each address in addresses do
		Message.To.Add ( address );
	enddo; 
	addresses = Conversion.StringToArray ( Row.Copy );
	for each address in addresses do
		Message.Cc.Add ( address );
	enddo; 
	
EndProcedure

Procedure setSubjectAndBody ( Row, Message )
	
	recordKey = InformationRegisters.ScheduledReports.CreateRecordKey ( new Structure ( "User, Report", Row.User, Row.Report ) );
	url = Conversion.ObjectToURL ( recordKey );
	name = getName ( row.ReportPath );
	presentation = Metadata.Reports [ name ].Presentation ();
	Message.Subject = presentation;
	p = new Structure ();
	p.Insert ( "ReportPresentation", presentation );
	p.Insert ( "ScheduleSettingsURL", url );
	p.Insert ( "Website", Cloud.Website () );
	Message.Texts.Add ( Output.ReportByEmailBody ( p ) );
	
EndProcedure

Procedure attachFile ( Row, Message, Folder )
	
	path = Folder + "\Report." + FileSystem.TableExtension ( Row.AttachmentType );
	data = Row.Data.Get ();
	data.Write ( path, FileSystem.SpreadsheetType ( Row.AttachmentType ) );
	Message.Attachments.Add ( path );

EndProcedure 

Procedure clean ( Row )
	
	r = InformationRegisters.SendingReports.CreateRecordManager ();
	FillPropertyValues ( r, Row );
	r.Delete ();
	
EndProcedure 
