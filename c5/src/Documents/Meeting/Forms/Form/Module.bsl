&AtClient
var OldDate;
&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	copyValues ();
	setCapacity ();
	calcTotals ( ThisObject );
	readStatistics ();
	if ( Object.Formed ) then
		if ( inProgress () ) then
			lock ();
		else
			loadAnswers ();
			activateYourAnswer ();
			arrangeControls ();
		endif;
	endif;
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure copyValues ()
	
	OldFinish = Object.Finish;
	OldRoom = Object.Room;
	OldStart = Object.Start;
	OldSubject = Object.Subject;
	
EndProcedure

&AtServer
Procedure setCapacity ()
	
	RoomCapacity = DF.Pick ( Object.Room, "Capacity" );
	
EndProcedure

&AtClientAtServerNoContext
Procedure calcTotals ( Form )
	
	Form.MembersTotal = Form.Object.Members.Count ();
	
EndProcedure

&AtServer
Procedure readStatistics ()
	
	if ( not Object.Formed ) then
		return;
	endif;
	data = getStatistics ();
	if ( data = undefined ) then
		return;
	endif;
	SaidMaybe = data.Maybe;
	SaidYes = data.Yes;
	SaidNo = data.No;
	SaidNothing = data.Nothing;
	parts = new Array ();
	parts.Add ( new FormattedString ( Output.MeetingSaidYes () + ": " + Format ( SaidYes, "NZ=0" ), , new Color ( 0, 128, 0 ) ) );
	parts.Add ( new FormattedString ( ", " + Output.MeetingSaidNo () + ": " + Format ( SaidNo, "NZ=0" ), , new Color ( 128, 0, 0 ) ) );
	parts.Add ( new FormattedString ( ", " + Output.MeetingSaidMaybe () + ": " + Format ( SaidMaybe, "NZ=0" ), , new Color ( 0, 0, 128 ) ) );
	parts.Add ( new FormattedString ( ", " + Output.MeetingSaidNothing () + ": " + Format ( SaidNothing, "NZ=0" ) ) );
	Statistics = new FormattedString ( parts );
	
EndProcedure

&AtServer
Function getStatistics ()
	
	s = "
	|select sum ( case when Invitations.Answer = value ( Enum.InvitationAnswers.Yes ) then 1 else 0 end ) as Yes,
	|	sum ( case when Invitations.Answer = value ( Enum.InvitationAnswers.No ) then 1 else 0 end ) as No,
	|	sum ( case when Invitations.Answer = value ( Enum.InvitationAnswers.Maybe ) then 1 else 0 end ) as Maybe,
	|	sum ( case when Invitations.Answer = value ( Enum.InvitationAnswers.EmptyRef ) then 1 else 0 end ) as Nothing
	|from Document.Meeting.Members as Members
	|	//
	|	// Invitations
	|	//
	|	join InformationRegister.Invitations as Invitations
	|	on Invitations.Member = Members.Member
	|	and Invitations.Meeting = Members.Ref
	|where Members.Ref = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction

&AtClientAtServerNoContext
Function meetingStarted ( Form )
	
	yes = Form.Object.Start < PeriodsSrv.GetCurrentSessionDate ();
	Form.MeetingStarted = yes;
	return yes;

EndFunction

&AtServer
Function inProgress ()
	
	job = Jobs.GetBackground ( Object.Ref );
	return job <> undefined;
	
EndFunction

&AtServer
Procedure lock ()
	
	ReadOnly = true;
	Posting = true;
	
EndProcedure

&AtServer
Procedure loadAnswers ()
	
	search = new Structure ( "Member" );
	members = Object.Members;
	for each row in getAnswers () do
		search.Member = row.Member;
		for each member in members.FindRows ( search ) do
			FillPropertyValues ( member, row );
		enddo;
	enddo;
	
EndProcedure

&AtServer
Function getAnswers ()
	
	s = "
	|select Members.Member as Member, Invitations.Answer as Answer, Invitations.Comment as Comment
	|from Document.Meeting.Members as Members
	|	//
	|	// Invitations
	|	//
	|	join InformationRegister.Invitations as Invitations
	|	on Invitations.Member = Members.Member
	|	and Invitations.Meeting = Members.Ref
	|where Members.Ref = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	return q.Execute ().Unload ();
	
EndFunction

&AtServer
Procedure activateYourAnswer ()
	
	CurrentUser = SessionParameters.User;
	if ( CurrentUser = Object.Creator ) then
		return;
	endif;
	data = invitationData ();
	if ( data = undefined ) then
		return;
	endif;
	YouInvited = true;
	YourAnswer = data.Answer;
	if ( YourAnswer = Enums.InvitationAnswers.EmptyRef () ) then
		YourAnswer = Enums.InvitationAnswers.Yes;
	endif;
	YourComment = data.Comment;
	
EndProcedure

&AtServer
Function invitationData ()
	
	data = Object.Members.FindRows ( new Structure ( "Member", CurrentUser ) );
	return ? ( data.Count () = 0, undefined, data [ 0 ] );
	
EndFunction

&AtServer
Procedure arrangeControls ()
	
	if ( not YouInvited ) then
		return;
	endif;
	Items.Confirm.DefaultButton = true;
	ReadOnly = true;
	CurrentItem = Items.YourAnswer;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		Constraints.ShowAccess ( ThisObject );
	else
		applyParams ();
	endif; 
	Options.Company ( ThisObject, Object.Company );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	// Bug workaround 8.3.13.1513: splitted functional options do not work properly.
	// Manual visibility control is required
	if ( Environment.MobileClient () ) then
		Items.GroupInfo.Visible = false;
	else
		Items.Statistics.Visible = false;
	endif;
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormWrite show not Object.Formed and not Object.Canceled and not Object.Completed;
	|Changes show filled ( Object.Changes );
	|GroupInfo show Object.Formed;
	|Completed show Object.Completed;
	|PageAnswer show YouInvited and not Object.Canceled and not Object.Completed;
	|FormOK show not YouInvited and not Object.Canceled and not Object.Completed;
	|Posting show Posting;
	|CapacityWarning show RoomCapacity > 0 and RoomCapacity < MembersTotal;
	|FormCancel show Object.Formed and not Object.Canceled and not Object.Completed;
	|FormComplete show Object.Formed and not Object.Canceled and not Object.Completed and MeetingStarted;
	|GroupCanceled show Object.Canceled;
	|Color Company Finish Memo Notify Room Start Subject Number Members lock Object.Canceled;
	|PickTime PickTimeMobile show not Object.Canceled;
	|MembersAnswer MembersComment show Object.Formed
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Parameters.CopyingValue.IsEmpty () ) then
		settings = Logins.Settings ( "Company" );
		Object.Company = settings.Company;
		if ( Object.Room.IsEmpty () ) then
			Object.Room = defaultRoom ();
		endif;
		applyRoom ();
		inviteMyself ();
		loadMembers ();
	else
		Object.Start = Parameters.NewStart;
		Object.Finish = Parameters.NewFinish;
		newRoom = Parameters.NewRoom;
		if ( not newRoom.IsEmpty () ) then
			Object.Room = newRoom;
			setCapacity ();
		endif;
		Object.Formed = false;
		Object.Completed = false;
		Object.Changed = 0;
		Object.Changes = "";
		Object.Canceled = false;
		Object.Reason = "";
	endif; 
	TaskForm.InitStart ( Object );
	TaskForm.AdjustFinish ( Object );
	TaskForm.CalcDuration ( Object );
	
EndProcedure 

&AtServer
Procedure applyRoom ()
	
	room = Object.Room;
	if ( room.IsEmpty () ) then
		Object.Color = undefined;
		RoomCapacity = 0;
	else
		data = DF.Values ( room, "Color, Capacity" );
		Object.Color = data.Color;
		RoomCapacity = data.Capacity;
	endif;
	
EndProcedure

&AtServer
Procedure inviteMyself ()
	
	row = Object.Members.Add ();
	row.Member = Object.Creator;
	row.Organizer = true;
	initRow ( row, Object, false );
		
EndProcedure

&AtClientAtServerNoContext
Procedure initRow ( Row, Object, Clone )
	
	if ( Clone ) then
		Row.Answer = undefined;
		Row.Comment = "";
	else
		Row.Send = Row.Member <> Object.Creator;
	endif;
	
EndProcedure

&AtServer
Procedure loadMembers ()
	
	members = Parameters.Members;
	if ( members = undefined ) then
		return;
	endif;
	creator = Object.Creator;
	for each member in members do
		if ( member = creator ) then
			continue;
		endif;
		row = Object.Members.Add ();
		row.Member = member;
		initRow ( row, Object, false );
	enddo;
	
EndProcedure

&AtServer
Function defaultRoom ()
	
	s = "
	|select top 2 Rooms.Ref as Ref
	|from Catalog.Rooms as Rooms
	|where not Rooms.DeletionMark
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 1, table [ 0 ].Ref, undefined );

EndFunction

&AtServer
Procedure applyParams ()
	
	newStart = Parameters.NewStart;
	if ( newStart = Date ( 1, 1, 1 ) ) then
		return;
	endif;
	Modified = true;
	Object.Start = newStart;
	Object.Finish = Parameters.NewFinish;
	newRoom = Parameters.NewRoom;
	if ( not newRoom.IsEmpty ()
		and newRoom <> Object.Room ) then
		Object.Room = newRoom;
		setCapacity ();
	endif;
	TaskForm.AdjustFinish ( Object );
	TaskForm.CalcDuration ( Object );
	meetingStarted ( ThisObject );
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	saveCalendarInfo ();

EndProcedure

&AtClient
Procedure saveCalendarInfo ()
	
	OldDate = Object.Start;
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	if ( DataChecked
		or not Object.Formed ) then
		return;
	endif;
	Cancel = true;
	AttachIdleHandler ( "checkData", 0.1, true );
	
EndProcedure

&AtClient
Procedure checkData ()
	
	if ( not CheckFilling () ) then
		return;
	endif;
	DataChecked = true;
	if ( changed () ) then
		OpenForm ( "Document.Meeting.Form.Changes", , ThisObject, , , , new NotifyDescription ( "MeetingChanges", ThisObject ) );
	else
		writeAndClose ();
	endif;
	
EndProcedure

&AtClient
Function changed ()
	
	if ( Object.Completed
		or not Object.Formed
		or Object.Ref.IsEmpty () ) then
		Object.Changed = 0;
	else
		Object.Changed =
		  1 * ( OldStart <> Object.Start )
		+ 2 * ( OldFinish <> Object.Finish )
		+ 4 * ( OldSubject <> Object.Subject )
		+ 8 * ( OldRoom <> Object.Room );
	endif;
	return Object.Changed <> 0;
	
EndFunction

&AtClient
Procedure writeAndClose ()
	
	if ( Write () ) then
		if ( Object.Formed
			or Object.Canceled ) then
			Close ();
		endif;
	endif;
	
EndProcedure

&AtClient
Procedure MeetingChanges ( Comment, Params ) export
	
	copyValues ();
	Object.Changes = Comment;
	writeAndClose ();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	preventDoubleChecking ( CheckedAttributes );
	
EndProcedure

&AtServer
Procedure preventDoubleChecking ( CheckedAttributes )
	
	if ( DataChecked
		or Object.Canceled
		or Object.Completed ) then
		CheckedAttributes.Clear ();
	endif;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( Object.Formed
		or Object.Canceled ) then
		post ( CurrentObject );
	endif;
	
EndProcedure

&AtServer
Procedure post ( CurrentObject )
	
	ref = CurrentObject.Ref;
	if ( TesterCache.Testing () ) then
		RunMeetings.Post ( ref );
	else
		params = new Array ();
		params.Add ( ref );
		BackgroundJobs.Execute ( "RunMeetings.Post", params, CurrentObject.Ref );
	endif;
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	notifySystem ();
	
EndProcedure

&AtClient
Procedure notifySystem ()
	
	p = new Structure ( "OldDate, NewDate", OldDate, Object.Start );
	Notify ( Enum.MessageMeetingIsSaved (), p, Object.Ref );
	saveCalendarInfo ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure OK ( Command )
	
	formMeeting ();
	
EndProcedure

&AtClient
Procedure formMeeting ()
	
	Object.Formed = true;
	Write ();
	
EndProcedure

&AtClient
Procedure RoomOnChange ( Item )
	
	applyRoom ();
	showWarning ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure showWarning ( Form )
	
	Appearance.Apply ( Form, "RoomCapacity" );
	
EndProcedure

&AtClient
Procedure PeriodStartChoice ( Item, ChoiceData, StandardProcessing )
	
	#if ( MobileClient ) then
		return;
	#endif
	StandardProcessing = false;
	DatePicker.SelectPeriod ( Item, Object.Start, Object.Finish, , Item = Items.Finish );
	
EndProcedure

&AtClient
Procedure PeriodOnChange ( Item )
	
	TaskForm.AdjustFinish ( Object );
	TaskForm.CalcDuration ( Object );
	
EndProcedure

&AtClient
Procedure PeriodChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	#if ( MobileClient ) then
		return;
	#endif
	StandardProcessing = false;
	Modified = true;
	applyPeriod ( SelectedValue );
	
EndProcedure

&AtClient
Procedure applyPeriod ( Period )
	
	Object.Start = Period.Start;
	Object.Finish = Period.Finish;
	TaskForm.AdjustFinish ( Object );
	TaskForm.CalcDuration ( Object );
	meetingStarted ( ThisObject );
	Appearance.Apply ( ThisObject, "MeetingStarted" );

EndProcedure

&AtClient
Procedure PickTime ( Command )
	
	selectTime ();
	
EndProcedure

&AtClient
Procedure selectTime ()
	
	p = new Structure ( "SelectionMode, SelectionDate, Filter, Source", true, Object.Start, Object.Room, Object.Ref );
	callback = new NotifyDescription ( "TimePicked", ThisObject );
	OpenForm ( "DataProcessor.Calendar.Form", p, ThisObject, , , , callback, FormWindowOpeningMode.LockWholeInterface );
	
EndProcedure

&AtClient
Procedure TimePicked ( Time, Params ) export
	
	if ( Time = undefined ) then
		return;
	endif;
	Object.Start = Time.Begin;
	Object.Finish = Time.End;
	TaskForm.CalcDuration ( Object );
	
EndProcedure

&AtClient
Procedure Confirm ( Command )
	
	if ( applyAnswer () ) then
		Close ();
	endif;
	
EndProcedure

&AtServer
Function applyAnswer ()
	
	if ( meetingExpired () ) then
		return false;
	endif;
	p = RunMeetings.AnswerParams ();
	p.Member = CurrentUser;
	p.Meeting = Object.Ref;
	p.Answer = YourAnswer;
	p.Comment = YourComment;
	if ( TesterCache.Testing () ) then
		RunMeetings.ApplyAnswer ( p );
	else
		params = new Array ();
		params.Add ( p );
		BackgroundJobs.Execute ( "RunMeetings.ApplyAnswer", params );
	endif;
	return true;
	
EndFunction

&AtServer
Function meetingExpired ()
	
	if ( Object.Start < CurrentSessionDate () ) then
		Output.MeetingExpired ( , "Start" );
		return true;
	endif;
	return false;
	
EndFunction

&AtClient
Procedure Complete ( Command )

	if ( meetingStarted ( ThisObject ) ) then
		Output.CompleteMeetingConfirmation ( ThisObject );
	else
		Output.MeetingNotStarted ( , "Start" );
	endif;
	
EndProcedure

&AtClient
Procedure CompleteMeetingConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	callback = new NotifyDescription ( "FinishSpecified", ThisObject );
	OpenForm ( "Document.Meeting.Form.Finish", new Structure ( "Start, Finish", Object.Start, Object.Finish ),
		ThisObject, , , , callback );
	
EndProcedure

&AtClient
Procedure FinishSpecified ( Time, Params ) export
	
	if ( Time = undefined ) then
		return;
	endif;
	Object.Completed = true;
	Object.Finish = Time;
	TaskForm.CalcDuration ( Object );
	writeAndClose ();
	
EndProcedure

&AtClient
Procedure Cancel ( Command )
	
	if ( meetingExpired () ) then
		return;
	else
		OpenForm ( "Document.Meeting.Form.Cancel", , ThisObject, , , , new NotifyDescription ( "ReasonDefined", ThisObject ) );
	endif;
	
EndProcedure

&AtClient
Procedure ReasonDefined ( Reason, Params ) export
	
	if ( Reason = undefined ) then
		return;
	endif;
	Object.Formed = false;
	Object.Canceled = true;
	Object.Reason = Reason;
	writeAndClose ();
	
EndProcedure

// *****************************************
// *********** Table Members

&AtClient
Procedure MembersOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure MembersOnStartEdit ( Item, NewRow, Clone )
	
	if ( not NewRow ) then
		return;
	endif;
	initRow ( TableRow, Object, Clone );
	
EndProcedure

&AtClient
Procedure MembersOnEditEnd ( Item, NewRow, CancelEdit )
	
	if ( CancelEdit ) then
		return;
	endif;
	calcTotals ( ThisObject );
	showWarning ( ThisObject );
	
EndProcedure

&AtClient
Procedure MembersAfterDeleteRow ( Item )
	
	calcTotals ( ThisObject );
	showWarning ( ThisObject );
	
EndProcedure
