#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Function Events () export
	
	p = Reporter.Events ();
	p.BeforeOpen = true;
	return p;
	
EndFunction 

Procedure BeforeOpen ( Form ) export
	
	Form.GenerateOnOpen = true;
	composer = Form.Object.SettingsComposer;
	warehouse = DC.FindFilter ( composer, "Warehouse" ).RightValue;
	if ( ValueIsFilled ( warehouse ) ) then
		return;
	endif;
	warehouse = Logins.Settings ( "Warehouse" ).Warehouse;
	if ( warehouse.IsEmpty () ) then
		Form.GenerateOnOpen = false;
		return;
	endif;
	DC.SetFilter ( composer, "Warehouse", warehouse );
	
EndProcedure

#endif