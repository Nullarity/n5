
// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	InvoiceForm.SetLocalCurrency ( ThisObject );
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Parameters.CopyingValue.IsEmpty () ) then
		Object.Signed = false;
	else
		setFlags ();
		setCurrency ();
		setCompany ();
		setTerms ();
		setVATAdvance ();
	endif;
	
EndProcedure

&AtServer
Procedure setFlags ()
	
	data = DF.Values ( Object.Owner, "Customer, Vendor" );
	Object.Customer = data.Customer;
	Object.Vendor = data.Vendor;
	
EndProcedure 

&AtServer
Procedure setCurrency ()
	
	if ( Object.Currency.IsEmpty () ) then
		Object.Currency = Application.Currency ();
	endif;
	
EndProcedure 

&AtServer
Procedure setCompany ()
	
	if ( not Object.Company.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	
EndProcedure 

&AtServer
Procedure setTerms ()
	
	if ( Object.Customer ) then
		Object.CustomerTerms = Constants.Terms.Get ();
		Object.CustomerPayment = Constants.PaymentMethod.Get ();
	endif;
	if ( Object.Vendor ) then
		Object.VendorTerms = Constants.VendorTerms.Get ();
		Object.VendorPayment = Constants.VendorPaymentMethod.Get ();
	endif; 
	
EndProcedure 

&AtServer
Procedure setVATAdvance ()

	s = "
	|select Settings.Value as Value
	|from InformationRegister.Settings.SliceLast ( ,
	|	Parameter = value ( ChartOfCharacteristicTypes.Settings.VATAdvance )
	|) as Settings
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	value = ? ( table.Count () = 0, undefined, table [ 0 ].Value );
	if ( Object.Customer ) then
		Object.CustomerVATAdvance = value;
	endif;
	if ( Object.Vendor ) then
		Object.VendorVATAdvance = value;
	endif;
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|CustomerPage show Object.Customer;
	|VendorPage show Object.Vendor;
	|CustomerBank enable Object.CustomerPayment <> Enum.PaymentMethods.Cash;
	|VendorBank enable Object.VendorPayment <> Enum.PaymentMethods.Cash;
	|CustomerVATAdvance show Object.Customer;
	|VendorVATAdvance show Object.Vendor;
	|CustomerRateType show Object.Customer and Object.Currency <> LocalCurrency;
	|CustomerRate CustomerFactor show Object.Customer and Object.Currency <> LocalCurrency
	|	and Object.CustomerRateType = Enum.CurrencyRates.Fixed;
	|VendorRateType show Object.Vendor and Object.Currency <> LocalCurrency;
	|VendorRate VendorFactor show Object.Vendor and Object.Currency <> LocalCurrency
	|	and Object.VendorRateType = Enum.CurrencyRates.Fixed;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not Periods.Ok ( Object.DateStart, Object.DateEnd ) ) then
		Cancel = true;
		return;
	endif;
	if ( not checkPrices () ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

&AtServer
Function checkPrices ()
	
	tables = new Array ();
	if ( Object.Customer ) then
		tables.Add ( Items.Items );
		tables.Add ( Items.Services );
	endif; 
	if ( Object.Vendor ) then
		tables.Add ( Items.VendorItems );
		tables.Add ( Items.VendorServices );
	endif; 
	return checkTables ( tables );
	
EndFunction 

&AtServer
Function checkTables ( Tables )
	
	error = false;
	for each table in Tables do
		if ( table = Items.Items
			or table = Items.VendorItems ) then
			columns = "Item, Package, Feature";
		else
			columns = "Item, Feature";
		endif; 
		doubles = Collections.GetDoubles ( Forms.ItemValue ( ThisObject, table ), columns );
		if ( doubles.Count () > 0 ) then
			name = table.Name;
			for each row in doubles do
				Output.DoubleItems ( , Output.Row ( name, row.LineNumber, "Item" ) );
			enddo; 
			error = true;
		endif; 
	enddo; 
	return not error;
	
EndFunction 

// *****************************************
// *********** Group Form

&AtClient
Procedure CurrencyOnChange ( Item )

	applyCurrency ();

EndProcedure

&AtServer
Procedure applyCurrency ()
	
	if ( Object.Currency.IsEmpty () ) then
		return;
	endif;
	resetRateType ( true, true );
	setCurrencyRate ( true, true );
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure

&AtServer
Procedure resetRateType ( Customer, Vendor )
	
	if ( Object.Currency = LocalCurrency ) then
		Object.CustomerRateType = undefined;
		Object.VendorRateType = undefined;
	else
		if ( Customer ) then
			Object.CustomerRateType = ? ( Object.Customer, Enums.CurrencyRates.Current, undefined );
		endif;
		if ( Vendor ) then
			Object.VendorRateType = ? ( Object.Vendor, Enums.CurrencyRates.Current, undefined );
		endif;
	endif;
	
EndProcedure

&AtServer
Procedure setCurrencyRate ( Customer, Vendor )
	
	if ( Customer ) then
		Object.CustomerRate = 1;
		Object.CustomerFactor = 1;
	endif;
	if ( Vendor ) then
		Object.VendorRate = 1;
		Object.VendorFactor = 1;
	endif;
	currency = Object.Currency;
	changeCustomer = Customer and Object.Customer and Object.CustomerRateType = Enums.CurrencyRates.Fixed;
	changeVendor = Vendor and Object.Vendor and Object.VendorRateType = Enums.CurrencyRates.Fixed;
	if ( currency = LocalCurrency
		or not ( changeCustomer or changeVendor ) ) then
		return;
	endif;
	rates = CurrenciesSrv.Get ( currency );
	if ( changeCustomer ) then
		Object.CustomerRate = rates.Rate;
		Object.CustomerFactor = rates.Factor;
	endif;
	if ( changeVendor ) then
		Object.VendorRate = rates.Rate;
		Object.VendorFactor = rates.Factor;
	endif;
	
EndProcedure

&AtClient
Procedure CustomerOnChange ( Item )
	
	applyCustomer ();
	
EndProcedure

&AtServer
Procedure applyCustomer ()
	
	resetRateType ( true, false );
	setCurrencyRate ( true, false );
	if ( not Object.Customer ) then
		Object.CustomerPrices = undefined;
		Object.CustomerTerms = undefined;
		Object.CustomerDelivery = 0;
		Object.Export = false;
		Object.Signed = false;
		Object.CustomerVATAdvance = undefined;
	endif; 
	Appearance.Apply ( ThisObject, "Object.Customer" );
	
EndProcedure

&AtClient
Procedure VendorOnChange ( Item )
	
	applyVendor ();
	
EndProcedure

&AtServer
Procedure applyVendor ()
	
	resetRateType ( false, true );
	setCurrencyRate ( false, true );
	if ( not Object.Vendor ) then
		Object.VendorPrices = undefined;
		Object.VendorTerms = undefined;
		Object.VendorDelivery = 0;
		Object.Import = false;
		Object.VendorVATAdvance = undefined;
	endif; 
	Appearance.Apply ( ThisObject, "Object.Vendor" );
	
EndProcedure

&AtClient
Procedure CustomerPaymentOnChange ( Item )
	
	resetCustomerBank ();
	Appearance.Apply ( ThisObject, "Object.CustomerPayment" );
	
EndProcedure

&AtClient
Procedure resetCustomerBank ()
	
	if ( Object.CustomerPayment = PredefinedValue ( "Enum.PaymentMethods.Cash" ) ) then
		Object.CustomerBank = undefined;
	endif; 
	
EndProcedure 

&AtClient
Procedure VendorPaymentOnChange ( Item )
	
	resetVendorBank ();
	Appearance.Apply ( ThisObject, "Object.VendorPayment" );
	
EndProcedure

&AtClient
Procedure resetVendorBank ()
	
	if ( Object.VendorPayment = PredefinedValue ( "Enum.PaymentMethods.Cash" ) ) then
		Object.VendorBank = undefined;
	endif; 

EndProcedure 

&AtClient
Procedure CustomerRateTypeOnChange ( Item )

	applyCustomerRateType ();

EndProcedure

&AtServer
Procedure applyCustomerRateType ()
	
	setCurrencyRate ( true, false );
	Appearance.Apply ( ThisObject, "Object.CustomerRateType" );
	
EndProcedure

&AtClient
Procedure VendorRateTypeOnChange ( Item )

	applyVendorRateType ();

EndProcedure

&AtServer
Procedure applyVendorRateType ()
	
	setCurrencyRate ( false, true);
	Appearance.Apply ( ThisObject, "Object.VendorRateType" );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	setPackage ( Items.Items );
	
EndProcedure

&AtClient
Procedure setPackage ( Table )
	
	row = Table.CurrentData;
	row.Package = DF.Pick ( row.Item, "Package" );
	
EndProcedure 

// *****************************************
// *********** Table VendorItems

&AtClient
Procedure VendorItemsItemOnChange ( Item )
	
	setPackage ( Items.VendorItems );
	
EndProcedure
