#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var PreviousDeletionMark export;

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	PreviousDeletionMark = DF.Pick ( Ref, "DeletionMark" );
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	PettyCash.SyncBase ( ThisObject );
	
EndProcedure

#endif