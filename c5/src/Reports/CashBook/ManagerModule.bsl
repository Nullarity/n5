#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Events () export
	
	p = Reporter.Events ();
	p.BeforeOpen = true;
	p.OnCheck = true;
	p.AfterOutput = true;
	return p;
	
EndFunction

Procedure BeforeOpen ( Form ) export
	
	Form.GenerateOnOpen = true;
	
EndProcedure 

#endif
