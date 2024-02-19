// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif;

EndProcedure

&AtServer
Procedure fillNew ()
	
	Object.Creator = SessionParameters.User;
	
EndProcedure