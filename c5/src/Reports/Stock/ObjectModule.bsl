#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export	
	
	filterWarehouses ();
	hideParams ();
	setPeriod ();
	SetPrivilegedMode ( true );
	
EndProcedure

Procedure filterWarehouses ()

	DC.SetParameter ( Params.Settings, "Warehouses", allowedWarehouses (), true );

EndProcedure

Function allowedWarehouses ()

	q = new Query ( "select allowed Ref as Ref from Catalog.Warehouses" );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );

EndFunction

Procedure hideParams ()
	
	list = Params.HiddenParams;
	list.Add ( "Warehouses" );
	
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