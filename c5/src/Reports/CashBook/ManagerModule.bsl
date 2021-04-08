#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Events () export
	
	p = Reporter.Events ();
	p.OnCheck = true;
	p.AfterOutput = true;
	return p;
	
EndFunction

#endif
