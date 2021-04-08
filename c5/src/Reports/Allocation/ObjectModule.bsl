#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export
	
	hideAsof ();
	setPeriod ();
	
EndProcedure

Procedure hideAsof ()
	
	list = Params.HiddenParams;
	list.Add ( "Asof" );
	
EndProcedure 

Procedure setPeriod ()
	
	if ( Reporter.IsFilling ( Params.Variant ) ) then
		return;
	endif; 
	settings = Params.Settings;
	reportDate = DC.GetParameter ( settings, "ReportDate" );
	calendarDate = reportDate.Value;
	if ( reportDate.Use ) then
		date = DF.Pick ( calendarDate, "Date", BegOfDay ( CurrentSessionDate () ) );
		if ( calendarDate.IsEmpty () ) then
			reportDate.Value = Catalogs.Calendar.GetDate ( date );
		endif;
		DC.SetParameter ( settings, "Asof", EndOfDay ( date ) + 1 );
	else
		DC.SetParameter ( settings, "Asof", undefined );
	endif;
	
EndProcedure


#endif