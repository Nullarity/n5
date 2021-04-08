#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Reposted;
var Realtime;	

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	checkWarehouse ( CheckedAttributes );

EndProcedure
		
Procedure checkWarehouse ( CheckedAttributes )
	
	if ( Items.Count () > 0 ) then
		CheckedAttributes.Add ( "Warehouse" );
	endif; 
	
EndProcedure 

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
	
	Reposted = Posted;
	Realtime = Forms.RealtimePosting ( ThisObject );
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		SequenceCost.Rollback ( Ref, Company, PointInTime () );
	endif;
	if ( not DeletionMark ) then
		InvoiceRecords.Sync ( ThisObject );
	endif; 
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	BelongingToSequences.Cost.Clear ();
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	Env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.VendorReturn.Post ( Env );
	
EndProcedure

#endif