#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkWarehouse ( CheckedAttributes );
	
EndProcedure

Procedure checkWarehouse ( CheckedAttributes )
	
	if ( not DF.Pick ( Range, "Online" ) ) then
		CheckedAttributes.Add ( "Warehouse" );
	endif;
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( DeletionMark ) then
		unpost ();
	else
		env = Posting.GetParams ( Ref, RegisterRecords );
		Cancel = not Documents.EnrollRange.Post ( env );
	endif;
	
EndProcedure

Procedure unpost ()
	
	Posting.ClearRecords ( RegisterRecords );
	
EndProcedure

#endif
