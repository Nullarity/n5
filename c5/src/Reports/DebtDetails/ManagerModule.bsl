#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Events () export
	
	p = Reporter.Events ();
	p.OnDetail = true;
	return p;
	
EndFunction 

Procedure ApplyDetails ( Composer, Params ) export
	
	parent = Params.Parent;
	if ( parent = "Debts"
		or parent = "VendorDebts" ) then
		filters = GetFromTempStorage ( Params.Filters );
		for each filter in filters do
			if ( filter.Name = "ReportDate" ) then
				Reporter.DateToPeriod ( Composer, filter );
				break;
			endif; 
		enddo; 
		DCsrv.GetGroup ( Composer, "Document", true ).Use = true;
	endif;
	Reporter.ApplyDetails ( Composer, filters );
	
EndProcedure 

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	Menu = new ValueList ();
	Reporter.AddReport ( Menu, "AnalyticTransactions" );
	Reporter.AddReport ( Menu, "BalanceSheet" );
	
EndProcedure

#endif