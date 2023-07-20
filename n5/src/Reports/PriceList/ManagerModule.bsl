#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Function Events () export
	
	p = Reporter.Events ();
	p.BeforeOpen = true;
	p.OnCheck = true;
	p.OnCompose = true;
	p.OnPrepare = true;
	return p;
	
EndFunction 

Procedure BeforeOpen ( Form ) export
	
	Form.GenerateOnOpen = shortList ();
	
EndProcedure

Function shortList ()
	
	s = "
	|select count ( Items.Ref )
	|from Catalog.Items as Items
	|where not Items.DeletionMark
	|having count ( Items.Ref ) > &Limit
	|";
	q = new Query ( s );
	q.SetParameter ( "Limit", Enum.PriceListLimit () );
	return q.Execute ().IsEmpty ();
	
EndFunction 

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