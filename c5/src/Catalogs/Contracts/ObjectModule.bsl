#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkRates ( CheckedAttributes );
	
EndProcedure

Procedure checkRates ( Attributes )
	
	if ( Currency = Application.Currency () ) then
		return;
	endif;
	if ( Customer ) then
		Attributes.Add ( "CustomerRateType" );
	endif;
	if ( Vendor ) then
		Attributes.Add ( "VendorRateType" );
	endif;
	
EndProcedure

#endif