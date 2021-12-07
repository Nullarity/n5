#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export
	
	hideParams ();
	
EndProcedure

Procedure hideParams ()
	
	p = DC.GetParameter ( Params.Settings, "Unregistered" );
	if ( not p.Value ) then
		list = Params.HiddenParams;
		list.Add ( "Unregistered" );
	endif;
	
EndProcedure 

#endif