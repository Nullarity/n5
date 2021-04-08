#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Events () export
	
	return Reporter.Events ();
	
EndFunction 

#endif