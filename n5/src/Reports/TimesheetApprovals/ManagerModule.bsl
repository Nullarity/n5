#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

#if ( Server ) then
	
Function Events () export
	
	return Reporter.Events ();
	
EndFunction 

#endif

#endif