#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

#if ( Server ) then
	
Function Events () export
	
	p = Reporter.Events ();
	p.OnCompose = true;
	return p;
	
EndFunction 

#endif

#endif