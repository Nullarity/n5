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
	|Customer hide filled ( CustomerFilter ) or filled ( FixedCustomerFilter );
	|GroupQuickInfo show filled ( CustomerFilter );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadFixedFilters ()
	
	Parameters.Filter.Property ( "Customer", FixedCustomerFilter );
	CustomerFilter = FixedCustomerFilter;
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )

	if ( EventName = Enum.InvoiceRecordsWrite () ) then
		updateList ( Source.Customer );
	elsif ( EventName = Enum.MessageInvoicesExchnage () ) then
		Items.List.Refresh ();
	endif; 

EndProcedure

&AtClient
Procedure updateList ( Customer )
	
	refresh = FixedCustomerFilter = Customer
	or CustomerFilter = Customer;
	if ( refresh ) then
		Items.List.Refresh ();
	endif;

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CustomerFilterOnChange ( Item )
	
	applyCustomer ();
	
EndProcedure

&AtServer
Procedure applyCustomer ()
	
	filterByCustomer ();
	Appearance.Apply ( ThisObject, "CustomerFilter" );
	
EndProcedure

&AtServer
Procedure filterByCustomer ()
	
	DC.ChangeFilter ( List, "Customer", CustomerFilter, not CustomerFilter.IsEmpty () );
	
EndProcedure 
