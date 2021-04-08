#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCheck ( Cancel ) export
	
	setPeriod ();
	
EndProcedure

Procedure setPeriod ()
	
	period = DC.GetParameter ( Params.Composer, "Period" );
	if ( not period.Use ) then
		period.Use = true;
	endif; 
	
EndProcedure 

#endif