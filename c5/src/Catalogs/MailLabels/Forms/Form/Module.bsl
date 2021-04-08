// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	initSettingsComposer ();
	loadFilters ( CurrentObject.Filter );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure initSettingsComposer ()
	
	dataSchema = getTemplate ();
	SchemaAddress = PutToTempStorage ( dataSchema, UUID );
	SettingsComposer.Initialize ( new DataCompositionAvailableSettingsSource ( SchemaAddress ) );
	variant = dataSchema.SettingVariants.Default.Settings;
	SettingsComposer.LoadSettings ( variant );
	SettingsComposer.Refresh ();
	
EndProcedure 

&AtServer
Function getTemplate ()
	
	if ( Object.LabelType = Enums.LabelTypes.Incoming ) then
		return Catalogs.MailLabels.GetTemplate ( "IncomingEmails" );
	else
		return Catalogs.MailLabels.GetTemplate ( "OutgoingEmails" );
	endif; 
	
EndFunction 

&AtServer
Procedure loadFilters ( Filter )
	
	filters = Filter.Get ();
	if ( filters = undefined ) then
		return;
	endif; 
	SettingsComposer.LoadUserSettings ( filters );
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		setUser ();
		initSettingsComposer ();
		if ( not Parameters.CopyingValue.IsEmpty () ) then
			Object.System = false;
			loadFilters ( Parameters.CopyingValue.Filter );
		endif; 
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );
	setDefaultButton ();
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|LabelType Owner lock filled ( Object.Ref );
	|SettingsComposerUserSettings Parent lock ( Object.System or Object.LabelType = Enum.LabelTypes.IMAP );
	|LabelType show not inlist ( Object.LabelType, Enum.LabelTypes.Trash, Enum.LabelTypes.IMAP );
	|FormWriteAndClose show ( Object.System or Object.LabelType = Enum.LabelTypes.IMAP );
	|FormApply show not Object.System and Object.LabelType <> Enum.LabelTypes.IMAP;
	|Code show Object.LabelType <> Enum.LabelTypes.IMAP
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setUser ()
	
	Object.User = SessionParameters.User;
	
EndProcedure 

&AtServer
Procedure setDefaultButton ()
	
	if ( Items.FormWriteAndClose.Visible ) then
		Items.FormWriteAndClose.DefaultButton = true;
	elsif ( Items.FormApply.Visible ) then
		Items.FormApply.DefaultButton = true;
	endif; 
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	saveSettings ( CurrentObject );

EndProcedure
	
&AtServer
Procedure saveSettings ( CurrentObject )
	
	if ( not Object.System and settingsExist ( SettingsComposer.UserSettings ) ) then
		filterByMailbox ();
		CurrentObject.Filter = new ValueStorage ( SettingsComposer.UserSettings, new Deflation () );
	else
		CurrentObject.Filter = undefined;
	endif; 
	
EndProcedure 

&AtServer
Function settingsExist ( Settings )
	
	filterItemType = Type ( "DataCompositionFilterItem" );
	filterGroupType = Type ( "DataCompositionFilterItemGroup" );
	filterType = Type ( "DataCompositionFilter" );
	for each item in Settings.Items do
		itemType = TypeOf ( item );
		if ( itemType = filterType ) then
			return settingsExist ( item );
		elsif ( itemType = filterGroupType ) then
			if ( item.Use ) then
				return settingsExist ( item );
			endif; 
		elsif ( itemType = filterItemType ) then
			if ( item.Use ) then
				return true;
			endif; 
		endif; 
	enddo; 
	return false;
	
EndFunction 

&AtServer
Procedure filterByMailbox ()
	
	DC.ChangeFilter ( SettingsComposer.Settings, "Mailbox", Object.Owner, true );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure LabelTypeOnChange ( Item )
	
	initSettingsComposer ();
	
EndProcedure

&AtClient
Procedure Apply ( Command )
	
	if ( not Write () ) then
		return;
	endif; 
	startJob ();

EndProcedure

&AtClient
Procedure startJob ()
	
	jobKey = "SendEmail" + UserName ();
	startAttaching ( Object.Ref, Object.LabelType, jobKey );
	Progress.Open ( jobKey, ThisObject, new NotifyDescription ( "LabelWasApplied", ThisObject ) );
	
EndProcedure 

&AtServerNoContext
Procedure startAttaching ( val Label, val LabelType, val JobKey )
	
	p = new Array ();
	p.Add ( Label );
	p.Add ( LabelType );
	p.Add ( DF.Pick ( Label, "Filter" ).Get () );
	Jobs.Run ( "MailboxesSrv.AttachMails", p, JobKey );
	////MailboxesSrv.AttachMails ( Label, LabelType, DF.Pick ( Label, "Filter" ).Get () );
	
EndProcedure 

&AtClient
Procedure LabelWasApplied ( Result, Params ) export
	
	if ( Object.LabelType = PredefinedValue ( "Enum.LabelTypes.Incoming" ) ) then
		NotifyChanged ( Type ( "DocumentRef.IncomingEmail" ) );
	else
		NotifyChanged ( Type ( "DocumentRef.OutgoingEmail" ) );
	endif; 
	Notify ( Enum.MessageMailLabelChanged (), Object.Ref );
	Close ();
	
EndProcedure 
