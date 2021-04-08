#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Realtime;

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( DeletionMark ) then
		InvoiceRecords.Delete ( ThisObject );
	endif; 
	setProperties ();
	
EndProcedure

Procedure setProperties ()
	
	Realtime = Forms.RealtimePosting ( ThisObject );
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( not DeletionMark ) then
		InvoiceRecords.Sync ( ThisObject );
	endif; 
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	env.Realtime = Realtime;
	Cancel = not Documents.LVITransfer.Post ( env );
	
EndProcedure

#endif
