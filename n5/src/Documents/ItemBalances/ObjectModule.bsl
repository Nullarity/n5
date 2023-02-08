#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Reposted;
var Realtime;

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
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	env.Reposted = Reposted;
	env.Realtime = Realtime;
	Cancel = not Documents.ItemBalances.Post ( env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	
EndProcedure

#endif