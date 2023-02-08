#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Events () export
	
	p = Reporter.Events ();
	p.AfterOutput = true;
	return p;
	
EndFunction 

#endif