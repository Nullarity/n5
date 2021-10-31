#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export	
	
	setPeriod ();
	
EndProcedure

Procedure setPeriod ()
	
	settings = Params.Settings;
	date = DF.Pick ( DC.GetParameter ( settings, "Date" ).Value, "Date" );
	DC.SetParameter ( settings, "YearStart", BegOfYear ( date ) );
	DC.SetParameter ( settings, "PaymentDate", EndOfDay ( date ) );
	
EndProcedure 

Procedure AfterOutput () export

	if ( Params.Variant = "#Fill" ) then
		result = new Structure ( "Compensations, Taxes" );
		data = Params.Result;
		last = data.Ubound ();
		result.Compensations = data [ last ].Unload ();
		result.Taxes = data [ last - 1 ].Unload ();
		Params.Result = result;
	endif;
	
EndProcedure

#endif