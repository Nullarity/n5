#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Events () export
	
	p = Reporter.Events ();
	p.BeforeOpen = true;
	p.OnCheck = true;
	p.OnDetail = true;
	return p;
	
EndFunction 

Procedure BeforeOpen ( Form ) export
	
	Form.GenerateOnOpen = true;
	
EndProcedure 

Procedure OnDetail ( Menu, StandardMenu, UseMainAction, Filters ) export
	
	Menu = new ValueList ();
	Reporter.AddReport ( Menu, "Transactions" );
	Reporter.AddReport ( Menu, "BalanceSheet" );
	Reporter.AddReport ( Menu, "AccountBalance" );
	Reporter.AddReport ( Menu, "AccountAnalysis" );
	
EndProcedure

Procedure OnScheduling ( SettingsComposer, Cancel, StandardProcessing ) export
	
	StandardProcessing = false;
	period = DC.GetParameter ( SettingsComposer, "ReportDate" );
	if ( period.Use and period.Value.Variant = StandardPeriodVariant.Custom ) then
		Output.ReportSchedulingIncorrectPeriod ();
		Cancel = true;
		return;
	endif; 
	
EndProcedure

#endif