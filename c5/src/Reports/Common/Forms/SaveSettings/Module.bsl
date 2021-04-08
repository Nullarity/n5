// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	applyParams ();
	loadSettingsTable ();
	
EndProcedure

&AtServer
Procedure applyParams ()
	
	ReportName = Parameters.ReportName;
	SettingsAddress = Parameters.SettingsAddress;
	IsSettings = Parameters.IsSettings;
	if ( IsSettings ) then
		ReportVariant = Parameters.ReportVariant;
	endif; 
	
EndProcedure

&AtServer
Procedure loadSettingsTable ()
	
	settingsReporVariant = ? ( IsSettings, ReportVariant, undefined );
	SettingsTable.Load ( Reporter.GetUserSettings ( SessionParameters.User, ReportName, settingsReporVariant ) );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CmdSave ( Command )
	
	saveAndClose ();
	
EndProcedure

&AtClient
Procedure saveAndClose ()
	
	if ( not CheckFilling () ) then
		return;
	endif; 
	foundRows = SettingsTable.FindRows ( new Structure ( "Description", VariantDescription ) );
	if ( foundRows.Count () > 0 ) then
		Output.ReplaceReportVariant ( ThisObject, foundRows [ 0 ].Code );
	else
		Close ( getSavedSettingsItem ( undefined ) );
	endif; 
	
EndProcedure

&AtClient
Procedure ReplaceReportVariant ( Answer, Code ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		Close ( getSavedSettingsItem ( Code ) );
	endif; 
	
EndProcedure 

&AtClient
Function getSavedSettingsItem ( Code )
	
	savingParams = new Structure ();
	savingParams.Insert ( "Code", Code );
	savingParams.Insert ( "VariantDescription", VariantDescription );
	savingParams.Insert ( "ReportName", ReportName );
	savingParams.Insert ( "SettingsAddress", SettingsAddress );
	savingParams.Insert ( "IsSettings", IsSettings );
	savingParams.Insert ( "ReportVariant", ReportVariant );
	return saveSettings ( savingParams );
	
EndFunction 

&AtServerNoContext
Function saveSettings ( val SavingParams )
	
	if ( SavingParams.Code = undefined ) then
		settingsItem = Catalogs.ReportSettings.CreateItem ();
	else
		reportRef = Catalogs.ReportSettings.FindByCode ( SavingParams.Code );
		settingsItem = reportRef.GetObject ();
	endif; 
	settingsItem.User = SessionParameters.User;
	settingsItem.Description = SavingParams.VariantDescription;
	settingsItem.Report = Catalogs.Metadata.Ref ( "Report." + SavingParams.ReportName );
	settingsItem.IsSettings = SavingParams.IsSettings;
	if ( SavingParams.IsSettings ) then
		settingsItem.ReportVariant = SavingParams.ReportVariant;
	endif; 
	settingsItem.LastUpdateDate = CurrentDate ();
	settingsItem.Storage = new ValueStorage ( GetFromTempStorage ( SavingParams.SettingsAddress ), new Deflation () );
	settingsItem.Write ();
	return settingsItem.Ref;
	
EndFunction

// *****************************************
// *********** Table: SettingsTable

&AtClient
Procedure SettingsTableOnActivateRow ( Item )
	
	if ( Item.CurrentData = undefined ) then
		return;
	endif; 
	VariantDescription = Item.CurrentData.Description;
	
EndProcedure

&AtClient
Procedure SettingsTableValueChoice ( Item, Value, StandardProcessing )
	
	saveAndClose ();
	
EndProcedure
