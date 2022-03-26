Function Completed ( Object ) export
	
	return not ( Object.Responsible.IsEmpty ()
		or Object.Resolution.IsEmpty () );

EndFunction

Procedure ApplyResolution ( Object ) export

	Object.Responsible = SessionParameters.User;
	if ( Object.Resolution = Enums.AllowDeny.Deny ) then
		Object.Expired = undefined;
	else
		Object.Expired = CurrentSessionDate () + Enum.ConstantsPermissionExpiration ();
	endif;

EndProcedure

Procedure SendSalesResponse ( Object ) export
	
	p = new Structure ( "Creator, Document, Resolution, Responsible" );
	FillPropertyValues ( p, Object );
	params = new Array ();
	params.Add ( p );
	Jobs.Run ( "SalesPermissionMailing.NotifyUser", params, , , TesterCache.Testing () );
	
EndProcedure

Procedure SendChangesResponse ( Object ) export
	
	p = new Structure ( "Creator, Permission, Responsible, Resolution" );
	FillPropertyValues ( p, Object );
	p.Permission = Object.Ref;
	params = new Array ();
	params.Add ( p );
	Jobs.Run ( "ChangesPermissionMailing.NotifyUser", params, , , TesterCache.Testing () );
	
EndProcedure
