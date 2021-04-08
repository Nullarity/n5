#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var DebtsOnDate;

Procedure OnCompose () export
	
	hideParams ();
	enablePeriods ();
	setPeriod ();
	filterPaymentPeriods ();
	filterByCurrency ();
	
EndProcedure

Procedure hideParams ()
	
	list = Params.HiddenParams;
	list.Add ( "PeriodFactor" );
	list.Add ( "PeriodsBorder" );
	
EndProcedure 

Procedure enablePeriods ()
	
	settings = Params.Settings;
	p = DC.GetParameter ( settings, "PeriodsBorder" );
	p.Use = true;
	p = DC.GetParameter ( settings, "PeriodFactor" );
	p.Use = true;
	
EndProcedure

Procedure setPeriod ()
	
	settings = Params.Settings;
	reportDate = DC.GetParameter ( settings, "ReportDate" );
	asof = DC.GetParameter ( settings, "Asof" );
	calendarDate = reportDate.Value;
	date = DF.Pick ( calendarDate, "Date", BegOfDay ( CurrentSessionDate () ) );
	if ( calendarDate.IsEmpty () ) then
		reportDate.Value = Catalogs.Calendar.GetDate ( date );
	endif;
	asof.Value = EndOfDay ( date ) + 1;
	DC.SetParameter ( settings, "DebtsOnDate", date );
	DebtsOnDate = date;
	
EndProcedure

Procedure filterPaymentPeriods ()
	
	settings = Params.Settings;
	date = DC.GetParameter ( settings, "PaymentDatePeriod" );
	group = DCsrv.GetGroup ( settings, "TotalPayment" );
	if ( date.Use ) then
		dateStart = Max ( date.Value.StartDate, DebtsOnDate );
		dateEnd = date.Value.EndDate;
	else
		dateStart = DebtsOnDate;
		dateEnd = Date ( 3999, 12, 31 );
	endif; 
	if ( group <> undefined ) then
		DC.DeleteFilter ( group, "PaymentDate" );
		DC.DeleteFilter ( group, "PaymentBalance" );
		DC.AddFilter ( group, "PaymentDate", dateStart, DataCompositionComparisonType.GreaterOrEqual );
		DC.AddFilter ( group, "PaymentDate", dateEnd, DataCompositionComparisonType.LessOrEqual );
		DC.SetFilter ( group, "PaymentBalance", 0, DataCompositionComparisonType.Greater );
	endif; 
	
EndProcedure

Procedure filterByCurrency ()
	
	settings = Params.Settings;
	currency = DC.FindFilter ( settings, "Currency" );
	if ( not currency.Use
		or currency.RightValue.IsEmpty () ) then
		DC.SetFilter ( settings, "Currency", Application.Currency () );
	endif;
	
EndProcedure

#endif