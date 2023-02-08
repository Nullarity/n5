#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export
	
	resetCurrency ();
	
EndProcedure

Procedure resetCurrency ()
	
	invoice = DC.FindFilter ( Params.Settings, "Invoice" );
	currency = DC.FindFilter ( Params.Settings, "Currency" );
	if ( invoice.Use )
		and ( invoice.ComparisonType = DataCompositionComparisonType.Equal
		or invoice.ComparisonType = DataCompositionComparisonType.InHierarchy
		or invoice.ComparisonType = DataCompositionComparisonType.InListByHierarchy ) then
		currency.Use = false;
	else
		currency.Use = true;
		if ( not ValueIsFilled ( currency.RightValue ) ) then
			currency.RightValue = Application.Currency ();
		endif; 
	endif; 
	
EndProcedure

#endif