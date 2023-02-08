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
	|CustomerFilter show empty ( InvoiceFilter ) and empty ( FixedCustomerFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFixedFilters ()
	
	Parameters.Filter.Property ( "Customer", FixedCustomerFilter );
	Parameters.Filter.Property ( "Invoice", InvoiceFilter );
	
EndProcedure 

&AtServer
Procedure OnLoadDataFromSettingsAtServer ( Settings )
	
	resetLinkedFilters ();
	filterByClient ();
	
EndProcedure

&AtServer
Procedure resetLinkedFilters ()
	
	if ( FixedCustomerFilter.IsEmpty () and InvoiceFilter.IsEmpty () ) then
		return;
	endif; 
	CustomerFilter = undefined;
	
EndProcedure 

&AtServer
Procedure filterByClient ()
	
	if ( not FixedCustomerFilter.IsEmpty () ) then
		return;
	endif; 
	DC.ChangeFilter ( List, "Customer", CustomerFilter, not CustomerFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	uploadFixedFilters ();

EndProcedure

&AtClient
Procedure uploadFixedFilters ()
	
	if ( not FixedCustomerFilter.IsEmpty () ) then
		CustomerFilter = FixedCustomerFilter;
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CustomerFilterOnChange ( Item )
	
	filterByClient ();
	
EndProcedure
