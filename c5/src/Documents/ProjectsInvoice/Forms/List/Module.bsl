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
	|CustomerFilter show empty ( FixedCustomerFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFixedFilters ()
	
	Parameters.Filter.Property ( "Customer", FixedCustomerFilter );
	
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

&AtServer
Procedure filterByClient ()
	
	if ( not FixedCustomerFilter.IsEmpty () ) then
		return;
	endif; 
	DC.ChangeFilter ( List, "Customer", CustomerFilter, not CustomerFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure PaymentFilterOnChange ( Item )
	
	filterByPayment ();	
	
EndProcedure

&AtServer
Procedure filterByPayment ()
	
	setFilter = ( PaymentFilter = 1 );
	filterValue = ( PaymentFilter = 0 );
	DC.ChangeFilter ( List, "Paid", filterValue, setFilter );
	
EndProcedure 
