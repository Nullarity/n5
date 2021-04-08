#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCheck ( Cancel ) export
	
	if ( not checkPeriodicity () ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

Function checkPeriodicity ()
	
	if ( Params.Variant = "#Default" ) then
		return true;
	elsif ( Params.Variant = "#IncomeStatement" ) then
		parameter = DC.FindParameter ( SettingsComposer, "Periodicity" );
		if ( parameter.Use ) then
			periodicity = DC.GetParameter ( Params.Composer, "Periodicity" );
			if ( not periodicity.Use or not ValueIsFilled ( periodicity.Value ) ) then
				Output.PeriodicityError ();
				return false;
			endif; 
		endif;	
	endif; 
	return true;
	
EndFunction 

#endif