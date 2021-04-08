#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export
	
	resetCurrency ();
	
EndProcedure

Procedure resetCurrency ()
	
	currencyParameter = DC.GetParameter ( Params.Settings, "Currency" );
	currencyParameter.Use = true;
	if ( not ValueIsFilled ( currencyParameter.Value ) ) then
		currencyParameter.Value = Application.Currency ();
	endif; 
	
EndProcedure

#endif