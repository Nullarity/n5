// *****************************************
// *********** List

&AtServer
Procedure ListOnLoadUserSettingsAtServer ( Item, Settings, StandardSettingsUsed )
	
	setView ();
	
EndProcedure

&AtServer
Procedure setView ()
	
	if ( Parameters.Filter.Property ( "Parent" ) ) then
		Items.List.Representation = TableRepresentation.List;
	else
		Items.List.Representation = TableRepresentation.HierarchicalList;
	endif;
	
EndProcedure
