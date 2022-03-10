// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadFixedFilters ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|CustomerFilter show empty ( FixedCustomerFilter );
	|Customer show empty ( FixedCustomerFilter ) and empty ( CustomerFilter );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFixedFilters ()
	
	filter = Parameters.Filter;
	filter.Property ( "Customer", FixedCustomerFilter );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CustomerFilterOnChange ( Item )
	
	filterByCustomer ();
	
EndProcedure

&AtServer
Procedure filterByCustomer ()
	
	DC.ChangeFilter ( List, "Customer", CustomerFilter, not CustomerFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "CustomerFilter" );
	
EndProcedure 
