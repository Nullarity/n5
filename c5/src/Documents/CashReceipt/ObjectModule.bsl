#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( DeletionMark ) then
		PettyCash.DeleteBase ( ThisObject );
	endif; 
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( not DeletionMark ) then
		PettyCash.SyncBase ( ThisObject );
	endif; 
	
EndProcedure

#endif