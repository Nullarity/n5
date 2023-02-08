#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export	
	
	setPeriod ();
	
EndProcedure

Procedure setPeriod ()
	
	settings = Params.Settings;
	asOfParameter = DC.GetParameter ( settings, "Asof" );
	asof = asOfParameter.Value;
	period = DC.Findparameter ( settings, "Period" );
	if ( period.UserSettingID = "" ) then
		if ( asof.IsEmpty () ) then
			date = CurrentSessionDate ();
			asOfParameter.Value = Catalogs.Calendar.GetDate ( date );
		else
			date = EndOfDay ( DF.Pick ( asof, "Date", BegOfDay ( CurrentSessionDate () ) ) );
		endif;
		periodParam = DC.GetParameter ( Params.Settings, "DateStart" );
		periodParam.Use = true;
		periodParam.Value = date;
		periodParam = DC.GetParameter ( Params.Settings, "DateEnd" );
		periodParam.Use = true;
		periodParam.Value = date;
	else
		Params.HiddenParams.Add ( "Asof" );
	endif;
	
EndProcedure 

#endif