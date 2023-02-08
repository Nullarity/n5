#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export
	
	hideParams ();
	titleReport ();
	
EndProcedure

Procedure hideParams ()
	
	list = Params.HiddenParams;
	list.Add ( "Period" );
	list.Add ( "Account" );
	
EndProcedure 

Procedure titleReport ()
	
	period = DC.FindParameter ( Params.Composer, "Period" );
	account = DC.FindParameter ( Params.Settings, "Account" ).Value;
	Reports.BalanceSheet.SetTitle ( Params, period, account );

EndProcedure 

#endif