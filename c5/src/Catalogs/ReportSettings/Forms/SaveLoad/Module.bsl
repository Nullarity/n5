
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParameters ();
	setReplacing ();
	setTitle ();
	setDefaultButton ( ThisObject );
	loadVariants ();
	initList ();
	activateRecord ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadParameters ()
	
	Report = Catalogs.Metadata.Ref ( "Report." + Parameters.Report );

EndProcedure

&AtServer
Procedure setTitle ()
	
	if ( Parameters.Settings ) then
		Title = Output.ShowingReportSettings ();
	else
		Title = Output.ShowingReportVariants ();
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setDefaultButton ( Form )
	
	if ( Form.Parameters.Saving ) then
		if ( Form.Replacing = 0 ) then
			Form.Items.FormSave.DefaultButton = true;
		else
			Form.Items.FormChoose.DefaultButton = true;
		endif;
	else
		if ( Form.Loading = 0
			and not Form.Parameters.Settings ) then
			Form.Items.FormChooseStandard.DefaultButton = true;
		else
			Form.Items.FormChoose.DefaultButton = true;
		endif;
	endif;

EndProcedure

&AtServer
Procedure loadVariants ()
	
	if ( Parameters.Saving
		or Parameters.Settings ) then
		return;
	endif;
	sysadmin = Logins.Sysadmin ();
	schema = Reporter.GetSchema ( Parameters.Report );
	for each variant in schema.SettingVariants do
		if ( sysadmin
			or not isSystemVariant ( variant ) ) then
			StandardVariants.Add ( variant.Name, variant.Presentation );
		endif; 
	enddo; 
	
EndProcedure

&AtClient
Procedure StandardVariantsValueChoice ( Item, Value, StandardProcessing )
	
	chooseStandard ();

EndProcedure

&AtClient
Procedure chooseStandard ()
	
	item = Items.StandardVariants.CurrentData;
	if ( item = undefined ) then
		return;
	endif;
	NotifyChoice ( "#" + item.Value );

EndProcedure

&AtServer
Function isSystemVariant ( Variant )
	
	return StrStartsWith ( Variant.Name, "#" );
	
EndFunction

&AtServer
Procedure initList ()
	
	DC.ChangeFilter ( List, "Report", Report, true );
	DC.ChangeFilter ( List, "IsSettings", Parameters.Settings, true );

EndProcedure

&AtServer
Procedure activateRecord ()
	
	if ( Parameters.Saving ) then
		record = Parameters.ReportSettings;
	elsif ( TypeOf ( Parameters.ReportVariant ) = Type ( "CatalogRef.ReportSettings" ) ) then
		record = Parameters.ReportVariant;
	endif;
	if ( ValueIsFilled ( record ) ) then
		Items.List.CurrentRow = record;
	endif;

EndProcedure

&AtServer
Procedure setReplacing ()
	
	if ( not Parameters.Saving ) then
		return;
	endif;
	settings = Parameters.Settings;
	if ( settings
		and ValueIsFilled ( Parameters.ReportSettings )
		or ( not settings
			and ValueIsFilled ( Parameters.ReportVariant )
			and TypeOf ( Parameters.ReportVariant  ) = Type ( "CatalogRef.ReportSettings" ) ) )
	then
		Replacing = 1;
	endif;

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|#s StandardVariants hide Parameters.Saving or Parameters.Settings;
	|StandardVariants enable Loading = 0;
	|List enable ( Replacing = 1 or Loading = 1 ) or ( Parameters.Settings and not Parameters.Saving );
	|FormChoose show ( Replacing = 1 or Loading = 1 ) or ( Parameters.Settings and not Parameters.Saving );
	|FormChooseStandard show Loading = 0 and not Parameters.Settings and not Parameters.Saving ;
	|FormSave show Parameters.Saving and Replacing = 0;
	|SavingGroup show Parameters.Saving;
	|RecordDescription enable Replacing = 0 and Parameters.Saving;
	|LoadingStandard LoadingUser hide Parameters.Saving or Parameters.Settings;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )

	if ( Parameters.Saving and Replacing = 0 ) then
		CheckedAttributes.Add ( "RecordDescripion" );
	endif;

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	setCurrentItem ();

EndProcedure

&AtClient
Procedure setCurrentItem ()
	
	if ( Parameters.Saving ) then
		if ( Replacing = 0 ) then
			CurrentItem = Items.RecordDescription;
		else
			CurrentItem = Items.List;
		endif;
	else
		if ( Loading = 0 ) then
			CurrentItem = Items.StandardVariants;
		else
			CurrentItem = Items.List;
		endif;
	endif;

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Save ( Command )
	
	if ( CheckFilling () ) then
		NotifyChoice ( saveData ( ? ( Replacing = 0, undefined, Items.List.CurrentData ) ) );
	endif;
	
EndProcedure

&AtServer
Function saveData ( val Ref )
	
	if ( Replacing = 0 ) then
		obj = Catalogs.ReportSettings.CreateItem ();
		obj.Description = RecordDescription;
		obj.User = SessionParameters.User;
		obj.Report = Report;
	else
		obj = Ref.GetObject ();
	endif; 
	obj.IsSettings = Parameters.Settings;
	obj.LastUpdateDate = CurrentSessionDate ();
	obj.Storage = new ValueStorage ( GetFromTempStorage ( Parameters.SettingsAddress ), new Deflation () );
	obj.Write ();
	return obj.Ref;

EndFunction

&AtClient
Procedure SavingVariantOnChange ( Item )
	
	applySavingVariant (); 
	
EndProcedure

&AtClient
Procedure applySavingVariant ()
	
	setDefaultButton ( ThisObject );
	Appearance.Apply ( ThisObject, "Replacing" );
	setCurrentItem ();

EndProcedure

&AtClient
Procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	if ( Parameters.Saving ) then
		saveData ( Value );
	endif;

EndProcedure

&AtClient
Procedure LoadingStandardOnChange ( Item )
	
	applyLoadingVariant ();

EndProcedure

&AtClient
Procedure applyLoadingVariant ()
	
	setDefaultButton ( ThisObject );
	Appearance.Apply ( ThisObject, "Loading" );
	setCurrentItem ();

EndProcedure