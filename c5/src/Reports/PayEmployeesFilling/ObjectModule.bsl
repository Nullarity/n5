#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export	
	
	setPeriod ();
	
EndProcedure

Procedure setPeriod ()
	
	settings = Params.Settings;
	date = DF.Pick ( DC.GetParameter ( settings, "Date" ).Value, "Date" );
	DC.SetParameter ( settings, "YearStart", BegOfYear ( date ) );
	DC.SetParameter ( settings, "BalancesDate", EndOfDay ( date ) + 1 );
	
EndProcedure 

#endif