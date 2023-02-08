// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	enableCustomerFilter ();
	filterByStatus ();
	filterByInvoice ();
	
EndProcedure

&AtServer
Procedure enableCustomerFilter ()
	
	owner = undefined;
	Parameters.Filter.Property ( "Owner", owner );
	Items.CustomerFilter.Visible = not ValueIsFilled ( owner );
	
EndProcedure 

&AtServer
Procedure filterByStatus ()
	
	if ( StatusFilter = 0 ) then
		DC.ChangeFilter ( List, "Completed", false, true );
	elsif ( StatusFilter = 1 ) then
		DC.ChangeFilter ( List, "Completed", true, true );
	elsif ( StatusFilter = 2 ) then
		DC.DeleteFilter ( List, "Completed" );
	endif; 
	
EndProcedure 

&AtServer
Procedure filterByInvoice ()
	
	if ( not AccessRight ( "View", Metadata.InformationRegisters.ProjectInvoices )  ) then
		return;
	endif; 
	setFilter = ( InvoiceFilter = 1 );
	filterValue = ( InvoiceFilter = 0 );
	DC.ChangeFilter ( List, "Invoiced", filterValue, setFilter );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CustomerFilterOnChange ( Item )
	
	filterByCustomer ();

EndProcedure

&AtServer
Procedure filterByCustomer ()
	
	DC.ChangeFilter ( List, "Owner", CustomerFilter, not CustomerFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure StatusFilterOnChange ( Item )
	
	filterByStatus ();
	
EndProcedure

&AtClient
Procedure InvoiceFilterOnChange ( Item )
	
	filterByInvoice ();	
	
EndProcedure
