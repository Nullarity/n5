#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Function Events () export
	
	p = Reporter.Events ();
	p.FullAccessRequest = true;
	return p;
	
EndFunction 

Function FullAccessRequest ( Params ) export
	
	return true;

EndFunction

#endif