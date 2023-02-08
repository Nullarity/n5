#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkDoubles () ) then
		Cancel = true;
	endif;
	if ( not checkPeriod () ) then
		Cancel = true;
	endif;
	if ( Cancel ) then
		return;
	endif;
	if ( not roomAvailable () ) then
		Cancel = true;
	endif;
	
EndProcedure

Function checkDoubles ()
	
	doubles = Collections.GetDoubles ( Members, "Member" );
	if ( doubles.Count () > 0 ) then
		for each row in doubles do
			Output.DoubleParticipants ( , Output.Row ( "Members", row.LineNumber, "Member" ) );
		enddo; 
		return false;
	endif; 
	return true;
	
EndFunction 

Function checkPeriod ()
	
	if ( not Periods.Ok ( Start, Finish ) ) then
		Output.PeriodError ( , "Finish" );
		return false;
	endif; 
	if ( Start < CurrentSessionDate () ) then
		Output.MeetingExpired ( , "Start" );
		return false;
	endif; 
	return true;
	
EndFunction

Function roomAvailable ()
	
	SetPrivilegedMode ( true );
	data = getReservation ();
	if ( data = undefined ) then
		return true;
	endif;
	meeting = data.Ref;
	Output.RoomOccupied ( new Structure ( "Meeting", meeting ), , meeting );
	return false;
	
EndFunction

Function getReservation ()
	
	s = "
	|// @Data
	|select top 1 Meetings.Ref as Ref
	|from Document.Meeting as Meetings
	|where Meetings.Ref <> &Ref
	|and Meetings.Room = &Room
	|and Meetings.Formed
	|and not Meetings.Completed
	|and ( Meetings.Start between &Start and &Finish
	|	or Meetings.Finish between &Start and &Finish )
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Room", Room );
	q.SetParameter ( "Start", Start );
	q.SetParameter ( "Finish", Finish );
	return SQL.Exec ( q ).Data;
	
EndFunction

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( DeletionMark
		and stillActive () ) then
		Cancel = true;
	endif;
	
EndProcedure

Function stillActive ()
	
	if ( Formed and not Canceled ) then
		Output.MeetingShouldBeCanceled ();
		return true;
	else
		return false;
	endif;
	
EndFunction

#endif