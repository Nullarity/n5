#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Function Events () export
	
	p = Reporter.Events ();
	p.OnCheck = true;
	p.OnDetail = true;
	p.OnCompose = true;
	p.OnPrepare = true;
	return p;
	
EndFunction 

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	UseMainAction = true;
	Menu = new ValueList ();
	Reporter.AddReport ( Menu, "Transactions" );
	Reporter.AddReport ( Menu, "Entries" );
	StandardMenu = getActions ();
	
EndProcedure

Function getActions ()
	
	actions = new Array ();
	actions.Add ( DataCompositionDetailsProcessingAction.OpenValue );
	return actions;
	
EndFunction 

Procedure ApplyDetails ( Composer, Params ) export
	
	Reports.BalanceSheet.ApplyDetails ( Composer, Params );
	
EndProcedure 

#endif