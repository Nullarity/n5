// *****************************************
// *********** List

&AtClient
Procedure RangeFilterOnChange ( Item )
	
	filterByRange ();
	
EndProcedure

&AtClient
Procedure filterByRange ()
	
	DC.ChangeFilter ( List, "Range", RangeFilter, not RangeFilter.IsEmpty () );
	
EndProcedure
