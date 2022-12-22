#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure OnCompose () export
	
	Reporter.AdjustGroupping ( ThisObject, "Item" );
	
EndProcedure

#endif