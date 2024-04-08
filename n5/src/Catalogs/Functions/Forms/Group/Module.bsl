// *****************************************
// *********** Form events

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
