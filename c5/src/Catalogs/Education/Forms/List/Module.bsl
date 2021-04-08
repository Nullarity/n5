// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	hideIndividual ();
	
EndProcedure

&AtServer
Procedure hideIndividual ()
	
	if ( Parameters.Filter.Property ( "Owner" ) ) then
		Items.Owner.Visible = false;
	endif; 
	
EndProcedure 
