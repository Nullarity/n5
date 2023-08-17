#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export
	
	hideParams ();
	addRecorders ();
	
EndProcedure

Procedure hideParams ()
	
	list = Params.HiddenParams;
	list.Add ( "ShowRecorders" );
	
EndProcedure 

Procedure addRecorders ()
	
	p = DC.GetParameter ( Params.Settings, "ShowRecorders" );
	showRecorders = p.Use and p.Value;
	group = DCsrv.GetGroup ( Params.Settings, "Recorders" );
	group.Use = showRecorders;

EndProcedure

#endif