#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

	
Function Events () export
	
	p = Reporter.Events ();
	p.OnDetail = true;
	return p;
	
EndFunction 

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	UseMainAction = true;
	
EndProcedure

#endif