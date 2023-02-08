#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkDescription ( CheckedAttributes );
	checkRates ( CheckedAttributes );
	checkPeriod ( CheckedAttributes );
	
EndProcedure

Procedure checkDescription ( Attributes )
	
	if ( Vendor ) then
		Attributes.Add ( "Description" );
	endif;

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

Procedure checkPeriod ( Attributes )
	
	if ( Signed ) then
		Attributes.Add ( "DateStart" );
		Attributes.Add ( "DateEnd" );
	endif;
	
EndProcedure

#endif