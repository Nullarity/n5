#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCheck ( Cancel ) export
	
	resetPeriod ();
	
EndProcedure

Procedure resetPeriod ()
	
	composer = Params.Composer;
	filter = DC.FindFilter ( composer, "Timesheet" );
	if ( filter.Use ) then
		period = DC.GetParameter ( composer, "Period" );
		period.Use = false;
	endif; 
	
EndProcedure 

Procedure AfterOutput () export
	
	if ( Params.Variant = "#Mobile" ) then
		resetFixation ();
	endif; 
	
EndProcedure 

Procedure resetFixation ()
	
	Params.Result.FixedTop = 0;
	
EndProcedure 

#endif