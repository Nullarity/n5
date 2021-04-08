// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		raise Output.InteractiveCreationForbidden ();
	endif;
	ReadOnly = true;
	
EndProcedure
