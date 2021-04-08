#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( DeletionMark ) then
		unpost ();
	else
		env = Posting.GetParams ( Ref, RegisterRecords );
		Cancel = not Documents.SplitRange.Post ( env );
	endif;
	
EndProcedure

Procedure unpost ()
	
	Posting.ClearRecords ( RegisterRecords );
	if ( not Range1.IsEmpty () ) then
		Range1.GetObject ().SetDeletionMark ( true );
	endif;
	if ( not Range2.IsEmpty () ) then
		Range2.GetObject ().SetDeletionMark ( true );
	endif;
	
EndProcedure

#endif
