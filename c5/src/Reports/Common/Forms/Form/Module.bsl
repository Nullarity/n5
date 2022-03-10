&AtServer
var GenerateOnOpen export;
&AtClient
var SelectedVariant;
&AtClient
var ChoiceForm;
&AtClient
var PreviousArea;
&AtClient
var WorkAroundSelectedActionParameters;
&AtClient
var WorkAroundDetails;
&AtClient
var TotalsEnv;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( not checkParameters () ) then
		Cancel = true;
		return;
	endif; 
	init ();
	applyParams ();
	events = reportManager ().Events ();
	if ( events.FullAccessRequest ) then
		SetPrivilegedMode ( reportManager ().FullAccessRequest ( ThisObject ) );
	endif;
	initComposer ();
	command = Parameters.Command;
	if ( command = "OpenReport" ) then
		openReport ();
	elsif ( command = "DrillDown" ) then
		drillDown ();
	elsif ( command = "Detail" ) then
		detail ();
	elsif ( command = "NewWindow" ) then
		openReportForNewWindow ();
	endif; 
	showStatus ();
	restoreSettingsButton ();
	WindowOptionsKey = Parameters.ReportName;
	afterLoadSettings ();
	if ( events.BeforeOpen
		and command = "OpenReport" ) then
		reportManager ().BeforeOpen ( ThisObject );
	endif;
	if ( GenerateOnOpen ) then
		makeReport ( false );
	endif; 
	setReportTitle ( ThisObject );
	setCurrentItem ();
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|GroupUserSettings show ShowSettings;
	|GroupQuickSettings show not ShowSettings;
	|CmdOpenSettings press ShowSettings;
	|ShowGrid press ShowGrid;
	|ShowHeaders press ShowHeaders;
	|ShowGrid ShowHeaders show not WebClient
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Function checkParameters ()

	if ( not Parameters.Property ( "Command" ) ) then
		Output.CommonReportOpenError ();
		return false;
	endif; 
	return true;
	
EndFunction

&AtServer
Procedure init ()
	
	WebClient = Environment.WebClient ();
	OneCompany = oneCompany ();
	
EndProcedure 

&AtServer
Function oneCompany ()
	
	s = "
	|select allowed Companies.Ref
	|from Catalog.Companies as Companies
	|where not Companies.DeletionMark
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	return table.Count () = 1;
	
EndFunction 

&AtServer
Procedure applyParams ()
	
	Object.ReportName = Parameters.ReportName;
	AccountingReport = accountingReport ();
	SimpleReport = simpleReport ();
	AccountingFlagsSupported = accountingFlagsSupported ();
	AdjustAccountHierarchySupported = adjustAccountHierarchySupported ();
	OnDetailEvent = reportManager ().Events ().OnDetail;
	meta = Metadata.Reports [ Object.ReportName ];
	ReportPresentation = ? ( meta.ExtendedPresentation = "", meta.Presentation (), meta.ExtendentPresentation );
	ReportRef = Catalogs.Metadata.Ref ( "Report." + Object.ReportName );
	Parameters.Property ( "VariantPresentation", VariantPresentation );
	Parameters.Property ( "Variant", ReportVariant );
	Parameters.Property ( "Settings", ReportSettings );
	Parameters.Property ( "GenerateOnOpen", GenerateOnOpen );
	if ( GenerateOnOpen = undefined ) then
		GenerateOnOpen = false;
	endif; 
	
EndProcedure

&AtServer
Function accountingReport ()
	
	report = Object.ReportName;
	return report = "BalanceSheet"
		or report = "AccountBalance"
		or report = "AccountAnalysis"
		or report = "Transactions"
		or report = "Entries"
		or report = "SubsidiaryLedger"
		or report = "AccountTurnovers";
	
EndFunction 

&AtServer
Function simpleReport ()
	
	report = Object.ReportName;
	return report = "BalanceSheet"
	or report = "AccountBalance"
	or report = "AccountAnalysis"
	or report = "IncomeStatement"
	or report = "Debts"
	or report = "Reconciliation"
	or report = "VendorDebts"
	or report = "SalesRegister"
	or report = "Timesheet"
	or report = "PersonalCard"
	or report = "PurchasesRegister"
	or report = "CashBook"
	or report = "RetailSalesDaily";
		
EndFunction 

&AtServer
Function accountingFlagsSupported ()
	
	report = Object.ReportName;
	return report = "BalanceSheet"
		or Report = "AccountAnalysis"
		or Report = "AccountBalance"
		or Report = "SubsidiaryLedger"
		or Report = "AccountTurnovers";

EndFunction

&AtServer
Function adjustAccountHierarchySupported ()
	
	report = Object.ReportName;
	return report = "BalanceSheet"
		or report = "SubsidiaryLedger";

EndFunction

&AtServer
Function reportManager ()
	
	return Reports [ Object.ReportName ];
	
EndFunction

&AtServer
Procedure initComposer ()
	
	dataSchema = Reporter.GetSchema ( Object.ReportName );
	SchemaAddress = PutToTempStorage ( dataSchema, UUID );
	Object.SettingsComposer.Initialize ( new DataCompositionAvailableSettingsSource ( SchemaAddress ) );
	
EndProcedure 

&AtServer
Procedure openReport ()
	
	loadVariantServer ( ReportVariant, undefined );
	Reporter.RestorePeriod ( Object );
	Reporter.ApplyFilters ( Object.SettingsComposer, Parameters );
	
EndProcedure

&AtServer
Procedure drillDown ()
	
	detailsProcess = new DataCompositionDetailsProcess ( GetFromTempStorage ( Parameters.DetailsDescription.Data ), new DataCompositionAvailableSettingsSource ( SchemaAddress ) );
	usedSettings = detailsProcess.ApplySettings ( Parameters.DetailsDescription.ID, Parameters.DetailsDescription.UsedSettings );
	if ( TypeOf ( usedSettings ) = Type ( "DataCompositionSettings" ) ) then
		Object.SettingsComposer.LoadSettings ( usedSettings );
	elsif ( TypeOf ( usedSettings ) = Type ( "DataCompositionUserSettings" ) ) then
		loadVariantServer ( ReportVariant, ReportSettings );
		Object.SettingsComposer.LoadUserSettings ( usedSettings );
	endif;
	
EndProcedure

&AtServer
Procedure detail ()
	
	loadVariantServer ( "#Default", undefined );
	Reports [ Object.ReportName ].ApplyDetails ( Object.SettingsComposer, Parameters );
	
EndProcedure

&AtServer
Procedure openReportForNewWindow ()
	
	Object.SettingsComposer.LoadSettings ( Parameters.Variant );
	Object.SettingsComposer.LoadUserSettings ( Parameters.UserSettings );
	disableActualState ( Items.Result );
	
EndProcedure 

&AtServer
Procedure showStatus ()
	
	Items.Result.StatePresentation.Text = Output.ClickGenerateReport ();
	
EndProcedure

&AtServer
Procedure restoreSettingsButton ()
	
	ShowSettings = CommonSettingsStorage.Load ( "Report.Common", Enum.SettingsShowSettingsButtonState () );
	
EndProcedure 

&AtServer
Procedure setCurrentItem ()
	
	if ( GenerateOnOpen ) then
		setResultCurrentItem ( ThisObject );
		CurrentItem = Items.Result;
	else
		activateSettings ();
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setResultCurrentItem ( Form )
	
	items = Form.Items;
	Form.CurrentItem = items.Result;
	
EndProcedure 

&AtServer
Procedure activateSettings ()
	
	if ( ShowSettings ) then
		CurrentItem = Items.UserSettings;
	else
		if ( Items.GroupQuickSettings.ChildItems.Count () > 0 ) then
			CurrentItem = Items.GroupQuickSettings.ChildItems [ 0 ];
		endif; 
	endif; 
	
EndProcedure 

&AtServer
Function makeReport ( Quickly )
	
	enableActualState ();
	Result.Clear ();
	report = prepareReport ();
	p = report.Params;
	p.Quickly = Quickly;
	if ( p.Events.OnCheck ) then
		cancel = false;
		report.OnCheck ( cancel );
		if ( cancel ) then
			return false;
		endif; 
	endif; 
	p.Settings = p.Composer.GetSettings ();
	if ( not Reporter.ComposeResult ( report ) ) then
		return false;
	endif; 
	storeDetailsData ( p );
	return true;
	
EndFunction

&AtServer
Function prepareReport ()
 	
	report = Reporter.Prepare ( Object.ReportName );
	p = report.Params;
	p.GenerateOnOpen = ( GenerateOnOpen <> undefined ) and GenerateOnOpen;
	p.Variant = ReportVariant;
	p.Schema = GetFromTempStorage ( SchemaAddress );
	p.Result = Result;
	p.Composer = Object.SettingsComposer;
	return report;
	
EndFunction 

&AtServer
Procedure storeDetailsData ( Params )
	
	if ( IsTempStorageURL ( DetailsAddress ) ) then
		DeleteFromTempStorage ( DetailsAddress );
		DetailsAddress = "";
	endif; 
	DetailsAddress = PutToTempStorage ( Params.Details, DetailsAddress );
	
EndProcedure 

&AtServer
Procedure enableActualState ()
	
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
	Items.Result.StatePresentation.Visible = false;
	
EndProcedure

&AtServer
Procedure afterLoadSettings ()
	
	if ( AccountingReport ) then
		applyAccount ( DC.FindSetting ( Object.SettingsComposer, "Account" ), true, "" );
		applyAccount ( DC.FindSetting ( Object.SettingsComposer, "BalancedAccount" ), true, "Balanced" );
	endif;
	if ( not ShowSettings ) then
		buildFilter ();
	endif; 
	
EndProcedure 

&AtServer
Procedure applyAccount ( Setting, JustAdjust, Prefix )
	
	if ( Setting = undefined ) then
		return;
	endif;
	data = accountData ( Setting );
	if ( data <> undefined
		and not JustAdjust ) then
		setComparison ( data, Setting );
	endif;
	adjustDimensions ( data, Prefix );
	setFlags ( data, JustAdjust, Prefix );
	setDims ( data, Prefix );
	setCurrency ( data, Prefix );
	
EndProcedure 

&AtServer
Function accountData ( Setting )
	
	if ( TypeOf ( Setting ) = Type ( "DataCompositionSettingsParameterValue" ) ) then
		account = ? ( Setting.Use, Setting.Value, undefined );
	else
		comparison = Setting.ComparisonType;
		if ( comparison = DataCompositionComparisonType.Equal
			or comparison = DataCompositionComparisonType.InHierarchy ) then
			account = ? ( Setting.Use, Setting.RightValue, undefined );
		endif
	endif;
	return ? ( ValueIsFilled ( account ), GeneralAccounts.GetData ( account ), undefined );

EndFunction 

&AtServer
Procedure adjustDimensions ( AccountData, Prefix )

	dataSchema = GetFromTempStorage ( SchemaAddress );	
	adjustValueTypes ( dataSchema, AccountData, Prefix );
	adjustDimsLevel ( dataSchema, AccountData, Prefix );
	PutToTempStorage ( dataSchema, SchemaAddress );
	Object.SettingsComposer.Initialize ( new DataCompositionAvailableSettingsSource ( SchemaAddress ) );

EndProcedure

&AtServer
Procedure adjustValueTypes ( DataSchema, AccountData, Prefix )
	
	for each dataset in DataSchema.DataSets do
		fields = dataset.Fields;
		if ( AccountData = undefined ) then
			level = 0;
		else
			dims = AccountData.Dims;
			level = AccountData.Fields.Level;
		endif;
		for i = 1 to 3 do
			name = ( Prefix + "Dim" ) + i;
			field = fields.Find ( name );
			if ( field <> undefined ) then
				field.ValueType = ? ( i > level, new TypeDescription (), dims [ i - 1 ].ValueType );
			endif;
		enddo;
	enddo;

EndProcedure

&AtServer
Procedure adjustDimsLevel ( DataSchema, AccountData, Prefix )
	
	parameter = DataSchema.Parameters.Find ( "Show" + Prefix + "Dimensions" );
	if ( parameter = undefined ) then
		return;
	endif;
	list = dimensionVariants ( AccountData );
	parameter.SetAvailableValues ( list );

EndProcedure

&AtServer
Function dimensionVariants ( AccountData )
	
	variants = new ValueList ();
	if ( AccountData = undefined ) then
		return variants;
	endif;
	dims = AccountData.Dims;
	unsupported = AccountData.Fields.Level + 1;
	for each meta in Metadata.Enums.Dimensions.EnumValues do
		item = Enums.Dimensions [ meta.Name ];
		list = GeneralAccounts.LevelToList ( item );
		fits = true;
		for i = unsupported to 3 do
			if ( list.Find ( i ) <> undefined ) then
				fits = false;
				break;
			endif;
		enddo;
		if ( fits ) then
			presentation = new Array ();
			for each i in list do
				presentation.Add ( dims [ i - 1 ].Presentation );
			enddo;
			variants.Add ( item, StrConcat ( presentation, " / " ) );
		endif;
	enddo;
	if ( variants.Count () = 0 ) then
		variants.Add ( Enums.Dimensions.EmptyRef (), "<...>" );
	endif;
	return variants;

EndFunction

&AtServer
Procedure setComparison ( Data, Setting )
	
	if ( not AdjustAccountHierarchySupported ) then
		return;
	endif; 
	main = Data.Fields.Main;
	if ( main
		and Setting.ComparisonType = DataCompositionComparisonType.Equal ) then
		reference = settingReference ( Setting );
		reference.ComparisonType = DataCompositionComparisonType.InHierarchy;
	elsif ( not main
		and Setting.ComparisonType = DataCompositionComparisonType.InHierarchy ) then
		reference = settingReference ( Setting );
		reference.ComparisonType = DataCompositionComparisonType.Equal
	endif; 
	
EndProcedure 

&AtServer
Function settingReference ( Setting ) 
	
	return Object.SettingsComposer.UserSettings.GetObjectByID (
	Object.SettingsComposer.UserSettings.GetIDByObject ( Setting ) );

EndFunction

&AtServer
Procedure setFlags ( Data, JustAdjust, Prefix )
	
	if ( not AccountingFlagsSupported ) then
		return;
	elsif ( Object.ReportName = "BalanceSheet"
		and Data = undefined ) then
		return;
	endif;
	composer = Object.SettingsComposer;
	currency = DC.FindParameter ( composer, "Show" + Prefix + "Currency" );
	quantity = DC.FindParameter ( composer, "Show" + Prefix + "Quantity" );
	dims = DC.FindParameter ( composer, "Show" + Prefix + "Dimensions" );
	hierarchy = DC.FindParameter ( composer, Prefix + "AccountsHierarchy" );
	if ( Data = undefined ) then
		if ( currency <> undefined ) then
			currency.Use = false;
		endif;
		if ( quantity <> undefined ) then
			quantity.Use = false;
		endif;
		if ( dims <> undefined ) then
			dims.Use = false;
		endif;
		if ( hierarchy <> undefined ) then
			hierarchy.Use = false;
			hierarchy.Value = false;
		endif;
	else
		fields = Data.Fields;
		if ( quantity <> undefined ) then
			quantitative = fields.Quantitative;
			reset = not ( JustAdjust and quantitative );
			if ( reset ) then
				quantity.Use = quantitative;
				quantity.Value = quantitative;
			endif;
		endif;
		if ( hierarchy <> undefined ) then
			main = fields.Main;
			reset = not ( JustAdjust and main );
			if ( reset ) then
				hierarchy.Use = main;
				hierarchy.Value = main;
			endif;
		endif;
		if ( dims <> undefined ) then
			deep = fields.Level > 0;
			reset = not ( JustAdjust and deep );
			if ( reset ) then
				dims.Use = deep;
				dims.Value = ? ( deep, Enums.Dimensions._1, Enums.Dimensions.EmptyRef () );
			endif;
		endif;
		if ( currency <> undefined ) then
			isCurrency = fields.Currency;
			reset = not ( JustAdjust and isCurrency );
			if ( reset ) then
				currency.Use = isCurrency;
				currency.Value = isCurrency;
			endif;
		endif;
	endif; 
	
EndProcedure 

&AtServer
Procedure setDims ( Data, Prefix )
	
	settings = Object.SettingsComposer.Settings;
	if ( Data = undefined ) then
		dims = undefined;
		level = 0;
	else
		dims = Data.Dims;
		level = Data.Fields.Level;
	endif;
	for i = 1 to 3 do
		id = ( Prefix + "Dim" ) + i;
		dimIndex = i - 1;
		dim = DC.FindFilter ( settings, id );
		if ( dim = undefined ) then
			continue;
		endif; 
		if ( level > dimIndex ) then
			dim.UserSettingPresentation = dims [ dimIndex ].Presentation;
			if ( dim.UserSettingID = "" ) then
				toggleSetting ( dim, id );
			endif; 
		else
			toggleSetting ( dim, "" );
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure setCurrency ( Data, Prefix )
	
	path = Prefix + "Currency";
	currency = DC.FindFilter ( Object.SettingsComposer.Settings, path );
	if ( currency = undefined ) then
		return;
	endif; 
	if ( Data = undefined
		and Object.ReportName <> "BalanceSheet" )
		or ( Data <> undefined
		and not Data.Fields.Currency ) then
		id = "";
	else
		id = path;
	endif;
	toggleSetting ( currency, id );
	
EndProcedure 

&AtServer
Procedure toggleSetting ( Setting, ID )
	
	if ( ID = "" ) then
		Setting.UserSettingPresentation = "";
		Setting.UserSettingID = "";
		Setting.Use = false;
		Setting.RightValue = undefined;
	else
		Setting.UserSettingID = ID;
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setReportTitle ( Form )
	
	object = Form.Object;
	report = object.ReportName;
	composer = object.SettingsComposer;
	parts = new Array ();
	parts.Add ( Form.ReportPresentation );
	if ( report = "BalanceSheet"
		or report = "SubsidiaryLedger" ) then
		addPeriod ( parts, composer );
	elsif ( report = "AccountBalance"
		or report = "AccountAnalysis"
		or report = "AccountTurnovers"
		or report = "Entries"
		or report = "Transactions" ) then
		addPart ( parts, composer, "Account" );
		addPeriod ( parts, composer );
	elsif ( report = "Timesheet"
		or report = "WorkLog"
		or report = "Payroll"
		or report = "Payslips" ) then
		addPart ( parts, composer, "Employee" );
		addPeriod ( parts, composer );
	else
		addPart ( parts, composer, "Period" );
	endif;
	Form.Title = StrConcat ( parts, ", " );

EndProcedure 

&AtClientAtServerNoContext
Procedure addPeriod ( Parts, Composer )
	
	#if ( not MobileClient ) then
		p = DC.FindParameter ( Composer, "Period" );
		if ( p.Use ) then
			period = p.Value;
			Parts.Add ( PeriodPresentation ( period.StartDate, period.EndDate, "FP=true" ) );
		endif; 
	#endif
	
EndProcedure 

&AtClientAtServerNoContext
Procedure addPart ( Parts, Composer, Fields )
	
	for each name in StrSplit ( Fields, ", " ) do
		value = DC.FindValue ( Composer, name );
		if ( value <> undefined ) then
			Parts.Add ( value );
		endif; 
	enddo;
	
EndProcedure 

&AtServer
Procedure filterByCompany ()
	
	setting = DC.FindSetting ( Object.SettingsComposer, "Company" );
	if ( setting = undefined ) then
		return;
	endif; 
	if ( companyInstalled () ) then
		return;
	endif; 
	if ( OneCompany and not mandatory ( setting ) ) then
		return;
	endif; 
	setValue ( setting, Logins.Settings ( "Company" ).Company );

EndProcedure

&AtServer
Function companyInstalled ()
	
	company = DC.FindValue ( Object.SettingsComposer, "Company" );
	return company <> undefined;

EndFunction 

&AtServer
Function mandatory ( Parameter )
	
	if ( TypeOf ( Parameter ) <> Type ( "DataCompositionSettingsParameterValue" ) ) then
		return false;
	endif;
	schema = Reporter.GetSchema ( Object.ReportName );
	return schema.Parameters.Find ( Parameter.Parameter ).DenyIncompleteValues;
	
EndFunction

&AtServer
Procedure setValue ( Setting, Value )
	
	Setting.Use = true;
	if ( TypeOf ( Setting ) = Type ( "DataCompositionSettingsParameterValue" ) ) then
		Setting.Value = Value;
	else
		Setting.RightValue = Value;
	endif; 
	
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( Exit ) then
		return;
	endif; 
	storePeriod ();
	if ( VariantModified ) then
		Cancel = true;
		Output.ReportVariantModified2 ( ThisObject, , , "SaveVariantBeforeClose" );
	endif
	
EndProcedure

&AtServer
Procedure storePeriod ()
	
	Reporter.StorePeriod ( Object );
	
EndProcedure

&AtClient
Procedure SaveVariantBeforeClose ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		saveReportVariant ( "closeAfterSavingVariant" );
	elsif ( Answer = DialogReturnCode.No ) then
		VariantModified = false;
		Close ();
	endif; 

EndProcedure

&AtClient
Procedure closeAfterSavingVariant ( SavedSettings, IsSettings ) export
	
	if ( CommonSaveSettings ( SavedSettings, IsSettings ) ) then
		Close ();
	endif;
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Make ( Command )
	
	buildReport ( false );
	
EndProcedure

&AtClient
Procedure buildReport ( Quickly )
	
	invalidateSelection ();
	if ( makeReport ( Quickly ) ) then
		setResultCurrentItem ( ThisObject );
	endif; 

EndProcedure 

&AtClient
Procedure invalidateSelection ()
	
	PreviousArea = undefined;
	
EndProcedure 

&AtClient
Procedure SendReportByEmail ( Command )
	
	organizeDelivery ();
	
EndProcedure

&AtClient
Procedure organizeDelivery ()
	
	emailParams = Mailboxes.GetEmailParams ();
	emailParams.Subject = Title;
	emailParams.TableDescription = Title;
	emailParams.TableAddress = PutToTempStorage ( Result, UUID );
	p = new Structure ( "EmailParams", emailParams );
	OpenForm ( "Document.OutgoingEmail.ObjectForm", p );
	
EndProcedure 

&AtClient
Procedure SendReportBySchedule ( Command )
	
	if ( not checkScheduling () ) then
		return;
	endif; 
	organizeSendingBySchedule ();
	
EndProcedure

&AtServer
Function checkScheduling ()
	
	class = Reports [ Object.ReportName ];
	events = class.Events ();
	standardProcessing = true;
	cancel = false;
	if ( events.OnScheduling ) then
		class.OnScheduling ( Object.SettingsComposer, cancel, standardProcessing );
	endif; 
	if ( not cancel
		and standardProcessing ) then
		cancel = not checkPeriod ( Object.SettingsComposer, "Period" );
		if ( not cancel ) then
			cancel = not checkPeriod ( Object.SettingsComposer, "Asof" );
		endif; 
	endif; 
	return not cancel;
	
EndFunction 

&AtServer
Function checkPeriod ( Composer, Name )
	
	period = DC.FindParameter ( Composer, Name );
	if ( period <> undefined
		and period.Use
		and period.Value.Variant = StandardPeriodVariant.Custom ) then
		Output.ReportSchedulingIncorrectPeriod ();
		return false;
	endif; 
	return true;
	
EndFunction 

&AtClient
Procedure organizeSendingBySchedule ()
	
	values = new Structure ();
	values.Insert ( "Report", ReportRef );
	values.Insert ( "Variant", ReportVariant );
	values.Insert ( "SettingsAddress", PutToTempStorage ( Object.SettingsComposer.UserSettings, UUID ) );
	p = new Structure ( "FillingValues", values );
	OpenForm ( "InformationRegister.ScheduledReports.RecordForm", p );
	
EndProcedure 

&AtClient
Procedure SaveToDocuments ( Command )
	
	openDocument ();
	
EndProcedure

&AtClient
Procedure openDocument ()
	
	values = new Structure ();
	values.Insert ( "Subject", ReportPresentation );
	values.Insert ( "TabDoc", Result );
	p = new Structure ( "FillingValues", values );
	p.Insert ( "Command", Enum.DocumentCommandsUploadPrintForm () );
	p.Insert ( "TabDoc", Result );
	OpenForm ( "Document.Document.ObjectForm", p );
	
EndProcedure 

&AtClient
Procedure LoadVariant ( Command )
	
	loadReportVariant ();
	
EndProcedure

&AtClient
Procedure LoadSettings ( Command )
	
	loadUserSettings ();
	
EndProcedure

&AtClient
Procedure loadReportVariant ()
	
	openAndLoadVariantOrSettings ( false );
	
EndProcedure
 
&AtClient
Procedure loadUserSettings ()
	
	openAndLoadVariantOrSettings ( true );
	
EndProcedure

&AtClient
Procedure openAndLoadVariantOrSettings ( IsSettings )
	
	p = new Structure ( "ReportName, IsSettings, ReportVariant", Object.ReportName, IsSettings, ReportVariant ); 
	if ( IsSettings ) then
		p.Insert ( "CurrentSettings", ReportSettings );
	endif; 
	OpenForm ( "Report.Common.Form.LoadSettings", p, , , , , new NotifyDescription ( "CommonLoadSettings", ThisObject, IsSettings ), FormWindowOpeningMode.LockWholeInterface );
	
EndProcedure

&AtClient
Procedure CommonLoadSettings ( SelectedItem, IsSettings ) export
	
	if ( SelectedItem = undefined ) then
		return;
	endif; 
	if ( TypeOf ( SelectedItem ) = Type ( "String" ) ) then
		if ( IsSettings ) then
			applySettings ( SelectedItem );
		else
			if ( VariantModified ) then
				SelectedVariant = SelectedItem;
				Output.ReportVariantModified1 ( ThisObject, , , "LoadConfirmedVariant" );
			else
				applyVariant ( SelectedItem );
			endif; 
		endif;
	endif;
	
EndProcedure 

&AtServer
Procedure applySettings ( val Setting )
	
	loadSettingsServer ( Setting );
	afterLoadSettings ();
	
EndProcedure 

&AtServer
Procedure loadSettingsServer ( Code )
	
	if ( IsTempStorageURL ( Code ) ) then
		settingsReport = GetFromTempStorage ( Code );
	else
		if ( TypeOf ( Code ) = Type ( "CatalogRef.ReportSettings" ) ) then
			settings = Code;
		else
			settings = Catalogs.ReportSettings.FindByCode ( Code );
		endif;
		settingsReport = settings.Storage.Get ();
		ReportSettings = settings;
	endif; 
	if ( settingsReport <> undefined ) then
		Object.SettingsComposer.LoadUserSettings ( settingsReport );
		disableActualState ( Items.Result );
	endif; 
	
EndProcedure

&AtClientAtServerNoContext
Procedure disableActualState ( Result )
	
	Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	Result.StatePresentation.Visible = true;
	
EndProcedure

&AtServer
Procedure applyVariant ( val Setting )
	
	loadVariantServer ( Setting, undefined );
	afterLoadSettings ();
	
EndProcedure 

&AtServer
Procedure loadVariantServer ( Variant, SettingsCode )
	
	if ( Variant = undefined ) then
		code = undefined;
	elsif ( TypeOf ( Variant ) = Type ( "CatalogRef.ReportSettings" ) ) then
		code = DF.Pick ( Variant, "Code" );
	else
		code = Variant;
	endif; 
	if ( code = undefined ) then
		loadDefaultSettings ();
		return;
	endif;
	if ( Left ( code, 1 ) = "#" ) then
		loadPredefinedVariant ( code );
	else
		loadUserVariant ( code );
	endif; 
	if ( ValueIsFilled ( SettingsCode ) ) then
		loadSettingsServer ( SettingsCode );
	else
		resetReportSettings ();
	endif; 
	disableActualState ( Items.Result );

EndProcedure

&AtServer
Procedure loadDefaultSettings ()
	
	settingsReport = InformationRegisters.UsersReportSettings.Get ( new Structure ( "User, Report", SessionParameters.User, ReportRef ) );
	if ( ValueIsFilled ( settingsReport.Variant ) ) then
		variantCode = ? ( TypeOf ( settingsReport.Variant ) = Type ( "CatalogRef.ReportSettings" ), settingsReport.Variant.Code, settingsReport.Variant );
		loadVariantServer ( variantCode, settingsReport.Settings );
	else
		loadVariantServer ( "#Default", undefined );
		filterByCompany ();
	endif; 
	
EndProcedure

&AtServer
Procedure loadPredefinedVariant ( Code )
	
	dataSchema = Reporter.GetSchema ( Object.ReportName );
	variants = dataSchema.SettingVariants;
	variantName = Mid ( Code, 2 );
	item = variants.Find ( variantName );
	if ( item = undefined ) then
		item = dataSchema.SettingVariants.Default;
		ReportVariant = "#Default";
	else
		ReportVariant = Code;
	endif; 
	variantReport = item.Settings;
	VariantPresentation = item.Presentation;
	Object.SettingsComposer.LoadSettings ( variantReport );
	Object.SettingsComposer.Refresh ();
	
EndProcedure

&AtServer
Procedure loadUserVariant ( Code )
	
	ReportVariant = Catalogs.ReportSettings.FindByCode ( Code );
	variantReport = ReportVariant.Storage.Get ();
	VariantPresentation = "" + ReportVariant;
	Object.SettingsComposer.LoadSettings ( variantReport );
	Object.SettingsComposer.Refresh ();
	
EndProcedure

&AtServer
Procedure resetReportSettings ()
	
	ReportSettings = undefined;
	resetUserSettings ();
	
EndProcedure 

&AtClient
Procedure LoadConfirmedVariant ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		saveReportVariant ( "loadVariantAfterSavePrevious" );
	elsif ( Answer = DialogReturnCode.No ) then
		VariantModified = false;
		applyVariant ( SelectedVariant );
	endif; 

EndProcedure

&AtClient
Procedure loadVariantAfterSavePrevious ( SavedSettings, IsSettings ) export
	
	if ( CommonSaveSettings ( SavedSettings, IsSettings ) ) then
		applyVariant ( SelectedVariant );
	endif; 
	
EndProcedure 

&AtClient
Procedure SaveVariant ( Command )
	
	saveReportVariant ( "CommonSaveSettings" );
	
EndProcedure

&AtClient
Procedure SaveSettings ( Command )
	
	userSettingsSave ();
	
EndProcedure

&AtClient
Procedure saveReportVariant ( ProcAfterSave )
	
	openAndSaveVariantOrSettings ( false, ProcAfterSave );
	
EndProcedure

&AtClient
Procedure userSettingsSave ()
	
	openAndSaveVariantOrSettings ( true, "CommonSaveSettings" );
	
EndProcedure

&AtClient
Procedure openAndSaveVariantOrSettings ( IsSettings, ProcAfterSave )
	
	p = new Structure ();
	address = PutToTempStorage ( ? ( IsSettings, Object.SettingsComposer.UserSettings, Object.SettingsComposer.Settings ), UUID );
	p.Insert ( "SettingsAddress", address );
	p.Insert ( "ReportName", Object.ReportName );
	p.Insert ( "IsSettings", IsSettings );
	if ( IsSettings ) then
		p.Insert ( "ReportVariant", ReportVariant );
	endif; 
	OpenForm ( "Report.Common.Form.SaveSettings", p, , , , , new NotifyDescription ( ProcAfterSave, ThisObject, IsSettings ), FormWindowOpeningMode.LockWholeInterface );
	
EndProcedure

&AtClient
Function CommonSaveSettings ( SavedSettings, IsSettings ) export
	
	if ( TypeOf ( SavedSettings ) = Type ( "CatalogRef.ReportSettings" ) ) then
		if ( IsSettings ) then
			ReportSettings = SavedSettings;
		else
			ReportVariant = SavedSettings;
			VariantModified = false;
		endif; 
		return true;
	endif;
	return false;
	
EndFunction

&AtClient
Procedure OpenSettings ( Command )
	
	toggleSettings ();
	
EndProcedure

&AtServer
Procedure toggleSettings ()
	
	if ( ShowSettings ) then
		buildFilter ();
		ShowSettings = false;
	else
		ShowSettings = true;
	endif; 
	Appearance.Apply ( ThisObject, "ShowSettings" );
	activateSettings ();
	saveSettingsState ();
	
EndProcedure 

&AtServer
Procedure buildFilter ()
	
	clearFilter ();
	settings = Object.SettingsComposer.Settings;
	userSettings = Object.SettingsComposer.UserSettings.Items;
	list = settings.DataParameters.Items;
	availParams = settings.DataParameters.AvailableParameters;
	filters = settings.Filter.Items;
	availFilters = settings.Filter.FilterAvailableFields;
	parameterType = Type (  "DataCompositionSettingsParameterValue" );
	filterType = Type (  "DataCompositionFilterItem" );
	quick = DataCompositionSettingsItemViewMode.QuickAccess;
	for i = 0 to userSettings.Count () - 1 do
		item = userSettings [ i ];
		add = false;
		id = item.UserSettingID;
		itemType = TypeOf ( item );
		if ( itemType = parameterType ) then
			for each param in list do
				if ( param.UserSettingID = id
					and param.ViewMode = quick ) then
					label = availParams.FindParameter ( param.Parameter ).Title;
					add = true;
					break;
				endif;
			enddo; 
		elsif ( itemType = filterType ) then
			for each filter in filters do
				if ( filter.UserSettingID = id
					and filter.ViewMode = quick ) then
					label = filter.UserSettingPresentation;
					if ( label = "" ) then
						availItem = availFilters.FindField ( filter.LeftValue );
						if ( availItem = undefined ) then
							label = filter.LeftValue;
						else
							label = availItem.Title;
						endif; 
					endif; 
					add = true;
					break;
				endif; 
			enddo; 
		endif; 
		if ( add ) then
			adjustFilter ( item, itemType );
			drawFilter ( i, label );
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure clearFilter ()
	
	fields = Items.GroupQuickSettings.ChildItems;
	i = fields.Count () - 1;
	while ( i >= 0 ) do
		Items.Delete ( fields.Get ( i ) );
		i = i - 1;
	enddo; 
	
EndProcedure 

&AtServer
Procedure adjustFilter ( Item, Type )
	
	if ( Item.Use ) then
		return;
	endif; 
	if ( Type = Type ( "DataCompositionFilterItem" ) ) then
		if ( ValueIsFilled ( Item.RightValue ) ) then
			Item.RightValue = undefined;
		endif; 
	elsif ( Type = Type ( "DataCompositionSettingsParameterValue" ) ) then
		if ( ValueIsFilled ( Item.Value ) ) then
			Item.Value = undefined;
		endif; 
	endif; 
	
EndProcedure 

&AtServer
Procedure drawFilter ( Index, Label )
	
	i = Format ( Index, "NZ=" );
	field = Items.Add ( "_" + i, Type ( "FormField" ), Items.GroupQuickSettings );
	field.DataPath = "Object.SettingsComposer.UserSettings[" + i + "].Value";
	field.Type = FormFieldType.InputField;
	field.Title = Label;
	field.Visible = true;
	field.OpenButton = false;
	field.OpenButton = false;
	field.ClearButton = true;
	if ( calendarFilter ( Index ) ) then
		field.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInDropListAndInInputField;
		field.CreateButton = false;
	endif;
	field.SetAction ( "OnChange", "FilterOnChange" );
	field.SetAction ( "StartChoice", "FilterStartChoice" );
	
EndProcedure 

&AtServer
Function calendarFilter ( Index )
	
	parameterType = Type ( "DataCompositionSettingsParameterValue" );
	composer = Object.SettingsComposer;
	setting = composer.UserSettings.Items [ Index ];
	if ( TypeOf ( setting ) <> parameterType ) then
		return false;
	endif;
	parameter = setting.Parameter;
	fixedList = composer.FixedSettings.DataParameters.Items;
	calendarType = Type ( "CatalogRef.Calendar" );
	for each item in fixedList do
		if ( TypeOf ( item ) = parameterType
			and item.Parameter = parameter ) then
			return TypeOf ( item.Value ) = calendarType;
		endif;
	enddo;
	return false;
	
EndFunction

&AtServer
Procedure saveSettingsState ()
	
	LoginsSrv.SaveSettings ( "Report.Common", Enum.SettingsShowSettingsButtonState (), ShowSettings );
	
EndProcedure 

&AtClient
Procedure ChangeVariant ( Command )
	
	changeReportVariant ();

EndProcedure

&AtClient
Procedure changeReportVariant ()
	
	p = new Structure ();
	p.Insert ( "Variant", Object.SettingsComposer.Settings );
	p.Insert ( "UserSettings", Object.SettingsComposer.UserSettings );
	p.Insert ( "VariantPresentation", VariantPresentation );
	ChoiceForm = GetForm ( "Report." + Object.ReportName + ".VariantForm", p, , true );
	ChoiceForm.OnCloseNotifyDescription = new NotifyDescription ( "LoadChangedVariant", ThisObject, ChoiceForm );
	ChoiceForm.WindowOpeningMode = FormWindowOpeningMode.LockWholeInterface;
	OpenForm ( ChoiceForm );
	
EndProcedure

&AtClient
Procedure LoadChangedVariant ( Result, Params ) export
	
	if ( Result = true ) then
		//@skip-warning
		Object.SettingsComposer = ChoiceForm.Report.SettingsComposer;
		#if ( not WebClient ) then
			disableActualState ( Items.Result );
		#endif
		VariantModified = true;
		afterLoadSettings ();
	endif; 
	
EndProcedure

&AtClient
Procedure ResetSettings ( Command )
	
	initSettings ();
	
EndProcedure

&AtServer
Procedure initSettings ()
	
	resetUserSettings ();
	afterLoadSettings ();
	
EndProcedure 

&AtServer
Procedure resetUserSettings ()
	
	Object.SettingsComposer.LoadUserSettings ( new DataCompositionUserSettings () );
	disableActualState ( Items.Result );
	
EndProcedure

&AtClient
Procedure NewWindow ( Command )
	
	openReportInNewWindow ();
	
EndProcedure

&AtClient
Procedure openReportInNewWindow ()
	
	p = getParametersForNewWindow ();
	p.Insert ( "Command", "NewWindow" );
	p.Insert ( "Variant", Object.SettingsComposer.Settings );
	p.Insert ( "UserSettings", Object.SettingsComposer.UserSettings );
	OpenForm ( "Report.Common.Form", p, , true );
	
EndProcedure

&AtClient
Function getParametersForNewWindow ()
	
	p = new Structure ();
	p.Insert ( "ReportName", Object.ReportName );
	p.Insert ( "Variant", ReportVariant );
	p.Insert ( "Settings", ReportSettings );
	p.Insert ( "VariantPresentation", VariantPresentation );
	return p;
	
EndFunction

&AtClient
Procedure SetVariantAsDefault ( Command )
	
	setReportVariantAsDefault ();
	
EndProcedure

&AtClient
Procedure setReportVariantAsDefault ()
	
	setUserSettings ( false );
	
EndProcedure

&AtClient
Procedure SetSettingsAsDefault ( Command )
	
	setUserVariantAndSettingsAsDefault ();
	
EndProcedure

&AtServer
Procedure setUserVariantAndSettingsAsDefault ()
	
	setUserSettings ( false );
	setUserSettings ( true );
	
EndProcedure

&AtServer
Procedure setUserSettings ( IsSettings )
	
	record = InformationRegisters.UsersReportSettings.CreateRecordManager ();
	record.User = SessionParameters.User;
	record.Report = ReportRef;
	record.Read ();
	record.User = SessionParameters.User;
	record.Report = ReportRef;
	if ( IsSettings ) then
		record.Settings = ReportSettings;
	else
		record.Variant = ReportVariant;
	endif; 
	record.Write ();

EndProcedure

&AtClient
Procedure SelectReportVariant ( Command )
	
	loadReportVariant ();
	
EndProcedure

&AtClient
Procedure Help ( Command )
	
	OpenHelp ( "Report." + Object.ReportName );
	
EndProcedure

// *****************************************
// *********** UserSettings

&AtClient
Procedure UserSettingsOnChange ( Item )
	
	applyUserSetting ( Object.SettingsComposer.UserSettings.GetObjectByID ( Items.UserSettings.CurrentRow ) );
	
EndProcedure

&AtClient
Procedure applyUserSetting ( Setting )
	
	updated = onChange ( Setting );
	#if ( not WebClient ) then
		if ( not updated ) then
			disableActualState ( Items.Result );
		endif; 
	#endif
	
EndProcedure 

&AtClient
Function onChange ( Setting )
	
	applySetting ( Setting );
	setReportTitle ( ThisObject );
	if ( AccountingReport
		and isCondition ( "Account", Setting )
		and not ShowSettings ) then
		buildFilter ();
	endif; 
	if ( SimpleReport ) then
		buildReport ( true );
		return true;
	endif; 
	return false;
	
EndFunction

&AtClient
Procedure applySetting ( Setting )
	
	if ( AccountingReport ) then
		if ( isCondition ( "Account", Setting, false ) ) then
			//@skip-warning
			applyAccount ( Setting, false, "" );
		elsif ( isCondition ( "BalancedAccount", Setting, false ) ) then
			//@skip-warning
			applyAccount ( Setting, false, "Balanced" );
		endif; 
	endif;
	
EndProcedure

&AtClient
Function isCondition ( Name, Setting, EqualOrHiearachy = true )
	
	type = TypeOf ( Setting );
	if ( type = Type ( "DataCompositionSettingsParameterValue" ) ) then
		#if ( WebClient ) then
			//@skip-warning
			return Name = settingName ( Setting );
		#else
			return Name = String ( Setting.Parameter );
		#endif
	else
		filter = DC.FindFilter ( Object.SettingsComposer, Name, false );
		if ( filter <> undefined ) then
			if ( not EqualOrHiearachy
			 	or ( filter.ComparisonType = DataCompositionComparisonType.Equal
					or filter.ComparisonType = DataCompositionComparisonType.InHierarchy ) ) then
				return filter.UserSettingID = Setting.UserSettingID;
			endif;
		endif;
	endif; 
	return false;
	
EndFunction 

&AtServerNoContext
Function settingName ( val Setting )
	
	return String ( Setting.Parameter );
	
EndFunction

&AtClient
Procedure UserSettingsValueStartChoice ( Item, ChoiceData, StandardProcessing )
	
	startChoice ( Object.SettingsComposer.UserSettings.GetObjectByID ( Items.UserSettings.CurrentRow ),
		Item, StandardProcessing );

EndProcedure

&AtClient
Procedure startChoice ( Setting, Item, StandardProcessing )
	
	if ( AccountingReport ) then
		if ( isCondition ( "Dim1", Setting ) ) then
			chooseDimension ( Item, 1, StandardProcessing );
		elsif ( isCondition ( "Dim2", Setting ) ) then
			chooseDimension ( Item, 2, StandardProcessing );
		elsif ( isCondition ( "Dim3", Setting  ) ) then
			chooseDimension ( Item, 3, StandardProcessing );
		endif;
	endif; 
	
EndProcedure

&AtClient
Procedure chooseDimension ( Item, Level, StandardProcessing )
	
	composer = Object.SettingsComposer;
	account = DC.FindValue ( composer, "Account" );
	if ( account = undefined ) then
		return;
	endif; 
	data = GeneralAccounts.GetData ( account );
	deep = data.Fields.Level;
	if ( deep = 0 ) then
		return;
	endif; 
	dims = data.Dims;
	p = Dimensions.GetParams ();
	p.Level = Level;
	if ( deep > 0 ) then
		p.Dim1 = getDimension ( composer, 1, dims );
	endif;
	if ( deep > 1 ) then
		p.Dim2 = getDimension ( composer, 2, dims );
	endif; 
	if ( deep > 2 ) then
		p.Dim3 = getDimension ( composer, 3, dims );
	endif; 
	p.Company = DC.FindValue ( composer, "Company" );
	Dimensions.Choose ( p, Item, StandardProcessing );
	
EndProcedure 

&AtClient
Function getDimension ( Composer, Level, Dims )
	
	value = DC.FindValue ( Composer, "Dim" + Level );
	if ( value = undefined ) then
		value = Dims [ Level - 1 ].ValueType.AdjustValue ( undefined );
	endif; 
	return value;

EndFunction 

&AtClient
Procedure FilterOnChange ( Item )
	
	setting = getSetting ( Item );
	applyUserSetting ( setting );
	
EndProcedure

&AtClient
Function getSetting ( Item )
	
	i = Number ( Mid ( Item.Name, 2 ) );
	setting = Object.SettingsComposer.UserSettings.Items [ i ];
	if ( TypeOf ( setting ) = Type ( "DataCompositionSettingsParameterValue" ) ) then
		setting.Use = ValueIsFilled ( setting.Value );
	else
		setting.Use = ValueIsFilled ( setting.RightValue );
	endif; 
	return setting;
	
EndFunction

&AtClient
Procedure FilterStartChoice ( Item, ChoiceData, StandardProcessing )
	
	startChoice ( getSetting ( Item ), Item, StandardProcessing );
	
EndProcedure

&AtClient
Procedure UserSettingsValueOnChange ( Item )
	
	applyValue ( Object.SettingsComposer.UserSettings.GetObjectByID ( Items.UserSettings.CurrentRow ) );
	
EndProcedure

&AtClient
Procedure applyValue ( Setting )
	
	if ( TypeOf ( Setting ) = Type ( "DataCompositionFilterItem" ) ) then
		fixComparison ( Setting );
	endif;

EndProcedure

&AtClient
Procedure fixComparison ( Setting )
	
	isFolder = isFolder ( Setting.RightValue );
	comparison = Setting.ComparisonType;
	if ( isFolder ) then
		if ( comparison = DataCompositionComparisonType.Equal ) then
			candidate = DataCompositionComparisonType.InHierarchy;
		elsif ( comparison = DataCompositionComparisonType.NotEqual ) then
			candidate = DataCompositionComparisonType.NotInHierarchy;
		else
			return;
		endif; 
	else
		if ( comparison = DataCompositionComparisonType.InHierarchy ) then
			candidate = DataCompositionComparisonType.Equal;
		elsif ( comparison = DataCompositionComparisonType.NotInHierarchy ) then
			candidate = DataCompositionComparisonType.NotEqual;
		else
			return;
		endif; 
	endif;
	Setting.ComparisonType = candidate;

EndProcedure

&AtServerNoContext
Function isFolder ( val Value )
	
	return Metafields.IsFolder ( Value );

EndFunction

// *****************************************
// *********** Result

&AtClient
Procedure ResultDetailProcessing ( Item, Details, StandardProcessing )
	
	if ( TypeOf ( Details ) <> Type ( "DataCompositionDetailsID" ) ) then
		return;	
	endif;
	StandardProcessing = false;
	if ( OnDetailEvent ) then
		ReportDetails.Clear ();
		UseMainAction = false;
		DetailActions = undefined;
		beforeDetailing ( Object.ReportName, ReportDetails, UseMainAction, DetailActions, DetailsAddress, SchemaAddress, Details );
	endif;
	doDetailProcessing ( Details, Item );
	
EndProcedure

&AtServerNoContext
Procedure beforeDetailing ( val ReportName, ReportDetails, UseMainAction, DetailActions, val DetailsAddress, val SchemaAddress, val Details )
	
	systemMenu = undefined;
	Reports [ ReportName ].OnDetail ( ReportDetails, systemMenu, UseMainAction, getFilters ( SchemaAddress, Details, DetailsAddress ) );
	if ( TypeOf ( systemMenu ) = Type ( "Array" ) ) then
		DetailActions = new FixedArray ( systemMenu );
	else
		DetailActions = systemMenu;
	endif;
	
EndProcedure

&AtClient
Procedure doDetailProcessing ( Details, Item )
	
	if ( DetailActions = undefined ) then
		actions = undefined;
	elsif ( DetailActions = null ) then
		actions = new Array ();
	else
		actions = new Array ( DetailActions );
	endif;
	detailsObject = new DataCompositionDetailsProcess ( DetailsAddress, new DataCompositionAvailableSettingsSource ( SchemaAddress ) );
	detailsObject.ShowActionChoice ( new NotifyDescription ( "ApplySelectedAction", ThisObject, Details ), Details, actions, ReportDetails,
	// "false or UseMainAction" - Bug workaround for webclient. It doesn't get UseMainAction as a boolean value if actions = undefined
	false or UseMainAction );

EndProcedure

&AtClient
Procedure ApplySelectedAction ( SelectedAction, SelectedActionParameters, Details ) export
	
	if ( SelectedAction = undefined
		or SelectedAction = DataCompositionDetailsProcessingAction.None ) then
		return;
	elsif ( SelectedAction = DataCompositionDetailsProcessingAction.OpenValue ) then
		ShowValue ( , SelectedActionParameters );
	elsif ( TypeOf ( SelectedAction ) = Type ( "String" ) ) then
 		p = ReportsSystem.GetParams ( SelectedAction );
		p.GenerateOnOpen = true;
		p.Command = "Detail";
		p.Parent = Object.ReportName;
		p.Filters = getFilters ( SchemaAddress, Details, DetailsAddress );
		OpenForm ( "Report.Common.Form", p, , true );
	else
		// Detailing report requires idle handler. Otherwise, a new report's form
		// will be opened in a new window
		WorkAroundSelectedActionParameters = SelectedActionParameters;
		WorkAroundDetails = Details;
		AttachIdleHandler ( "detailReport", 0.01, true );
	endif; 
	
EndProcedure 

&AtServerNoContext
Function getFilters ( val Schema, val Details, val Address )
	
	settings = GetFromTempStorage ( Address );
	composer = new DataCompositionSettingsComposer ();
	composer.LoadSettings ( settings.Settings );
	composer.Initialize ( new DataCompositionAvailableSettingsSource ( Schema ) );
	return retrieveFilters ( composer, Details, settings );
	
EndFunction 

&AtServerNoContext
Function retrieveFilters ( Composer, Details, Settings )
	
	filters = new Array ();
	addDetails ( Settings.Items [ Details ], Composer, filters );
	clean ( filters );
	addFilters ( filters, Composer );
	return PutToTempStorage ( filters );
	
EndFunction

&AtServerNoContext
Procedure addDetails ( Item, Composer, Filters )
	
	if ( TypeOf ( Item ) = Type ( "DataCompositionFieldDetailsItem" ) ) then
		for each field in Item.GetFields () do
			allowedField = getAllowedField ( new DataCompositionField ( field.field ), Composer );
			if ( allowedField = undefined
				or allowedField.Resource ) then
				continue;
			endif;
			Filters.Add ( formalize ( field.Field, true, false, false, field ) );
		enddo;
	endif;
	for each parent in Item.GetParents() do
		addDetails ( parent, Composer, Filters );
	enddo;
	
EndProcedure

&AtServerNoContext
Function formalize ( Name, Field, Filter, Parameter, Item )
	
	data = new Structure ( "Name, Field, Filter, Parameter, Item, StandardProcessing, Comparison", Name, Field, Filter, Parameter, Item, true );
	if ( Field and Item.Hierarchy ) then
		data.Comparison = DataCompositionComparisonType.InHierarchy;
	endif; 
	return data;
	
EndFunction 

&AtServerNoContext
Function getAllowedField ( Field, Composer )
	
	if ( TypeOf ( Field ) = Type ( "String" ) ) then
		search = new DataCompositionField ( Field );
	else
		search = Field;
	endif;
	composerType = TypeOf ( Composer );
	if ( composerType = Type ( "DataCompositionSettingsComposer" )
	 or composerType = Type ( "DataCompositionDetailsData" )
	 or composerType = Type ( "DataCompositionNestedObjectSettings" ) ) then
		return Composer.Settings.SelectionAvailableFields.FindField ( search );
	else
		return Composer.FindField ( search );
	endif;
	
EndFunction

&AtServerNoContext
Procedure clean ( Filters )
	
	i = Filters.Count () - 1;
	while ( i >= 0 ) do
		name = Filters [ i ].Name;
		for j = 0 to i - 1 do
			if ( Filters [ j ].Name = name ) then
				Filters.Delete ( i );
				break;
			endif;
		enddo;
		k = 1;
		childKilled = false;
		while ( true ) do
			a = StrFind ( name, ".", , k );
			if ( a = 0 ) then
				break;
			endif; 
			parent = Left ( name, a - 1 );
			for j = 0 to Filters.Count () - 1 do
				if ( Filters [ j ].Name = parent ) then
					Filters.Delete ( i );
					childKilled = false;
					break;
				endif;
			enddo; 
			if ( childKilled ) then
				break;
			endif; 
			k = a + 1;
		enddo; 
		i = i - 1;
	enddo;
	
EndProcedure 

&AtServerNoContext
Procedure addFilters ( Filters, Composer )

	for each item in Composer.Settings.Filter.Items do
		if ( item.Use ) then
			Filters.Add ( formalize ( undefined, false, true, false, item ) );
		endif;
	enddo;
	for each item in Composer.Settings.DataParameters.Items do
		if ( item.Use ) then
			Filters.Add ( formalize ( String ( item.Parameter ), false, false, true, item ) );
		endif;
	enddo;

EndProcedure 

&AtClient
Procedure ShowLevel ( Command )
	
	selectLevel ();
	
EndProcedure

&AtClient
Procedure selectLevel ()
	
	#if ( WebClient ) then
		top = 5;
	#else
		top = Result.RowGroupLevelCount ();
	#endif
	if ( top = 1 ) then
		return;
	endif; 
	menu = new ValueList ();
	for i = 1 to top do
		menu.Add ( i );
	enddo; 
	ShowChooseFromMenu ( new NotifyDescription ( "LevelSelected", ThisObject ), menu );
	
EndProcedure 

&AtClient
Procedure LevelSelected ( Value, Params ) export
	
	if ( Value = undefined ) then
		return;
	endif; 
	Result.ShowRowGroupLevel ( Value.Value - 1 );
	
EndProcedure 

&AtClient
Procedure ShowHeaders ( Command )
	
	toggleHeaders ();
	
EndProcedure

&AtClient
Procedure toggleHeaders ()
	
	ShowHeaders = not ShowHeaders;
	Items.Result.ShowHeaders = ShowHeaders;
	Appearance.Apply ( ThisObject, "ShowHeaders" );

EndProcedure

&AtClient
Procedure ShowGrid ( Command )
	
	toggleGrid ();
	
EndProcedure

&AtClient
Procedure toggleGrid ()
	
	ShowGrid = not ShowGrid;
	Items.Result.ShowGrid = ShowGrid;
	Appearance.Apply ( ThisObject, "ShowGrid" );

EndProcedure 

&AtClient
Procedure CalcTotals ( Command )
	
	updateTotals ( false );
	
EndProcedure

&AtClient
Procedure updateTotals ( CheckSquare )
	
	if ( TotalsEnv = undefined ) then
		SpreadsheetTotals.Init ( TotalsEnv );	
	endif;
	TotalsEnv.Spreadsheet = Result;
	TotalsEnv.CheckSquare = CheckSquare;
	SpreadsheetTotals.Update ( TotalsEnv );
	Items.CalcTotals.Visible = CheckSquare and TotalsEnv.HugeSquare;
	TotalInfo = TotalsEnv.Result; 
	
EndProcedure 

&AtClient
Procedure ResultOnActivateArea ( Item )

	if ( drawing ()
		or sameArea () ) then
		return;
	endif;
	startCalculation ();
	
EndProcedure

&AtClient
Function drawing ()
	
	return TypeOf ( Result.CurrentArea ) <> Type ( "SpreadsheetDocumentRange" );
	
EndFunction 

&AtClient
Function sameArea ()
	
	currentName = Result.CurrentArea.Name;
	if ( PreviousArea = currentName ) then
		return true;
	else
		PreviousArea = currentName;
		return false;
	endif; 
	
EndFunction 

&AtClient
Procedure startCalculation ()
	
	DetachIdleHandler ( "startUpdating" );
	AttachIdleHandler ( "startUpdating", 0.2, true );
	
EndProcedure 

&AtClient
Procedure startUpdating ()
	
	updateTotals ( true );
	
EndProcedure 

&AtClient
Procedure detailReport () export
	
	p = getParametersForNewWindow ();
	p.Insert ( "Command", "DrillDown" );
	p.Insert ( "GenerateOnOpen", true );
	p.Insert ( "DetailsDescription", new DataCompositionDetailsProcessDescription ( DetailsAddress, WorkAroundDetails, WorkAroundSelectedActionParameters ) );
	OpenForm ( "Report.Common.Form", p, , true );
	
EndProcedure
