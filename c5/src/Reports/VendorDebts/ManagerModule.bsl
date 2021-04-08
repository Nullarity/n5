#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Events () export
	
	p = Reporter.Events ();
	p.BeforeOpen = true;
	p.OnCompose = true;
	p.OnDetail = true;
	return p;
	
EndFunction 

Procedure BeforeOpen ( Form ) export
	
	Form.GenerateOnOpen = true;
	
EndProcedure 

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	Menu = new ValueList ();
	Reporter.AddReport ( Menu, "VendorDebtDetails" );
	Reporter.AddReport ( Menu, "AnalyticTransactions" );
	Reporter.AddReport ( Menu, "BalanceSheet" );
	
EndProcedure

#endif