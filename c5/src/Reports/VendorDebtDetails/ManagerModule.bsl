#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Function Events () export
	
	p = Reporter.Events ();
	p.OnDetail = true;
	return p;
	
EndFunction 

Procedure ApplyDetails ( Composer, Params ) export
	
	Reports.DebtDetails.ApplyDetails ( Composer, Params );
	
EndProcedure 

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	Menu = new ValueList ();
	Reporter.AddReport ( Menu, "AnalyticTransactions" );
	Reporter.AddReport ( Menu, "BalanceSheet" );
	
EndProcedure

#endif