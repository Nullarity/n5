#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Events () export
	
	p = Reporter.Events ();
	p.BeforeOpen = true;
	p.OnDetail = true;
	p.FullAccessRequest = true;
	return p;
	
EndFunction 

Function FullAccessRequest ( Params ) export

	return true;

EndFunction

Procedure BeforeOpen ( Form ) export
	
	Form.GenerateOnOpen = true;
	
EndProcedure 

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	UseMainAction = true;
	
EndProcedure

#endif
