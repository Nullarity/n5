
&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif; 
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillNew ()

	if ( Logins.Sysadmin () ) then
		Object.Tenant = undefined;
	else
		Object.Tenant = SessionParameters.Tenant;
	endif;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DescriptionOnChange ( Item )

	applyDescription ();

EndProcedure

&AtClient
Procedure applyDescription ()
	
	Object.FullDescription = Object.Description;
	
EndProcedure