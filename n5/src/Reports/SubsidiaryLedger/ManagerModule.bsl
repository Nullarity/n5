#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Function Events () export
	
	p = Reporter.Events ();
	p.OnDetail = true;
	p.OnCompose = true;
	return p;
	
EndFunction 

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	UseMainAction = true;
	Menu = new ValueList ();
	Reporter.AddReport ( Menu, "Transactions" );
	Reporter.AddReport ( Menu, "Entries" );
	Reporter.AddReport ( Menu, "AccountTurnovers" );
	
EndProcedure

Procedure ApplyDetails ( Composer, Params ) export
	
	Reports.BalanceSheet.ApplyDetails ( Composer, Params );
	
EndProcedure 

#endif