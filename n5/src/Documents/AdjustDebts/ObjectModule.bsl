#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	AdjustDebtsForm.FillCheckProcessing ( ThisObject, Cancel, CheckedAttributes );
	
EndProcedure

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )

	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( DeletionMark ) then
		InvoiceRecords.Delete ( ThisObject );
	endif;

EndProcedure

Procedure OnWrite ( Cancel )

	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( not DeletionMark ) then
		InvoiceRecords.Sync ( ThisObject );
	endif; 

EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not RunAdjustDebts.Post ( env );
	
EndProcedure

#endif
