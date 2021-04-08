// *****************************************
// *********** Group Form

&AtClient
Procedure CustomsFilterOnChange ( Item )
	
	filterByCustoms ();
	
EndProcedure

&AtClient
Procedure filterByCustoms ()
	
	DC.ChangeFilter ( List, "Customs", CustomsFilter, not CustomsFilter.IsEmpty () );
	
EndProcedure
