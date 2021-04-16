// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Forms.RedefineOpeningModeForLinux ( ThisObject );
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	setFlags ();
	setCurrency ();
	setCompany ();
	setTerms ();
	setVATAdvance ();
	
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
Procedure CustomerOnChange ( Item )
	
	applyCustomer ();
	Appearance.Apply ( ThisObject, "Object.Customer" );
	
EndProcedure

&AtClient
Procedure applyCustomer ()
	
	if ( Object.Customer ) then
		return;
	endif; 
	Object.CustomerPrices = undefined;
	Object.CustomerTerms = undefined;
	Object.CustomerDelivery = 0;
	Object.Export = false;
	Object.CustomerVATAdvance = undefined;
	
EndProcedure

&AtClient
Procedure VendorOnChange ( Item )
	
	applyVendor ();
	Appearance.Apply ( ThisObject, "Object.Vendor" );
	
EndProcedure

&AtClient
Procedure applyVendor ()
	
	if ( Object.Vendor ) then
		return;
	endif; 
	Object.VendorPrices = undefined;
	Object.VendorTerms = undefined;
	Object.VendorDelivery = 0;
	Object.Import = false;
	Object.VendorVATAdvance = undefined;
	
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
