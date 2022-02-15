#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Realtime;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	checkTransitAccount ( CheckedAttributes );
	checkVAT ( CheckedAttributes );
	
EndProcedure

Procedure checkTransitAccount ( CheckedAttributes )
	
	if ( Method = Enums.PaymentMethods.Card ) then
		CheckedAttributes.Add ( "TransitAccount" );
	endif; 
	
EndProcedure

Procedure checkVAT ( CheckedAttributes )
	
	if ( VATUse > 0 ) then
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

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	env.Realtime = Realtime;
	env.Interactive = Posting.Interactive ( ThisObject );
	Cancel = not Documents.RetailSales.Post ( env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	BelongingToSequences.Cost.Clear ();
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		SequenceCost.Rollback ( Ref, Company, PointInTime () );
	endif;
	PettyCash.Sync ( ThisObject );
	
EndProcedure

#endif