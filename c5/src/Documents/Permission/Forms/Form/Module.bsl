// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		raise Output.InteractiveCreationForbidden ();
	endif;
	completed = not ( Object.Responsible.IsEmpty ()
		or Object.Resolution.IsEmpty () );
	if ( not completed
		and SalesRestriction.CanApprove () ) then
		init ();
	endif;
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Expired show Object.Resolution = Enum.AllowDeny.Allow;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure init ()
	
	Object.Responsible = SessionParameters.User;

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	notifyUser ();
	
EndProcedure

&AtServer
Procedure notifyUser ()
	
	p = new Structure ( "Creator, Document, Resolution, Responsible" );
	FillPropertyValues ( p, Object );
	params = new Array ();
	params.Add ( p );
	Jobs.Run ( "PermissionsMailing.NotifyUser", params, , , TesterCache.Testing () );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )

	Notify ( Enum.MessagePermissionIsSaved (), Object.Document );

EndProcedure

// *****************************************
// *********** Form events

&AtClient
Procedure ResolutionOnChange ( Item )
	
	setExpiration ();
	Appearance.Apply ( ThisObject, "Object.Resolution" );

EndProcedure

&AtClient
Procedure setExpiration ()
	
	if ( Object.Resolution = PredefinedValue ( "Enum.AllowDeny.Deny" ) ) then
		Object.Expired = undefined;
	else
		Object.Expired = SessionDate () + 86400;
	endif;

EndProcedure