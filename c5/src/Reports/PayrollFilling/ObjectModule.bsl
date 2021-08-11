#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var Data;
var InHandQuery;
var ResultQuery;

Procedure OnCompose () export	
	
	setPeriod ();
	
EndProcedure

Procedure setPeriod ()
	
	settings = Params.Settings;
	paymentDate = DC.GetParameter ( settings, "PayDay" ).Value;
	if ( paymentDate = undefined ) then
		date = DC.GetParameter ( settings, "Period" ).Value.EndDate;
	else
		date = DF.Pick ( paymentDate, "Date" );
	endif;
	DC.SetParameter ( settings, "PaymentDate", BegOfDay ( date ) );
	DC.SetParameter ( settings, "YearStart", BegOfYear ( date ) );
	
EndProcedure 

Procedure OnPrepare ( Template ) export
	
	extractQueries ( Template );
	
EndProcedure 

Procedure extractQueries ( Template )
	
	dataSets = Template.DataSets;
	InHandQuery = dataSets.InHand.Query;
	ResultQuery = dataSets.Result.Query;
	
EndProcedure

Procedure AfterOutput () export

	if ( Params.Variant = "#Fill" ) then
		setResult ();
	endif;
	
EndProcedure

Procedure setResult ()

	result = new Structure ( "Compensations, Taxes, Base" );
	Data = Params.Result;
	last = Data.Ubound ();
	result.Base = Data [ last - 1 ].Unload ();
	salaryInHand = not Data [ last ].IsEmpty ();
	if ( salaryInHand ) then
		run ( InHandQuery );
	endif;
	run ( ResultQuery );
	last = data.Ubound ();
	result.Compensations = Data [ last ].Unload ();
	result.Taxes = Data [ last - 1 ].Unload ();
	Params.Result = result;

EndProcedure

Procedure run ( Query )
	
	q = Params.BatchQuery;
	q.Text = Query;
	CoreLibrary.AdjustQuery ( q );
	Data = q.ExecuteBatch ();
	
EndProcedure

#endif