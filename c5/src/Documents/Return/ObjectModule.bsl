#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
var Realtime;
var Reposted;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	checkVAT ( CheckedAttributes );
	
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
	if ( not IsNew () ) then
		Catalogs.Lots.Sync ( Ref, DeletionMark );
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
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	Env = Posting.GetParams ( Ref, RegisterRecords );
	Env.Reposted = Reposted;
	Env.Realtime = Realtime;
	Cancel = not Documents.Return.Post ( Env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	
EndProcedure

#endif