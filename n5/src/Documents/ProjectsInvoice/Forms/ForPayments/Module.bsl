
// *****************************************
// *********** Group Form

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
