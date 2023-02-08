#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	if ( not checkPeriods () ) then
		Cancel = true;
	endif; 
	
EndProcedure

Function checkPeriods ()
	
	if ( not Periods.Ok ( FromDate, ToDate ) ) then
		Output.PeriodError ( , "ToDate" );
		return false;
	endif;
	if ( not Periods.Ok ( ToDate, ValidTo ) ) then
		Output.PeriodError ( , "CompletionDate" );
		return false;
	endif;
	return true;
	
EndFunction 

#endif