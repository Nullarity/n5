#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Events () export
	
	p = Reporter.Events ();
	p.BeforeOpen = true;
	p.OnPrepare = true;
	p.OnDetail = true;
	p.AfterOutput = true;
	return p;
	
EndFunction 

Procedure BeforeOpen ( Form ) export
	
	Form.GenerateOnOpen = true;
	
EndProcedure

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	UseMainAction = true;
	
EndProcedure

#endif