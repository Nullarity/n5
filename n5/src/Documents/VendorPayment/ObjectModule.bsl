#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	PaymentForm.Check ( ThisObject, Cancel, CheckedAttributes );
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	PettyCash.Sync ( ThisObject );
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not RunPayments.Post ( env );
	
EndProcedure

#endif