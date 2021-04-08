// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	hideItem ();
	
EndProcedure

&AtServer
Procedure hideItem ()
	
	if ( Parameters.Filter.Property ( "Owner" ) ) then
		Items.Owner.Visible = false;
	endif; 
	
EndProcedure 
