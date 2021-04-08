#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( SetNewPrices ) then
		CheckedAttributes.Add ( "NewPrices" );
	endif; 
	
EndProcedure

#endif