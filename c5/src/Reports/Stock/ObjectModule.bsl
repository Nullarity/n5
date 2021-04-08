#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export	
	
	SetPrivilegedMode(true);
	setPeriod ();
	
EndProcedure

Procedure setPeriod ()
	
	settings = Params.Settings;
	asof = DC.GetParameter ( settings, "Asof" );
	calendarDate = asof.Value;
	if ( not asof.Use ) then
		return;
	endif;
	date = DF.Pick ( calendarDate, "Date", BegOfDay ( CurrentSessionDate () ) );
	if ( calendarDate.IsEmpty () ) then
		asof.Value = Catalogs.Calendar.GetDate ( date );
	endif;
	reportDate = EndOfDay ( date );
	periodParam = DC.GetParameter ( Params.Settings, "DateStart" );
	periodParam.Use = true;
	periodParam.Value = reportDate;
	periodParam = DC.GetParameter ( Params.Settings, "DateEnd" );
	periodParam.Use = true;
	periodParam.Value = reportDate;
	
EndProcedure 

#endif