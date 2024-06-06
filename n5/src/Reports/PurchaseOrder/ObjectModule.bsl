#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export
	
	hideParams ();
	
EndProcedure

Procedure hideParams ()
	
	list = Params.HiddenParams;
	list.Add ( "Ref" );
	
EndProcedure 

#endif