Procedure Post ( Ref ) export
	
	env = Posting.GetParams ( Ref );
	BeginTransaction ();
	getData ( env );
	makeInvitations ( env );
	CommitTransaction ();
	sendInvitations ( env );
	
EndProcedure

Procedure getData ( Env )

	sqlFields ( Env );
	sqlMembers ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Room.Description as Room, Documents.Room.Address as Address, Documents.Creator as Creator,
	|	Documents.Changed as Changed, Documents.Changes as Changes, Documents.Start as Start,
	|	Documents.Finish as Finish, Documents.Subject as Subject, Documents.Duration as Duration,
	|	Documents.Canceled as Canceled, Documents.Reason as Reason
	|from Document.Meeting as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlMembers ( Env )
	
	s = "
	|// #Members
	|// New and Old
	|select Members.Member as Member, Members.Member.FullName as MemberName, Members.Member.Email as Email,
	|	Members.Send and Settings.MeetingNotifications as Send, Members.Organizer as Organizer,
	|	case when Members.Ref.Canceled then 3
	|		when Invitations.Member is null then 1
	|		else 2
	|	end as Status // 1 - New, 2 - Old, 3 - Canceled
	|from Document.Meeting.Members as Members
	|	//
	|	// Invitations
	|	//
	|	left join InformationRegister.Invitations as Invitations
	|	on Invitations.Member = Members.Member
	|	and Invitations.Meeting = Members.Ref
	|	//
	|	// Settings
	|	//
	|	left join Catalog.UserSettings as Settings
	|	on Settings.Owner = Members.Member
	|where Members.Ref = &Ref
	|union all
	|// Cancelled
	|select Invitations.Member, Invitations.Member.FullName, Invitations.Member.Email, Settings.MeetingNotifications,
	|	false, 3 // 3 - Cancelled, false
	|from InformationRegister.Invitations as Invitations
	|	//
	|	// Members
	|	//
	|	left join Document.Meeting.Members as Members
	|	on Members.Member = Invitations.Member
	|	and Members.Ref = Invitations.Meeting
	|	//
	|	// Settings
	|	//
	|	left join Catalog.UserSettings as Settings
	|	on Settings.Owner = Invitations.Member
	|where Invitations.Meeting = &Ref
	|and Members.Ref is null
	|order by Organizer desc, MemberName
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure makeInvitations ( Env )
	
	ref = Env.Ref;
	fields = Env.Fields;
	creator = fields.Creator;
	changed = fields.Changed;
	newMember = 1;
	cancelledMember = 3;
	for each row in Env.Members do
		status = row.Status;
		if ( status = cancelledMember ) then
			r = InformationRegisters.Invitations.CreateRecordManager ();
			r.Member = row.Member;
			r.Meeting = ref;
			r.Delete ();
		else
			if ( changed
				or status = newMember ) then
				r = InformationRegisters.Invitations.CreateRecordManager ();
				member = row.Member;
				r.Member = member;
				if ( member = creator ) then
					r.Answer = Enums.InvitationAnswers.Yes;
				endif;
				r.Meeting = ref;
				r.Write ();
			endif;
		endif;
	enddo;
	
EndProcedure 

Procedure sendInvitations ( Env )
	
	fields = Env.Fields;
	creator = fields.Creator;
	oldMember = 2;
	unchanged = ( fields.Changed = 0 );
	messages = new Map ();
	profile = MailboxesSrv.SystemProfile ();
	for each row in Env.Members do
		if ( not row.Send
			or row.Member = creator ) then
			continue;
		endif;
		status = row.Status;
		if ( status = oldMember
			and unchanged ) then
			continue;
		endif;
		if ( messages [ status ] = undefined ) then
			content = messageContent ( row, Env );
			messages [ status ] = content;
		else
			content = messages [ status ];
		endif;
		message = createMessage ( content, row, Env );
		try
			MailboxesSrv.Post ( profile, message );
		except
			WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, Metadata.Documents.Meeting, Env.Ref, ErrorDescription () );
		endtry
	enddo;
	
EndProcedure 

Function messageContent ( Row, Env )
	
	fields = Env.Fields;
	p = new Structure ();
	start = fields.Start;
	timeFormat = Output.TimeFormat ();
	p.Insert ( "StartTime", Format ( start, timeFormat ) );
	p.Insert ( "StartDate", Format ( start, "DLF=DD" ) );
	finish = fields.finish;
	p.Insert ( "FinishTime", Format ( finish, timeFormat ) );
	p.Insert ( "FinishDate", Format ( finish, "DLF=DD" ) );
	p.Insert ( "Duration", fields.Duration );
	p.Insert ( "Room", fields.Room );
	p.Insert ( "Subject", fields.Subject );
	p.Insert ( "Members", getMembers ( Env ) );
	p.Insert ( "Address", fields.Address );
	p.Insert ( "Changes", fields.Changes );
	p.Insert ( "TimeChanged", "" );
	p.Insert ( "SubjectChanged", "" );
	p.Insert ( "RoomChanged", "" );
	changed = fields.Changed;
	subject = new Array ();
	body = new Array ();
	oldMember = 2;
	cancelledMember = 3;
	status = Row.Status;
	if ( status = cancelledMember ) then
		subject.Add ( Output.MeetingCanceled () + ": " );
		body.Add ( "<p>" + Output.MeetingCanceledBody () );
		if ( fields.Canceled ) then
			p.Insert ( "Reason", fields.Reason );
			body.Add ( "<br/>" + Output.MeetingCanceledReason ( p ) );
		endif;
		body.Add ( "</p>" );
	elsif ( status = oldMember ) then
		// Changed = 1000 | 0100 | 0010 | 0001, where:
		// 1000: start date changed
		// 0100: finish date changed
		// 0010: subject changed
		// 0001: room changed
		// See form module of document Meeting for details
		subject.Add ( Output.MeetingUpdated () + ": " );
		meetingChanged = Output.MeetingChanged ();
		p.Insert ( "TimeChanged", ? ( CheckBit ( changed, 0 ) or CheckBit ( changed, 1 ), meetingChanged, "" ) );
		p.Insert ( "SubjectChanged", ? ( CheckBit ( changed, 2 ), meetingChanged, "" ) );
		p.Insert ( "RoomChanged", ? ( CheckBit ( changed, 3 ), meetingChanged, "" ) );
		if ( p.Changes <> "" ) then
			body.Add ( "<p>" + Output.MeetingMessage ( p ) + "</p>" );
		endif;
	endif;
	subject.Add ( Output.MeetingSubject ( p ) );
	body.Add ( "<p>" + Output.MeetingBodyWhat ( p ) );
	body.Add ( "<br/>" + Output.MeetingBodyWhen ( p ) );
	body.Add ( "<br/>" + Output.MeetingBodyWhere ( p ) );
	if ( p.Address <> "" ) then
		body.Add ( "<br/>" + Output.MeetingBodyAddress ( p ) );
	endif;
	if ( status <> cancelledMember ) then
		body.Add ( "<br/>" + Output.MeetingBodyWho ( p ) );
	endif;
	body.Add ( "</p>" );
	actionsRequired = false;
	if ( Cloud.Cloud () ) then
		if ( status <> cancelledMember ) then
			actionsRequired = true;
			body.Add ( Output.MeetingBodyActions () );
			p.Insert ( "Invitation", Conversion.ObjectToURL ( Env.Ref ) );
			body.Add ( "<p>" + Output.MeetingBodyInvitation ( p ) + "</p>" );
		endif;
		body.Add ( aboutNotifications () );
	endif;
	return new Structure ( "Subject, Body, ActionsRequired", StrConcat ( subject ), StrConcat ( body ), actionsRequired );
	
EndFunction 

Function getMembers ( Env )
	
	list = new Array ();
	canceled = 3;
	organizer = " " + Output.MeetingOrganizer ();
	for each row in Env.Members do
		if ( row.Status = canceled ) then
			continue;
		endif;
		list.Add ( Output.MailTo ( new Structure ( "Name, Email", row.MemberName + ? ( row.Organizer, organizer, "" ), row.Email ) ) );
	enddo;
	return StrConcat ( list, ", " );
	
EndFunction

Function aboutNotifications ()
	
	return "<p>" + Output.NotificationsPage ( new Structure ( "MySettings", Conversion.ObjectToURL ( Logins.Settings ( "Ref" ).Ref ) ) ) + "</p>";
	
EndFunction

Function createMessage ( Content, Row, Env )
	
	message = new InternetMailMessage ();
	message.From = Cloud.Noreply ();
	address = message.To.Add ( Row.Email );
	address.DisplayName = Row.MemberName;
	message.Subject = Content.Subject;
	if ( Content.ActionsRequired ) then
		p = new Structure ();
		service = Cloud.RemoteActionsService () + "/hs/RemoteActions?ID=";
		p.Insert ( "Yes", service + actionID ( Enums.RemoteActions.MeetingYes, Row, Env ) );
		p.Insert ( "No", service + actionID ( Enums.RemoteActions.MeetingNo, Row, Env ) );
		p.Insert ( "Maybe", service + actionID ( Enums.RemoteActions.MeetingMaybe, Row, Env ) );
		body = Output.FormatStr ( Content.Body, p );
	else
		body = Content.Body;
	endif;
	message.Texts.Add ( body, InternetMailTextType.HTML );
	return message;
	
EndFunction

Function actionID ( Action, Row, Env )
	
	r = InformationRegisters.RemoteActions.CreateRecordManager ();
	id = new UUID ();
	r.ID = id;
	r.Action = Action;
	r.Expire = Env.Fields.Start;
	r.Parameter1 = Env.Ref;
	r.Parameter2 = Row.Member;
	r.Write ();
	return id;
	
EndFunction

Function AnswerParams () export
	
	p = new Structure ();
	p.Insert ( "Member" );
	p.Insert ( "Answer" );
	p.Insert ( "Comment", "" );
	p.Insert ( "Meeting" );
	return p;
	
EndFunction

Procedure ApplyAnswer ( Params ) export
	
	closeInvitation ( Params );
	notifyCreator ( Params );
	
EndProcedure

Procedure closeInvitation ( Params )
	
	r = InformationRegisters.Invitations.CreateRecordManager ();
	r.Member = Params.Member;
	r.Meeting = Params.Meeting;
	r.Answer = Params.Answer;
	r.Comment = Params.Comment;
	r.Write ();
	
EndProcedure

Procedure notifyCreator ( Params )
	
	meeting = Params.Meeting;
	data = creatorData ( meeting );
	if ( not data.Send ) then
		return;
	endif;
	profile = MailboxesSrv.SystemProfile ();
	message = notificationMessage ( Params, data );
	try
		MailboxesSrv.Post ( profile, message );
	except
		WriteLogEvent ( "MailboxesSrv.Post", EventLogLevel.Error, Metadata.Documents.Meeting, meeting, ErrorDescription () );
	endtry

EndProcedure

Function creatorData ( Meeting )
	
	s = "
	|// @Fields
	|select Meetings.Subject as Subject, Meetings.Creator.FullName as Creator,
	|	Meetings.Creator.Email as Email, Meetings.Room.Description as Room,
	|	Meetings.Start as Start, Meetings.Notify and Settings.MeetingNotifications as Send
	|from Document.Meeting as Meetings
	|	//
	|	// Settings
	|	//
	|	left join Catalog.UserSettings as Settings
	|	on Settings.Owner = Meetings.Creator
	|where Meetings.Ref = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Meeting );
	return SQL.Exec ( q ).Fields;
	
EndFunction

Function notificationMessage ( Params, Data )
	
	message = new InternetMailMessage ();
	message.From = Cloud.Noreply ();
	subject = new Array ();
	member = String ( Params.Member );
	subject.Add ( member );
	answer = Params.Answer;
	if ( answer = Enums.InvitationAnswers.Maybe ) then
		subject.Add ( Output.MeetingNotificationAnswerMaybe () );
	elsif ( answer = Enums.InvitationAnswers.No ) then
		subject.Add ( Output.MeetingNotificationAnswerNo () );
	else
		subject.Add ( Output.MeetingNotificationAnswerYes () );
	endif;
	p = new Structure ();
	start = data.Start;
	timeFormat = Output.TimeFormat ();
	p.Insert ( "StartTime", Format ( start, timeFormat ) );
	p.Insert ( "StartDate", Format ( start, "DLF=DD" ) );
	p.Insert ( "Room", data.Room );
	p.Insert ( "Member", member );
	p.Insert ( "Subject", data.Subject );
	p.Insert ( "Answer", answer );
	p.Insert ( "Comment", Params.Comment );
	p.Insert ( "MemberMailTo", Output.MailTo ( new Structure ( "Name, Email", member, data.Email ) ) );
	subject.Add ( Output.MeetingNotificationSubject ( p ) );
	message.Subject = StrConcat ( subject, " " );
	body = new Array ();
	body.Add ( "<p>" + Output.MeetingNotificationBody ( p ) );
	if ( p.Comment <> "" ) then
		body.Add ( "<br/>" + Output.MeetingNotificationBodyComment ( p ) );
	endif;
	body.Add ( "</p>" );
	if ( Cloud.Cloud () ) then
		body.Add ( aboutNotifications () );
	endif;
	message.Texts.Add ( StrConcat ( body ), InternetMailTextType.HTML );
	address = message.To.Add ( data.Email );
	address.DisplayName = data.Creator;
	return message;
	
EndFunction
