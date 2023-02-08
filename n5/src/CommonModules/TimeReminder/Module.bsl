Procedure Send ( TimeEntry ) export
	
	SetPrivilegedMode ( true );
	env = new Structure ();
	env.Insert ( "TimeEntry", TimeEntry );
	getData ( env );
	profile = MailboxesSrv.SystemProfile ();
	message = new InternetMailMessage ();
	setSenderAndReceiver ( env, message );
	setSubject ( env, message );
	setBody ( env, message );
	try
		MailboxesSrv.Post ( profile, message );
	except
		WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, Metadata.ScheduledJobs.TimeReminder, , ErrorDescription () );
		return;
	endtry;
	Jobs.Remove ( TimeEntry );
	
EndProcedure 

Procedure getData ( Env )
	
	SQL.Init ( Env );
	sqlFields ( Env );
	Env.Q.SetParameter ( "Ref", Env.TimeEntry );
	SQL.Perform ( Env );

EndProcedure 

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select top 1 Document.Customer.Description as Customer, Document.Project.Description as Project,
	|	Document.Employee.Description as Employee, Document.Creator.Email as CreatorEmail,
	|	case when Document.Creator <> Users.Ref then isnull ( Users.Email, """" ) else Document.Creator.Email end as EmployeeEmail,
	|	presentation ( Document.Ref ) as TimeEntryPresentation
	|from Document.TimeEntry as Document
	|	left join Catalog.Users as Users
	|	on Users.Employee = Document.Employee
	|	and not Users.DeletionMark
	|where Document.Ref = &Ref
	|;
	|// #Tasks
	|select Tasks.LineNumber as LineNumber, Tasks.TimeStart as TimeStart, Tasks.TimeEnd as TimeEnd, Tasks.Duration as Duration, Tasks.Description as Description,
	|	Tasks.Task.Description as TaskDescription
	|from Document.TimeEntry.Tasks as Tasks
	|where Tasks.Ref = &Ref
	|order by Tasks.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure setSenderAndReceiver ( Env, Message )
	
	Message.From = Cloud.Noreply ();
	Message.To.Add ( Env.Fields.CreatorEmail );
	if ( Env.Fields.EmployeeEmail <> ""
		and Env.Fields.EmployeeEmail <> Env.Fields.CreatorEmail ) then
		Message.Cc.Add ( Env.Fields.EmployeeEmail );
	endif; 
	
EndProcedure

Procedure setSubject ( Env, Message )
	
	description = "";
	if ( Env.Tasks.Count () > 0 ) then
		description = Env.Tasks [ 0 ].Description;
	endif; 
	if ( IsBlankString ( description ) ) then
		description = Env.Fields.Customer + ", " + Env.Fields.Project;
	endif; 
	Message.Subject = Output.ReminderSubject ( new Structure ( "ReminderDescription", description ) );
	
EndProcedure 

Procedure setBody ( Env, Message )
	
	rowParams = new Structure ( "LineNumber, TimeStart, TimeEnd, Duration, Description, TaskDescription" );
	s = "";
	for each row in Env.Tasks do
		FillPropertyValues ( rowParams, row, "LineNumber, Description, TaskDescription" );
		rowParams.TimeStart = Format ( row.TimeStart, "DF=HH:mm" );
		rowParams.TimeEnd = Format ( row.TimeEnd, "DF=HH:mm" );
		rowParams.Duration = Format ( row.Duration, "NFD=2; NDS=:" );
		s = s + Output.TimeEntryRow ( rowParams ) + Chars.LF;
	enddo; 
	bodyParams = new Structure ();
	bodyParams.Insert ( "TimeEntry", Env.Fields.TimeEntryPresentation );
	bodyParams.Insert ( "Employee", Env.Fields.Employee );
	bodyParams.Insert ( "Customer", Env.Fields.Customer );
	bodyParams.Insert ( "Project", Env.Fields.Project );
	bodyParams.Insert ( "Tasks", s );
	bodyParams.Insert ( "URL", Conversion.ObjectToURL ( Env.TimeEntry ) );
	Message.Texts.Add ( Output.ReminderBody ( bodyParams ) );
	
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
