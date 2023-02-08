#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( DeletionMark ) then
		unpost ();
	else
		env = Posting.GetParams ( Ref, RegisterRecords );
		Cancel = not Documents.TransferRange.Post ( env );
	endif;
	
EndProcedure

Procedure unpost ()
	
	Posting.ClearRecords ( RegisterRecords );
	
EndProcedure

#endif
