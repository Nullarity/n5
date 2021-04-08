#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Reposted;
var Realtime;
var Env;

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	setProperties ();
	
EndProcedure

Procedure setProperties ()
	
	Reposted = Posted;
	Realtime = Forms.RealtimePosting ( ThisObject );
	
EndProcedure 

Procedure Posting ( Cancel, PostingMode )
	
	Env = Posting.GetParams ( Ref, RegisterRecords );
	Env.Reposted = Reposted;
	Env.Realtime = Realtime;
	Cancel = not Documents.CustomsDeclaration.Post ( Env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	if ( Dependencies.Exist ( Ref ) ) then
		Cancel = true;
		return;
	endif; 
	Dependencies.Unbind ( Ref );
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	BelongingToSequences.Cost.Clear ();
	
EndProcedure

#endif