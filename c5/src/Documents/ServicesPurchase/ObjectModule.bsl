#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	RegulatedRangesForm.Check ( ThisObject, Cancel, CheckedAttributes );
	
EndProcedure

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	RegulatedRanges.Fill ( ThisObject );

EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	RegulatedRanges.Enroll ( ThisObject );
	
EndProcedure

#endif
