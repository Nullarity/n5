// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setLanguages ();
	restoreChoice ();
	
EndProcedure

&AtServer
Procedure setLanguages ()

	myLanguage = CurrentLanguage ().LanguageCode;
	list = Items.Language.ChoiceList;
	supported = Conversion.StringToArray ( Parameters.Languages );
	myLanguageInList = false;
	for each code in supported do
		value = Enums.PrintLanguages [ code ];
		list.Add ( value );
		if ( code = myLanguage ) then
			myLanguageInList = true;
		endif;
	enddo;		
	if ( myLanguageInList ) then
		list.Insert ( 0, Enums.PrintLanguages.Default );
		Language = Enums.PrintLanguages.Default;
	else
		Language = list [ 0 ].Value;
	endif;
	
EndProcedure

&AtServer
Procedure restoreChoice ()
	
	value = CommonSettingsStorage.Load ( settingID () );
	if ( Items.Language.ChoiceList.FindByValue ( value ) <> undefined ) then
		Language = value;
	endif;
	
EndProcedure

&AtServer
Function settingID ()
	
	return Enum.SettingsPrintFormLanguage () + "_" + Conversion.EnumItemToName ( Parameters.Form );
	
EndFunction

// *****************************************
// *********** Form

&AtClient
Procedure LanguageClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure OK ( Command )
	
	code = applyChoice ();
	Close ( code );
	
EndProcedure

&AtServer
Function applyChoice ()
	
	if ( MakeDefault ) then
		saveLanguage ();
	endif;
	saveChoice ();
	return languageCode ();
	
EndFunction

&AtServer
Procedure saveLanguage ()
	
	obj = Logins.Settings ( "Ref" ).Ref.GetObject ();
	table = obj.Print;
	form = Enums.PrintForms [ Parameters.Form ];
	row = table.Find ( form, "Form" );
	if ( row = undefined ) then
		row = table.Add ();
		row.Form = form;
	endif;
	row.Language = Language;
	obj.Write ();
	
EndProcedure

&AtServer
Procedure saveChoice ()
	
	LoginsSrv.SaveSettings ( settingID (), , Language );
	
EndProcedure

&AtServer
Function languageCode ()
	
	if ( Language = PredefinedValue ( "Enum.PrintLanguages.Default" ) ) then
		return CurrentLanguage ().LanguageCode;
	else
		return Lower ( Conversion.EnumItemToName ( Language ) );
	endif;
	
EndFunction
