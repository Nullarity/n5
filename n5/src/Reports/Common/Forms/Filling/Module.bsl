&AtServer
var Presentation;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	loadParams ();
	init ();
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
	ClearTable = true;
	Reporter.ApplyFilters ( Composer, Parameters.Filling );

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
	
	perform ();
	if ( Background ) then
		Progress.Open ( UUID, ThisObject, new NotifyDescription ( "Complete", ThisObject ) );
	else
		Close ( getResult () );
	endif; 
	
EndProcedure

&AtServer
Procedure perform ()
	
	schema = GetFromTempStorage ( SchemaAddress );
	args = new Array ();
	args.Add ( Report );
	args.Add ( Variant );
	settings = Composer.GetSettings ();
	FillerSrv.ExtractTables ( settings );
	args.Add ( settings );
	args.Add ( schema );
	args.Add ( ResultAddress );
	args.Add ( Batch );
	Jobs.Run ( "FillerSrv.Perform", args, UUID, , TesterCache.Testing () );

EndProcedure

&AtClient
Procedure Complete ( Completed, Params ) export
	
	if ( Completed ) then
		Close ( getResult () );
	endif; 
	
EndProcedure 

&AtClient
Function getResult ()
	
	result = Filler.Result ();
	result.ClearTable = ClearTable;
	result.Address = ResultAddress;
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
