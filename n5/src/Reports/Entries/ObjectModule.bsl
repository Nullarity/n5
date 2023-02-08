#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var AccountFilter;

Procedure OnCheck ( Cancel ) export
	
	getAccount ();
	if ( not checkAccount () ) then
		Cancel = true;
	endif; 
	
EndProcedure 

Procedure getAccount ()
	
	filter = DC.FindParameter ( Params.Composer, "Account" );
	AccountFilter = filter.Value;
	
EndProcedure 

Function checkAccount ()
	
	if ( ValueIsFilled ( AccountFilter ) ) then
		return true;
	endif;
	Output.FieldIsEmpty ( new Structure ( "Field", Params.Schema.Parameters.Account.Title ) );
	return false;

EndFunction 

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