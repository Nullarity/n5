// *****************************************
// *********** Group Form

&AtClient
Procedure InvoiceFilterOnChange ( Item )
	
	filterByInvoice ();	
	
EndProcedure

&AtServer
Procedure filterByInvoice ()
	
	setFilter = ( InvoiceFilter = 1 );
	filterValue = ( InvoiceFilter = 0 );
	DC.ChangeFilter ( List, "Invoiced", filterValue, setFilter );
	
EndProcedure 
