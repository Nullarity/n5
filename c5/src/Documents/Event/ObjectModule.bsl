#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var IsNew;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkPeriod ()
		or not employeeAvailable () ) then
		Cancel = true;
	endif;
	
EndProcedure

Function checkPeriod ()
	
	if ( not Periods.Ok ( Start, Finish ) ) then
		Output.PeriodError ( , "Finish" );
		return false;
	endif; 
	now = CurrentSessionDate ();
	if ( Start < now
		and Status = Enums.EventStatuses.Scheduled ) then
		Output.EventExpired ( , "Start" );
		return false;
	elsif ( Start > now
		and Status = Enums.EventStatuses.Completed ) then
		Output.EventNotStarted ( , "Start" );
		return false;
	endif; 
	return true;
	
EndFunction

Function employeeAvailable ()
	
	SetPrivilegedMode ( true );
	data = getConflict ();
	if ( data = undefined ) then
		return true;
	endif;
	event = data.Ref;
	Output.ResponsibleBusy ( new Structure ( "Responsible, Event", Responsible, event ), , event );
	return false;
	
EndFunction

Function getConflict ()
	
	s = "
	|// @Data
	|select top 1 Events.Ref as Ref
	|from Document.Event as Events
	|where Events.Ref <> &Ref
	|and not Events.DeletionMark
	|and Events.Responsible = &Responsible
	|and Events.Status = value ( Enum.EventStatuses.Scheduled )
	|and ( Events.Start between &Start and &Finish
	|	or Events.Finish between &Start and &Finish )
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Responsible", Responsible );
	q.SetParameter ( "Start", Start );
	q.SetParameter ( "Finish", Finish );
	return SQL.Exec ( q ).Data;
	
EndFunction

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	IsNew = IsNew ();
	removeReminder ();
	if ( DataExchange.Load
		or DeletionMark ) then
		return;
	endif;
	setReminderDate ();
	
EndProcedure

Procedure removeReminder ()
	
	if ( IsNew ) then
		return;
	endif; 
	Jobs.Remove ( Ref );
	
EndProcedure 

Procedure setReminderDate ()
	
	if ( Reminder = Enums.Reminder.None ) then
		return;
	endif; 
	ReminderDate = Enums.Reminder.GetDate ( Start, Reminder );
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load
		or DeletionMark ) then
		return;
	endif; 
	if ( notifyResponsible () ) then
		TasksReminder.Write ( ThisObject );
	endif; 
	
EndProcedure

Function notifyResponsible ()
	
	remind = Reminder <> Enums.Reminder.None
	and Status = Enums.EventStatuses.Scheduled;
	return remind and Start > PeriodsSrv.CurrentUserDate ( Responsible );
	
EndFunction

#endif