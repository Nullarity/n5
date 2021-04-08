// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setFilter ();
	
EndProcedure

&AtServer
Procedure setFilter ()
	
	item = Parameters.Item; 
	if ( item.IsEmpty () ) then
		return;
	endif;
	Items.List.Representation = TableRepresentation.List;
	features = DF.Pick ( item, "Features" );
	DC.SetFilter ( List, "Parent", features );
	if ( features.IsEmpty () ) then
		DC.SetFilter ( List, "IsFolder", false );
	endif;
	
EndProcedure