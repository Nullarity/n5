#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkVATCode ( CheckedAttributes );
	
EndProcedure

Procedure checkVATCode ( CheckedAttributes )

	if ( VAT ) then
		CheckedAttributes.Add ( "VATCode" );
	endif;

EndProcedure

#endif
