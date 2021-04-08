#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

	
Function Events () export
	
	p = Reporter.Events ();
	p.BeforeOpen = true;
	return p;
	
EndFunction 

Procedure BeforeOpen ( Form ) export
	
	Form.GenerateOnOpen = true;
	
EndProcedure 

#endif