Procedure SendEmail ( Ref ) export
	
	SetPrivilegedMode ( true );
	env = new Structure ();
	env.Insert ( "Ref", Ref );
	env.Insert ( "Event", isEvent ( Ref ) );
	getData ( env );
	profile = MailboxesSrv.SystemProfile ();
	message = new InternetMailMessage ();
	setSenderAndReceiver ( env, message );
	if ( env.Event ) then
		fillEvent ( env, message );
	else
		fillTask ( env, message );
	endif;
	try
		MailboxesSrv.Post ( profile, message );
	except
		WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, Metadata.ScheduledJobs.TasksReminder, , ErrorDescription () );
		return;
	endtry;
	Jobs.Remove ( Ref );
	
EndProcedure

Function isEvent ( Ref )
	
	return TypeOf ( ref ) = Type ( "DocumentRef.Event" );
	
EndFunction

Procedure getData ( Env )
	
	SQL.Init ( Env );
	sqlFields ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );

EndProcedure 

Procedure sqlFields ( Env )
	
	if ( Env.Event ) then
		s = "
		|// @Fields
		|select Events.Subject as Subject, Events.Responsible.Email as Email, Events.Severity as Severity,
		|	Events.Start as Start, Events.Finish as Finish, Events.Duration as Duration, Events.Content as Content,
		|	Events.Organization.Description as Organization, Events.Contract.Description as Contact,
		|	Events.Responsible as Responsible
		|from Document.Event as Events
		|where Events.Ref = &Ref
		|";
	else
		s = "
		|// @Fields
		|select Tasks.Memo as Memo, Tasks.Performer.Email as Email, presentation ( Tasks.Ref ) as TaskPresentation,
		|	Tasks.Start as Start, Tasks.Finish as Finish, Tasks.Duration as Duration
		|from Task.UserTask as Tasks
		|where Tasks.Ref = &Ref
		|";
	endif;
	Env.Selection.Add ( s );

EndProcedure

Procedure setSenderAndReceiver ( Env, Message )
	
	Message.From = Cloud.Noreply ();
	Message.To.Add ( Env.Fields.Email );
	
EndProcedure

Procedure fillEvent ( Env, Message )
	
	p = new Structure ( "Subject, FullSubject, Severity, Starting, Start, StartTime, Finish, Duration, Content,
	|Organization, Contact, Responsible" );
	fields = Env.Fields;
	p.Severity = fields.Severity;
	p.Organization = fields.Organization;
	p.Content = fields.Content;
	p.Duration = Format ( fields.Duration, "NFD=2; NDS=:" );
	p.Insert ( "URL", Conversion.ObjectToURL ( Env.Ref ) );
	subject = TrimAll ( fields.Subject );
	p.FullSubject = subject;
	p.Subject = subject + ? ( StrLen ( subject ) > 100, "...", "" ); 
	start = fields.Start;
	startDate = Format ( start, "DLF=D" );
	dayStart = BegOfDay ( start );
	today = BegOfDay ( PeriodsSrv.CurrentUserDate ( fields.Responsible ) );
	if ( dayStart = today ) then
		shortStart = Output.Today ();
	elsif ( dayStart = ( today + 86400 ) ) then
		shortStart = Output.Tomorrow ();
	else
		shortStart = startDate;
	endif;
	p.Starting = shortStart;
	p.Start = startDate;
	p.StartTime = Format ( start, "DF='HH:mm'" );
	finish = fields.Finish;
	finishTime = Format ( finish, "DF='HH:mm'" );
	if ( BegOfDay ( finish ) = dayStart ) then
		p.Finish = finishTime;
	else
		p.Finish = Format ( finish, "DLF=D" ) + " " + finishTime;
	endif;
	Message.Subject = Output.EventSubject ( p );
	Message.Texts.Add ( Output.EventBody ( p ) );
	
EndProcedure

Procedure fillTask ( Env, Message )
	
	p = new Structure ( "Description, Memo, Start, StartTime, Finish, Duration, Task, URL" );
	fields = Env.Fields;
	memo = TrimAll ( fields.Memo );
	description = Left ( clean ( memo ), 100 );
	addDots = StrLen ( description ) <> StrLen ( memo );
	if ( addDots ) then
		description = description + "...";
	endif; 
	p.Description = description;
	p.Memo = memo;
	start = fields.Start;
	p.Start = Format ( start, "DLF=D" );
	p.StartTime = Format ( start, "DF='HH:mm'" );
	p.Finish = Format ( fields.Finish, "DF='HH:mm'" );
	p.Duration = Format ( fields.Duration, "NFD=2; NDS=:" );
	p.Task = fields.TaskPresentation;
	p.URL = Conversion.ObjectToURL ( Env.Ref );
	Message.Subject = Output.TaskSubject ( p );
	Message.Texts.Add ( Output.TaskBody ( p ) );
	
EndProcedure 

Function clean ( Text )
	
	s = StrReplace ( Text, Chars.LF, " " );
	s = StrReplace ( s, Chars.CR, " " );
	s = StrReplace ( s, Chars.FF, " " );
	s = StrReplace ( s, Chars.NBSp, " " );
	s = StrReplace ( s, Chars.Tab, " " );
	s = StrReplace ( s, Chars.VTab, " " );
	return s;
	
EndFunction 

Procedure Write ( Object ) export
	
	SetPrivilegedMode ( true );
	p = new Array ();
	ref = Object.Ref;
	p.Add ( ref );
	job = ScheduledJobs.CreateScheduledJob ( Metadata.ScheduledJobs.TasksReminder );
	if ( isEvent ( ref ) ) then
		userName = DF.Pick ( ref, "Responsible.Description" );
	else
		userName = DF.Pick ( ref, "Performer.Description" );
	endif;
	job.UserName = userName;
	job.Parameters = p;
	job.Key = Object.Ref.UUID ();
	sessionDate = CurrentSessionDate ();
	timeOffset = sessionDate - CurrentDate ();
	date = Object.ReminderDate - timeOffset;
	job.Schedule.BeginDate = date;
	job.Schedule.BeginTime = date;
	job.Write ();
	
EndProcedure 
