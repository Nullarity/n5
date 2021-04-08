#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export	
	
	setPeriod ();
	verticalTotal ();
	horizontalTotal ();
	
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

Procedure verticalTotal ()
	
	costField = DCsrv.GetField ( Params.Settings.Selection, "Cost" );
	if ( costField = undefined ) then
		placement = DataCompositionTotalPlacement.None;
	else
		placement = ? ( costField.Use, DataCompositionTotalPlacement.Auto, DataCompositionTotalPlacement.None );
	endif; 
	Params.Settings.OutputParameters.SetParameterValue ( "VerticalOverallPlacement", placement );
	
EndProcedure 

Procedure horizontalTotal ()
	
	total = DC.FindParameter ( Params.Settings, "ShowTotal" );
	tableType = Type ( "DataCompositionTable" );
	for each item in Params.Settings.Structure do
		if ( TypeOf ( item ) = tableType
			and item.Name = "Table" ) then
			overall = item.OutputParameters.Items.Find ( "HorizontalOverallPlacement" );
			overall.Use = true;
			if ( total.Use and total.Value ) then
				overall.Value = DataCompositionTotalPlacement.Auto;
			else
				overall.Value = DataCompositionTotalPlacement.None;
			endif; 
		endif; 
	enddo; 
	total.Use = false;
	
EndProcedure 

#endif