// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) 
		and ( Object.Owner.IsEmpty () ) then
		Object.Owner = Application.Company ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure
