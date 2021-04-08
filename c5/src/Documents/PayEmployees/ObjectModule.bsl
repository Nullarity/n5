#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	// Bug workaround: Tabular section checking process should be done manually.
	// Otherwise, platform 8.3.10.2052 will explicitly add a new row into Compensation
	// tabular section that confuses users.
	CheckedAttributes.Add ( "Compensations" );
	checkAccount ( CheckedAttributes );
	
EndProcedure

Procedure checkAccount ( CheckedAttributes )
	
	if ( not Method.IsEmpty () ) then
		CheckedAttributes.Add ( "Account" );
	endif; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( DeletionMark ) then
		PettyCash.Delete ( ThisObject );
	endif; 
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( not DeletionMark ) then
		PettyCash.Sync ( ThisObject );
	endif; 
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.PayEmployees.Post ( env );
	
EndProcedure

#endif