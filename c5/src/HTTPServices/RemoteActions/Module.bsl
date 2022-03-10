
Function DoGet ( Request )
	
	SetPrivilegedMode ( true );
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
	elsif ( action = Enums.RemoteActions.PermissionAllow
		or action = Enums.RemoteActions.PermissionDeny ) then
		aboutPermission ( result );
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
	|<head>
	|<meta content=""text/html;charset=utf-8"" http-equiv=""Content-Type"">
	|<meta content=""utf-8"" http-equiv=""encoding"">
	|</head>
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
	|<head>
	|<meta content=""text/html;charset=utf-8"" http-equiv=""Content-Type"">
	|<meta content=""utf-8"" http-equiv=""encoding"">
	|</head>
	|<body>
	|<p>" + Output.RemoteActionApplied () + "
	|</p>
	|<button onclick='window.close();'>OK</button>
	|</body>
	|</html>
	|";
	response = new HTTPServiceResponse ( 200 );
	response.SetBodyFromString ( html );
	return response;

EndFunction

Procedure aboutPermission ( Data )
	
	obj = Data.Parameter1.GetObject ();
	responsible = Data.Parameter2;
	SessionParameters.User = responsible;
	if ( PermissionForm.Completed ( obj )
		and obj.Responsible <> responsible ) then
		raise Output.PermissionComplete ();
	endif;                                    
	PermissionForm.Init ( obj, responsible );
	if ( Data.Action = Enums.RemoteActions.PermissionAllow ) then
		obj.Resolution = Enums.AllowDeny.Allow;
	else
		obj.Resolution = Enums.AllowDeny.Deny;
	endif;
	PermissionForm.ApplyResolution ( obj );
	checkObject ( obj );
	obj.Write ();
	PermissionForm.NotifyUser ( obj );
	
EndProcedure

Procedure checkObject ( Object )
	
	if ( Object.CheckFilling () ) then
		return;
	endif;
	list = GetUserMessages ();
	text = new Array ();
	for each msg in list do
		text.Add ( msg.Text );
	enddo;
	if ( text.Count () > 0 ) then
		raise StrConcat ( text, "; " );
	endif;
	
EndProcedure
