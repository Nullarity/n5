// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		setOwner ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure

&AtServer
Procedure setOwner ()
	
	if ( not Object.Owner.IsEmpty () ) then
		return;
	endif; 
	Object.Owner = SessionParameters.User;
	
EndProcedure 