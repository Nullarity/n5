#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Function Events () export
	
	p = Reporter.Events ();
	p.OnCheck = true;
	p.OnDetail = true;
	p.OnCompose = true;
	return p;
	
EndFunction 

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	Menu = new ValueList ();
	Reporter.AddReport ( Menu, "Transactions" );
	Reporter.AddReport ( Menu, "Entries" );
	Reporter.DisableMenu ( StandardMenu );
	
EndProcedure

Procedure ApplyDetails ( Composer, Params ) export
	
	Reports.BalanceSheet.ApplyDetails ( Composer, Params );
	
EndProcedure 

#endif