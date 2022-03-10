&AtServer
Function Completed ( Object ) export
	
	return not ( Object.Responsible.IsEmpty ()
		or Object.Resolution.IsEmpty () );

EndFunction

&AtServer
Procedure Init ( Object, Responsible = undefined ) export
	
	Object.Responsible = ? ( Responsible = undefined, SessionParameters.User, Responsible );

EndProcedure

Procedure ApplyResolution ( Object ) export

	if ( Object.Resolution = PredefinedValue ( "Enum.AllowDeny.Deny" ) ) then
		Object.Expired = undefined;
	else
		#if ( Client ) then
			now = SessionDate ();
		#else
			now = CurrentSessionDate ();
		#endif
		Object.Expired = now + 86400;
	endif;

EndProcedure

&AtServer
Procedure NotifyUser ( Object ) export
	
	p = new Structure ( "Creator, Document, Resolution, Responsible" );
	FillPropertyValues ( p, Object );
	params = new Array ();
	params.Add ( p );
	Jobs.Run ( "PermissionsMailing.NotifyUser", params, , , TesterCache.Testing () );
	
EndProcedure
