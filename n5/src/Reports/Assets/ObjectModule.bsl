#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export
	
	hideParams ();
	
EndProcedure

Procedure hideParams ()
	
	list = Params.HiddenParams;
	list.Add ( "FixTable" );
	
EndProcedure 

Procedure AfterOutput () export
	
	fixTable = DC.GetParameter ( Params.Settings, "FixTable" ).Value;
	if ( fixTable ) then
		fixLeft ();
	endif;

EndProcedure

Procedure fixLeft ()
	
	Params.Result.FixedLeft = 2;
	
EndProcedure 

#endif