
&AtClient
Procedure CommandProcessing ( Reference, ExecuteParameters )
	
	p = ReportsSystem.GetParams ( "Fuel" );
	filters = new Array ();
	filters.Add ( DC.CreateParameter ( "ShowRecorders", true ) );
	if ( TypeOf ( Reference ) = Type ( "DocumentRef.Waybill" ) ) then
		data = DF.Values ( Reference, "DateOpening, Date, Car" );
		filters.Add ( DC.CreateFilter ( "Car", data.Car ) );
		period = DC.CreateParameter ( "Period",
			new StandardPeriod ( data.DateOpening, EndOfDay ( data.Date ) ) );
		filters.Add ( period );
	else
		filters.Add ( DC.CreateFilter ( "Car", Reference ) );
	endif;
	p.Filters = filters;
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, ExecuteParameters.Source, true, ExecuteParameters.Window );
	
EndProcedure
