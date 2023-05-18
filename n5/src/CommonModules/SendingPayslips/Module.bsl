Procedure Send ( Ref ) export

	SetPrivilegedMode ( true );
	env = getData ( Ref );
	initComposer ( env );
	initFolder ( env );
	profile = MailboxesSrv.SystemProfile ();
	for each row in env.Employees do
		message = getMessage ( row, Env );
		try
			MailboxesSrv.Post ( profile, message );
		except
			WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error,
				Metadata.ScheduledJobs.SendingPayslips, , ErrorDescription () );
		endtry;
		releaseFile ( message );
	enddo;
	DeleteFiles ( env.Folder );
	Jobs.Remove ( Ref );
	
EndProcedure 

Function getData ( Ref )
	
	env = new Structure ();
	env.Insert ( "Ref", Ref );
	SQL.Init ( env );
	sqlFields ( env );
	Env.Q.SetParameter ( "Ref", env.Ref );
	SQL.Perform ( env );
	env.Insert ( "Month", Format ( env.Fields.Month, "DF=MM.yyyy" ) );
	return env;

EndFunction

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Document.Month as Month
	|from Document.SendingPayslips as Document
	|where Document.Ref = &Ref
	|;
	|// #Employees
	|select Employees.Employee as Employee, presentation ( Employees.Employee ) as Name,
	|	Employees.Email as Email
	|from Document.SendingPayslips.Employees as Employees
	|where Employees.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure initComposer ( Env )
	
	schema = Reporter.GetSchema ( "Payslips" );
	composer = new DataCompositionSettingsComposer ();
	composer.Initialize ( new DataCompositionAvailableSettingsSource ( schema ) );
	composer.LoadSettings ( schema.DefaultSettings );
	month = Env.Fields.Month;
	DC.SetParameter ( composer, "Period", new StandardPeriod ( BegOfMonth ( month ), EndOfMonth ( month ) ) );
	Env.Insert ( "Composer", composer );

EndProcedure

Procedure initFolder ( Env )
	
	folder = GetTempFileName ();
	CreateDirectory ( folder );
	Env.Insert ( "Folder", folder );
	Env.Insert ( "File", folder + GetPathSeparator ()
		+ "payslip-" + Format ( Env.Fields.Month, "DF=MM-yyyy" ) + ".pdf" );
	
EndProcedure

Function getMessage ( Row, Env )
	
	composer = Env.Composer;
	DC.SetParameter ( composer, "Employee", Row.Employee );
	report = Reporter.Make ( "Payslips", "#Default", composer.UserSettings );
	report.Params.Result.Write ( Env.File, SpreadsheetDocumentFileType.PDF );
	p = new Structure ( "Employee, Month", Row.Name, Env.Month );
	message = new InternetMailMessage ();
	message.From = Cloud.Noreply ();
	message.Subject = Output.PayslipSubject ( Env );
	message.To.Add ( Row.Email );
	message.Texts.Add ( Output.PayslipBody ( p ) );
	message.Attachments.Add ( Env.File  );
	return message;
		
EndFunction

Procedure releaseFile ( Message )
	
	Message = undefined;

EndProcedure

Procedure Write ( Object ) export
	
	SetPrivilegedMode ( true );
	p = new Array ();
	p.Add ( Object.Ref );
	job = ScheduledJobs.CreateScheduledJob ( Metadata.ScheduledJobs.TimeReminder );
	job.UserName = DF.Pick ( Object.Ref, "Creator.Description" );
	job.Parameters = p;
	job.Key = Object.Ref.UUID ();
	sessionDate = CurrentSessionDate ();
	timeOffset = sessionDate - CurrentDate ();
	job.Schedule.BeginDate = Object.ReminderDate - timeOffset;
	job.Schedule.BeginTime = Object.ReminderDate - timeOffset;
	job.Write ();
	
EndProcedure 
