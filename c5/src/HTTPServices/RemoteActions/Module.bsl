
Function DoGet ( Request )
	
	p = getParams ();
	fetchParams ( p, Request );
	error = false;
	result = perform ( p, error );
	if ( error ) then
		return fail ( result );
	else
		return success ();
	endif;
	
EndFunction

Function getParams ()
	
	p = new Structure ();
	p.Insert ( "ID" );
	return p;
	
EndFunction 

Procedure fetchParams ( Params, Request )
	
	p = Conversion.MapToStruct ( Request.QueryOptions );
	FillPropertyValues ( Params, p );
	
EndProcedure 

Function perform ( Params, Error )
	
	result = getData ( Params, Error );
	if ( Error ) then
		return result;
	endif;
	action = result.Action;
	if ( action = Enums.RemoteActions.MeetingYes
		or action = Enums.RemoteActions.MeetingMaybe
		or action = Enums.RemoteActions.MeetingNo ) then
		aboutMeeting ( result );
	endif;
	
EndFunction

Function getData ( Params, Error )
	
	r = InformationRegisters.RemoteActions.CreateRecordManager ();
	r.ID = new UUID ( Params.ID );
	r.Read ();
	if ( not r.Selected () ) then
		Error = true;
		return Output.RemoteActionNotFound ();
	endif;
	if ( r.Expire < CurrentSessionDate () ) then
		Error = true;
		return Output.RemoteActionExpired ();
	endif;
	return r;
	
EndFunction

Procedure aboutMeeting ( Data )
	
	p = RunMeetings.AnswerParams ();
	p.Meeting = Data.Parameter1;
	p.Member = Data.Parameter2;
	p.Answer = actionToAnswer ( Data );
	if ( TesterCache.Testing () ) then
		RunMeetings.ApplyAnswer ( p );
	else
		params = new Array ();
		params.Add ( p );
		BackgroundJobs.Execute ( "RunMeetings.ApplyAnswer", params );
	endif;
	
EndProcedure

Function actionToAnswer ( Data )
	
	action = Data.Action;
	if ( action = Enums.RemoteActions.MeetingYes ) then
		return Enums.InvitationAnswers.Yes;
	elsif ( action = Enums.RemoteActions.MeetingNo ) then
		return Enums.InvitationAnswers.No;
	else
		return Enums.InvitationAnswers.Maybe;
	endif;
	
EndFunction

Function fail ( Error )
	
	html = "
	|<!DOCTYPE html>
	|<html>
	|<body>
	|<p>" + Error + "</p>
	|</body>
	|</html>
	|";
	response = new HTTPServiceResponse ( 200 );
	response.SetBodyFromString ( html );
	return response;

EndFunction

Function success ()
	
	html = "
	|<!DOCTYPE html>
	|<html>
	|<body>
	|<p>" + Output.RemoteActionApplied () + "
	|</p>
	|<button onclick='window.close();'>Close</button>
	|</body>
	|</html>
	|";
	response = new HTTPServiceResponse ( 200 );
	response.SetBodyFromString ( html );
	return response;

EndFunction