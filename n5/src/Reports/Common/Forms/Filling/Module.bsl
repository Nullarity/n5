&AtServer
var Presentation;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	loadParams ();
	init ();
	fetchHiddenSettings ();
	hideSettings ();
	setTitle ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ClearTable show ProposeClearing
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParams ()
	
	filling = Parameters.Filling;
	Report = filling.Report;
	Variant = filling.Variant;
	Background = filling.Background;
	Batch = filling.Batch;
	ProposeClearing = filling.ProposeClearing;
	CloseOnErrors = filling.CloseOnErrors;
	ClearTable = filling.ClearTable;
	
EndProcedure

&AtServer
Procedure init ()
	
	SetPrivilegedMode ( true );
	schema = Reporter.GetSchema ( Report );
	SetPrivilegedMode ( false );
	SchemaAddress = PutToTempStorage ( schema, SchemaAddress );
	Composer.Initialize ( new DataCompositionAvailableSettingsSource ( SchemaAddress ) );
	Composer.LoadSettings ( schema.SettingVariants [ Variant ].Settings );
	Presentation = schema.SettingVariants [ Variant ].Presentation;
	ResultAddress = PutToTempStorage ( new ValueTable (), Parameters.Caller );
	Reporter.ApplyFilters ( Composer, Parameters.Filling );

EndProcedure 

&AtServer
Procedure fetchHiddenSettings ()

	filters = undefined;
	Parameters.Filling.Property ( "Filters", filters );
	if ( filters = undefined ) then
		return;
	endif;
	settings = Composer.Settings;
	for each filter in filters do
		if ( not filter.Hide ) then
			continue;
		endif;
		if ( filter.Property ( "Parameter" ) ) then
			name = "" + filter.Parameter;
			item = DC.GetParameter ( Composer, name );
			fields = "Use, Value";
		else
			name = "" + filter.LeftValue;
			item = DC.FindFilter ( Composer, name );
			fields = "Use, ComparisonType, RightValue";
		endif; 
		source = DC.FindSetting ( settings, name );
		FillPropertyValues ( source, item, fields );
		HiddenSettings.Add ( name, item.UserSettingID );
	enddo; 

EndProcedure

&AtServer
Procedure hideSettings ()

	settings = Composer.Settings;
	for each setting in HiddenSettings do
		DC.FindSetting ( settings, setting.Value ).UserSettingID = "";
	enddo;

EndProcedure

&AtServer
Procedure setTitle ()
	
	Title = Presentation;

EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	Caller = FormOwner.UUID;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Fill ( Command )
	
	perform ( Background );
	if ( Background ) then
		Progress.Open ( UUID, FormOwner, new NotifyDescription ( "Complete", ThisObject ) );
	else
		Close ( getResult ( true ) );
	endif; 
	
EndProcedure

&AtServer
Procedure perform ( Background )
	
	schema = GetFromTempStorage ( SchemaAddress );
	args = new Array ();
	args.Add ( Report );
	args.Add ( Variant );
	args.Add ( getSettings () );
	args.Add ( schema );
	args.Add ( ResultAddress );
	args.Add ( Batch );
	args.Add ( ClearTable );
	Jobs.Run ( "FillerSrv.Perform", args, UUID, , not Background or TesterCache.Testing () );

EndProcedure

&AtServer
Function getSettings ()

	loadHiddenSettings ();
	settings = Composer.GetSettings ();
	hideSettings ();
	FillerSrv.ExtractTables ( settings );
	return settings;

EndFunction

&AtServer
Procedure loadHiddenSettings ()

	settings = Composer.Settings;
	for each setting in HiddenSettings do
		DC.FindSetting ( settings, setting.Value ).UserSettingID = setting.Presentation;
	enddo;

EndProcedure

&AtClient
Procedure Complete ( Completed, Params ) export
	
	if ( Completed or CloseOnErrors ) then
		Close ( getResult ( Completed ) );
	endif; 
	
EndProcedure 

&AtClient
Function getResult ( Completed )
	
	result = Filler.Result ();
	result.ClearTable = ClearTable;
	result.Address = ResultAddress;
	result.Completed = Completed;
	return result;
	
EndFunction 

&AtClient
Procedure MarkAll ( Command )
	
	mark ( true );
	
EndProcedure

&AtClient
Procedure UnmarkAll ( Command )
	
	mark ( false );
	
EndProcedure

&AtClient
Procedure mark ( Flag )
	
	for each item in Composer.UserSettings.Items do
		if ( TypeOf ( item ) = Type ( "DataCompositionFilterItem" )
			or TypeOf ( item ) = Type ( "DataCompositionSettingsParameterValue" ) )
			and ( item.ViewMode = DataCompositionSettingsItemViewMode.QuickAccess ) then
			item.Use = Flag;
		endif; 
	enddo; 
	
EndProcedure

&AtClient
Procedure OpenSettings ( Command )
	
	Items.UserSettingsCmdOpenSettings.Check = not Items.UserSettingsCmdOpenSettings.Check;
	//@skip-warning
	Items.UserSettings.ViewMode = ? ( Items.UserSettingsCmdOpenSettings.Check, DataCompositionSettingsViewMode.All, DataCompositionSettingsViewMode.QuickAccess );
	
EndProcedure
