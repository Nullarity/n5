// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	hideIndividual ();
	
EndProcedure

&AtServer
Procedure hideIndividual ()
	
	if ( Parameters.Filter.Property ( "Individual" ) ) then
		Items.Individual.Visible = false;
	endif; 
	
EndProcedure 
