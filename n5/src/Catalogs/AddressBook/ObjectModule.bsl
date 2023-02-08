#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not Mailboxes.CheckAddresses ( ThisObject, "Email" ) ) then
		Cancel = true;
	endif; 
	if ( not Mailboxes.CheckName ( ThisObject, "Description" ) ) then
		Cancel = true;
	endif; 

EndProcedure

#endif