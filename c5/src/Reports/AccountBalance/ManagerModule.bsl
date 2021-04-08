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
	StandardMenu = getActions ();
	
EndProcedure

Function getActions ()
	
	actions = new Array ();
	actions.Add ( DataCompositionDetailsProcessingAction.OpenValue );
	return actions;
	
EndFunction 

Procedure ApplyDetails ( Composer, Params ) export
	
	enableRecorders ( Composer );
	Reports.BalanceSheet.ApplyDetails ( Composer, Params );

EndProcedure 

Procedure enableRecorders ( Composer )
	
	DC.SetParameter ( Composer, "ShowRecorders", true, true );
	
EndProcedure 

#endif