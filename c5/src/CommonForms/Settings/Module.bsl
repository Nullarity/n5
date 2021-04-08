&AtClient
var Pages;
&AtClient
var Features;
&AtClient
var Packages;
&AtClient
var Production;
&AtClient
var Series;
&AtClient
var License;
&AtClient
var AccountingRow;
&AtClient
var StayOpen;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	fillAddresses ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure fillAddresses ( Form )
	
	object = Form.Object;
	data = DF.Values ( object.Company, "PaymentAddress, ShippingAddress" );
	Form.PaymentAddress = data.PaymentAddress;
	Form.ShippingAddress = data.ShippingAddress;
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	testPeriodicity ();
	testTracking ();
	fillTimeZones ();
	setCurrentTimeZone ();
	setLastStep ();
	applySetupDate ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
		
EndProcedure

Procedure testPeriodicity ()
	
	if ( TestingOff ( "SettingsPeriodicity" ) ) then
		return;
	endif;
	_periodicity = Metadata.InformationRegisters.Settings.InformationRegisterPeriodicity;
	_month = Metadata.ObjectProperties.InformationRegisterPeriodicity.Month;
	_info = "Periodicity of InformationRegisters.Settings should be Month. Otherwise, code of CommonForm.Settings should be rewised";
	Assert ( _periodicity, _info ).Equal ( _month );
	
EndProcedure

Procedure testTracking ()
	
	if ( TestingOn ( "SettingsTracking" ) ) then
		if ( Metadata.ExchangePlans.MobileServers.Content.Find ( Metadata.InformationRegisters.Tracking ) = undefined ) then
			raise "InformationRegisters.Tracking should be in ExchangePlans.MobileServers for sending removed records";
		endif; 
	endif;
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormPreviuosStep enable CurrentStep > 0;
	|FormNextStep enable CurrentStep < LastStep;
	|ShowExpiration enable filled ( Object.License )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillTimeZones ()
	
	timeZones = GetAvailableTimeZones ();
	for each timeZone in timeZones do
		Items.TimeZone.ChoiceList.Add ( timeZone, timeZone + " (" + TimeZonePresentation ( timeZone ) + ")" );
	enddo; 
	
EndProcedure 

&AtServer
Procedure setCurrentTimeZone ()
	
	currentTimeZone = GetInfoBaseTimeZone ();
	TimeZone = ? ( currentTimeZone = undefined, TimeZone (), currentTimeZone );
	
EndProcedure 

&AtServer
Procedure setLastStep ()
	
	LastStep = Items.Pages.ChildItems.Count () - 1;
	
EndProcedure 

&AtServer
Procedure applySetupDate ()
	
	adjustSetupDate ();
	filterSettings ();
	
EndProcedure 

&AtServer
Procedure adjustSetupDate ()
	
	if ( SetupDate = Date ( 1, 1, 1 ) ) then
		SetupDate = BegOfMonth ( CurrentSessionDate () );
	else
		SetupDate = BegOfMonth ( SetupDate );
	endif; 
	
EndProcedure 

&AtServer
Procedure filterSettings ()
	
	DC.SetParameter ( Settings, "Period", SetupDate, true );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	init ();
	readOptions ();
	
EndProcedure

&AtClient
Procedure init ()
	
	StayOpen = false;
	Pages = new Map ();
	Pages [ 0 ] = Items.MainPage;
	Pages [ 1 ] = Items.FeaturesPage;
	Pages [ 2 ] = Items.CustomersPage;
	Pages [ 3 ] = Items.ItemsPage;
	Pages [ 4 ] = Items.AccountingPage;
	Pages [ 5 ] = Items.EmployeesPage;
	Pages [ 6 ] = Items.DatabasePage;
	
EndProcedure

&AtClient
Procedure readOptions ()
	
	Features = Object.Features;
	Packages = Object.Packages;
	Production = Object.Production;
	Series = Object.Series;
	License = Object.License;
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( Cloud.SaaS ()
		and Connections.IsDemo ()
		and not Logins.Sysadmin () ) then
		Output.DemoMode ();
		Cancel = true;
		return;
	endif; 
	setNoPackages ();
	setTenantTimeZone ();
	saveAddresses ();
	Constants.FirstStart.Set ( false );
	
EndProcedure

&AtServer
Procedure setNoPackages ()
	
	Constants.NoPackages.Set ( not Object.Packages );
	
EndProcedure 

&AtServer
Procedure setTenantTimeZone ()
	
	SetPrivilegedMode ( true );
	SetExclusiveMode ( true );
	SetInfoBaseTimeZone ( TimeZone );
	SetExclusiveMode ( false );
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtServer
Procedure saveAddresses ()
	
	data = DF.Values ( Object.Company, "PaymentAddress, ShippingAddress" );
	if ( data.PaymentAddress = PaymentAddress
		and data.ShippingAddress = ShippingAddress ) then
		return;
	endif; 
	obj = Object.Company.GetObject ();
	obj.PaymentAddress = PaymentAddress;
	obj.ShippingAddress = ShippingAddress;
	obj.Write ();
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	saveConnectionString ();
	registerConstants ();
	
EndProcedure

&AtServer
Procedure saveConnectionString ()
	
	value = ? ( Object.License = "", "", InfoBaseConnectionString () );
	Constants.ConnectionString.Set ( value );
	
EndProcedure

&AtServer
Procedure registerConstants ()
	
	obj = Catalogs.Constants.Constants.GetObject ();
	obj.Write ();
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	RefreshReusableValues ();
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	if ( licenseChanged () ) then
		StayOpen = true;
		Output.RestartSystem ( ThisObject );
	elsif ( optionsChanged () ) then
		StayOpen = true;
		Output.RestartInterface ( ThisObject );
	endif; 
	
EndProcedure

&AtClient
Function licenseChanged ()
	
	return License <> Object.License;
	
EndFunction

&AtClient
Function optionsChanged ()
	
	return Features <> Object.Features
		or Packages <> Object.Packages
		or Production <> Object.Production
		or Series <> Object.Series;
	
EndFunction 

&AtClient
Procedure RestartSystem ( Answer, Params ) export
	
	StayOpen = false;
	if ( Answer = DialogReturnCode.No ) then
		Close ();
	else
		Exit ( , true );
	endif;
	
EndProcedure 

&AtClient
Procedure RestartInterface ( Params ) export
	
	readOptions ();
	RefreshInterface ();
	StayOpen = false;
	Close ();
	
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( StayOpen ) then
		Cancel = true;
	elsif ( Modified ) then
		Cancel = true;
		Output.ConfirmExit ( ThisObject );
	endif; 
	
EndProcedure

&AtClient
Procedure ConfirmExit ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Cancel ) then
		return;
	elsif ( Answer = DialogReturnCode.Yes ) then
		Write ();
	else
		Modified = false;
	endif; 
	Close ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure NextStep ( Command )
	
	CurrentStep = CurrentStep + 1;
	activateCurrentStep ();
	Appearance.Apply ( ThisObject, "CurrentStep" );
	
EndProcedure

&AtClient
Procedure activateCurrentStep ()
	
	Items.Pages.CurrentPage = Pages [ CurrentStep ];

EndProcedure 

&AtClient
Procedure PreviuosStep ( Command )
	
	CurrentStep = CurrentStep - 1;
	activateCurrentStep ();
	Appearance.Apply ( ThisObject, "CurrentStep" );
	
EndProcedure

// *****************************************
// *********** Group Pages

&AtClient
Procedure PagesOnCurrentPageChange ( Item, CurrentPage )
	
	setCurrentStep ( CurrentPage );
	
EndProcedure

&AtClient
Procedure setCurrentStep ( CurrentPage )
	
	for each item in Pages do
		if ( item.Value = CurrentPage ) then
			CurrentStep = item.Key;
			Appearance.Apply ( ThisObject, "CurrentStep" );
			break;
		endif; 
	enddo; 
	
EndProcedure 

// *****************************************
// *********** Page General

&AtClient
Procedure ShowExpiration ( Command )
	
	displayExpiration ();
	
EndProcedure

&AtClient
Procedure displayExpiration ()
	
	error = undefined;
	date = ApplicationUpdates.SubscriptionExpired ( Object.License, error );
	if ( date = undefined ) then
		raise error;
	else
		p = new Structure ( "Date", Conversion.DateToString ( date ) );
		if ( EndOfDay ( date ) < CurrentDate () ) then
			Output.LicenseAlreadyExpired ( , , p );
		else
			Output.LicenseWillExpire ( , , p );
		endif;
	endif;
	
EndProcedure

&AtClient
Procedure LicenseOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.License" );
	
EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	fillAddresses ( ThisObject );
	
EndProcedure

&AtClient
Procedure PaymentAddressOnChange ( Item )
	
	if ( PaymentAddress.IsEmpty () ) then
		return;
	endif; 
	setShippingAddress ();
	
EndProcedure

&AtServer
Procedure setShippingAddress ()
	
	if ( not ShippingAddress.IsEmpty () ) then
		return;
	endif; 
	ShippingAddress = PaymentAddress;
	
EndProcedure 

// *****************************************
// *********** Page Accounting

&AtClient
Procedure SetupDateOnChange ( Item )
	
	applySetupDate ();
	
EndProcedure

&AtClient
Procedure SettingsOnActivateRow ( Item )
	
	AccountingRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure SettingsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	openSetting ();
	
EndProcedure

&AtClient
Procedure openSetting ()
	
	if ( AccountingRow = undefined ) then
		return;
	elsif ( AccountingRow.IsFolder ) then
		Output.SelectSettingPlease ();
	else
		p = new Structure ( "Parameter, Date", AccountingRow.Ref, SetupDate );
		OpenForm ( "ChartOfCharacteristicTypes.Settings.Form.Setup", p );
	endif; 
	
EndProcedure 

&AtClient
Procedure SettingsBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	openSetting ()

EndProcedure
