#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export	
	
	adjustPeriod ();
	
EndProcedure

Procedure adjustPeriod ()
	
	settings = Params.Settings;
	ref = DC.FindFilter ( settings, "Ref" );
	if ( ref.Use ) then
		DC.GetParameter ( settings, "Period" ).Use = false;
	endif;
	
EndProcedure 

#endif