#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Events () export
	
	p = Reporter.Events ();
	p.FullAccessRequest = true;
	p.OnCompose = true;
	p.OnDetail = true;
	return p;
	
EndFunction 

Function FullAccessRequest ( Params ) export
	
	return true;

EndFunction

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	UseMainAction = true;
	StandardMenu = new Array ();
	StandardMenu.Add ( DataCompositionDetailsProcessingAction.OpenValue );
	
EndProcedure

#endif