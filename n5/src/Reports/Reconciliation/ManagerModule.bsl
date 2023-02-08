#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Events () export
	
	p = Reporter.Events ();
	p.BeforeOpen = true;
	p.OnCheck = true;
	p.AfterOutput = true;
	return p;
	
EndFunction

Procedure BeforeOpen ( Form ) export
	
	init ( Form );
	
EndProcedure 

Procedure init ( Form )
	
	settings = Form.Object.SettingsComposer;
	filter = DC.GetParameter ( settings, "Language" );
	if ( not ValueIsFilled ( filter.Value ) ) then
		filter.Value = Enums.Languages [ CurrentLanguage ().LanguageCode ];
	endif;

EndProcedure

#endif