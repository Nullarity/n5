// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setTitle ();
	loadSettings ();
	setSettingsTableCurrentRow ();
	
EndProcedure

&AtServer
Procedure setTitle ()
	
	if ( Parameters.IsSettings ) then
		Title = Output.LoadReportSettings ();
	else
		Title = Output.LoadReportVariant ();
	endif; 
	
EndProcedure 

&AtServer
Procedure loadSettings ()
	
	if ( Parameters.IsSettings ) then
		loadUserSettings ();
	else
		loadVariants ();
	endif; 
	
EndProcedure 

&AtServer
Procedure loadUserSettings ()
	
	CollectionsSrv.Join ( SettingsTable, Reporter.GetUserSettings ( SessionParameters.User, Parameters.ReportName, Parameters.ReportVariant ) );
		
EndProcedure

&AtServer
Procedure loadVariants ()
	
	dataSchema = Reporter.GetSchema ( Parameters.ReportName );
	detectSystemVariants = ( dataSchema.SettingVariants.Count () > 1 );
	system = IsInRole ( "AdministratorSystem" );
	for each variant in dataSchema.SettingVariants do
		if ( detectSystemVariants
			and not system
			and isSystemVariant ( variant ) ) then
			continue;
		endif; 
		rowVariant = SettingsTable.Add ();
		rowVariant.Code = "#" + variant.Name;
		rowVariant.Description = variant.Presentation;
	enddo; 
	CollectionsSrv.Join ( SettingsTable, Reporter.GetVariants ( SessionParameters.User, Parameters.ReportName ) );
	
EndProcedure

&AtServer
Function isSystemVariant ( Variant )
	
	return StrStartsWith ( Variant.Name, "#" );
	
EndFunction

&AtServer
Procedure setSettingsTableCurrentRow ()
	
	currentSettings = ? ( Parameters.IsSettings, Parameters.CurrentSettings, Parameters.ReportVariant );
	columnID = ? ( TypeOf ( currentSettings ) = Type ( "CatalogRef.ReportSettings" ), "Ref", "Code" );
	for each row in SettingsTable do
		if ( row [ columnID ] = currentSettings ) then
			Items.SettingsTable.CurrentRow = SettingsTable.IndexOf ( row );
			break;
		endif; 
	enddo; 

EndProcedure

// *****************************************
// *********** Table: SettingsTable

&AtClient
Procedure SettingsTableValueChoice ( Item, Value, StandardProcessing )

	Close ( Item.CurrentData.Code );
	
EndProcedure
