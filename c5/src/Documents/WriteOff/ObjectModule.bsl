#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Realtime;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkVAT ( CheckedAttributes );

EndProcedure

Procedure checkVAT ( CheckedAttributes )
	
	if ( VATUse > 0 ) then
		CheckedAttributes.Add ( "VATAccount" );
		CheckedAttributes.Add ( "Items.VATAccount" );
	endif; 
	
EndProcedure

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	setProperties ();
	
EndProcedure

Procedure setProperties ()
	
	Realtime = Forms.RealtimePosting ( ThisObject );
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		SequenceCost.Rollback ( Ref, Company, PointInTime () );
		return;
	endif;
	if ( not DeletionMark ) then
		InvoiceRecords.Sync ( ThisObject );
	endif; 
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	env.Realtime = Realtime;
	Cancel = not Documents.WriteOff.Post ( env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	BelongingToSequences.Cost.Clear ();
	
EndProcedure

#endif