// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	hideItem ();
	
EndProcedure

&AtServer
Procedure hideItem ()
	
	if ( Parameters.Filter.Property ( "Item" ) ) then
		Items.Item.Visible = false;
	endif; 
	
EndProcedure 
