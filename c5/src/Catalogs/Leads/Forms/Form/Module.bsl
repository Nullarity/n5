&AtClient
var ItemsRow;
&AtClient
var ServicesRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	initPhones ();
	Photos.Load ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure initPhones ()
	
	PhoneTemplates.Set ( ThisObject, "AdditionalPhone, BusinessPhone, HomePhone, MobilePhone, Fax" );

EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Forms.RedefineOpeningModeForLinux ( ThisObject );
	init ();
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
		initPhones ();
	endif; 
	setAccuracy ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Photo show filled ( Photo );
	|Upload show empty ( Photo );
	|VAT ItemsVATAccount ServicesVATAccount show Object.VATUse > 0;
	|ItemsVATCode ItemsVAT ItemsTotal ServicesVATCode ServicesVAT ServicesTotal show Object.VATUse > 0;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure init ()
	
	CurrentUser = SessionParameters.User;
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	Object.Creator = CurrentUser;
	Object.Date = CurrentSessionDate ();
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	settings = Logins.Settings ( "Company, Department" );
	Object.Company = settings.Company;
	Object.Department = settings.Department;
	Object.Currency = Application.Currency ();
	Object.Responsible = CurrentUser;
	ContactsForm.SetCountry ( Object );
	ContactsForm.SetZIPFormat ( Object );
	
EndProcedure 

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, ServicesQuantity" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
		
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	ContactsForm.ZIPMask ( ThisObject );

EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	Photos.Save ( ThisObject, CurrentObject );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	endif; 
	
EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = Object.Items.Add ();
		item = Fields.Item;
		row.Item = item;
		package = Fields.Package;
		row.Package = package;
		feature = Fields.Feature;
		row.Feature = feature;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Quantity = Fields.Quantity;
		row.Price = Goods.Price ( , Object.Date, Object.Prices, item, package, feature, , , , , Object.Currency );
		data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
		row.VATCode = data.VAT;
		row.VATRate = data.Rate;
		accounts = AccountsMap.Item ( item, Object.Company, , "VAT" );
		row.VATAccount = accounts.VAT;
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	Computations.Amount ( row );
	Computations.Total ( row, Object.VATUse );
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure GenderOnChange ( Item )
	
	setPresentation ();
	
EndProcedure

&AtClient
Procedure setPresentation ()
	
	parts = new Array ();
	if ( not IsBlankString ( Object.Name ) ) then
		parts.Add ( "" + ? ( Object.Salutation.IsEmpty (), "", "" + Object.Salutation + " " ) + Object.Name );
	endif; 
	if ( not IsBlankString ( Object.Email ) ) then
		parts.Add ( Object.Email );
	endif; 
	if ( not IsBlankString ( Object.MobilePhone ) ) then
		parts.Add ( Object.MobilePhone );
	endif; 
	if ( not Object.ContactType.IsEmpty () ) then
		parts.Add ( "" + Object.ContactType );
	endif; 
	Object.Contact = StrConcat ( parts, ", " );
	Object.Description = Object.Contact;
	
EndProcedure 

&AtClient
Procedure SalutationOnChange ( Item )
	
	setPresentation ();
	
EndProcedure

&AtClient
Procedure NameOnChange ( Item )
	
	setName ( Object );
	setPresentation ();
	
EndProcedure

&AtClientAtServerNoContext
Procedure setName ( Object )
	
	Object.Name = ContactsForm.FullName ( Object );
	
EndProcedure 

&AtClient
Procedure EmailOnChange ( Item )
	
	setPresentation ();
	
EndProcedure

&AtClient
Procedure PhoneStartChoice ( Item, ChoiceData, StandardProcessing )
	
	PhoneTemplates.Choice ( ThisObject, Item );

EndProcedure

&AtClient
Procedure MobilePhoneOnChange ( Item )
	
	setPresentation ();
	
EndProcedure

&AtClient
Procedure BusinessPhoneOnChange ( Item )
	
	setPresentation ();
	
EndProcedure

&AtClient
Procedure AdditionalPhoneOnChange ( Item )
	
	setPresentation ();
	
EndProcedure

&AtClient
Procedure FaxOnChange ( Item )
	
	setPresentation ();
	
EndProcedure

&AtClient
Procedure HomePhoneOnChange ( Item )
	
	setPresentation ();
	
EndProcedure

&AtClient
Procedure WebOnChange ( Item )
	
	setPresentation ();
	
EndProcedure

&AtClient
Procedure ContactTypeOnChange ( Item )
	
	setPresentation ();
	
EndProcedure

&AtClient
Procedure TwitterOnChange ( Item )
	
	ContactsForm.AdjustTwitter ( Object );
	
EndProcedure

// *****************************************
// *********** Photo

&AtClient
Procedure PhotoClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	Photos.Upload ( ThisObject );
	
EndProcedure

&AtClient
Procedure Upload ( Command )
	
	Photos.Upload ( ThisObject );
	
EndProcedure

&AtClient
Procedure ClearPhoto ( Command )
	
	Photos.Remove ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Address

&AtClient
Procedure CountryOnChange ( Item )
	
	ContactsForm.SetZIPFormat ( Object );
	ContactsForm.ZIPMask ( ThisObject );
	ContactsForm.SetAddress ( Object );
		
EndProcedure

&AtClient
Procedure AddressOnChange ( Item )
	
	ContactsForm.SetAddress ( Object );
	
EndProcedure

&AtClient
Procedure ZIPFormatOnChange ( Item )
	
	ContactsForm.ZIPMask ( ThisObject );
	ContactsForm.SetAddress ( Object );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	OpenForm ( "CommonForm.Scan", , ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	ItemsRow.VATCode = data.VAT;
	ItemsRow.VATRate = data.Rate;
	ItemsRow.VATAccount = data.VATAccount;
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate," );
	price = Goods.Price ( , Params.Date, Params.Prices, item, data.Package, , , , , , Params.Currency );
	accounts = AccountsMap.Item ( item, Params.Company, , "VAT" );
	data.Insert ( "Price", price );
	data.Insert ( "VATAccount", accounts.VAT );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure ItemsFeatureOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ItemsRow );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	ItemsRow.Price = Goods.Price ( , Object.Date, prices, ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature, , , , , Object.Currency );
	
EndProcedure 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Feature", ItemsRow.Feature );
	p.Insert ( "Package", ItemsRow.Package );
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	p.Insert ( "Prices", prices );
	data = getPackageData ( p );
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	price = Goods.Price ( , Params.Date, Params.Prices, Params.Item, package, Params.Feature, , , , , Params.Currency );
	data = new Structure ();
	data.Insert ( "Capacity", capacity );
	data.Insert ( "Price", price );
	return data;
	
EndFunction 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPriceOnChange ( Item )

	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );

EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	Computations.Price ( ItemsRow );
	Computations.Discount ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPricesOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsDiscountRateOnChange ( Item )
	
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsDiscountOnChange ( Item )
	
	Computations.DiscountRate ( ItemsRow );
	Computations.Amount ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsVATCodeOnChange ( Item )
	
	ItemsRow.VATRate = DF.Pick ( ItemsRow.VATCode, "Rate" );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsVATOnChange ( Item )
	
	Computations.Total ( ItemsRow, Object.VATUse, false );
	
EndProcedure

// *****************************************
// *********** Table Services

&AtClient
Procedure ServicesOnActivateRow ( Item )
	
	ServicesRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ServicesOnEditEnd ( Item, NewRow, CancelEdit )
	
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ServicesAfterDeleteRow ( Item )
	
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ServicesItemOnChange ( Item )
	
	applyService ();
	
EndProcedure

&AtClient
Procedure applyService ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ServicesRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getServiceData ( p );
	ServicesRow.Price = data.Price;
	ServicesRow.Description = data.FullDescription;
	ServicesRow.VATCode = data.VAT;
	ServicesRow.VATRate = data.Rate;
	ServicesRow.VATAccount = data.VATAccount;
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getServiceData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "FullDescription, VAT, VAT.Rate as Rate" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, , , , , , , Params.Currency );
	accounts = AccountsMap.Item ( item, Params.Company, , "VAT" );
	data.Insert ( "Price", price );
	data.Insert ( "VATAccount", accounts.VAT );
	return data;
	
EndFunction 

&AtClient
Procedure ServicesFeatureOnChange ( Item )
	
	priceService ();
	Computations.Amount ( ServicesRow );
	
EndProcedure

&AtClient
Procedure priceService ()
	
	prices = ? ( ServicesRow.Prices.IsEmpty (), Object.Prices, ServicesRow.Prices );
	ServicesRow.Price = Goods.Price ( , Object.Date, prices, ServicesRow.Item, , ServicesRow.Feature, , , , , Object.Currency );
	
EndProcedure 

&AtClient
Procedure ServicesQuantityOnChange ( Item )
	
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesPriceOnChange ( Item )

	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );

EndProcedure

&AtClient
Procedure ServicesAmountOnChange ( Item )
	
	Computations.Price ( ServicesRow );
	Computations.Discount ( ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesPricesOnChange ( Item )
	
	priceService ();
	Computations.Amount ( ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesDiscountRateOnChange ( Item )
	
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesDiscountOnChange ( Item )
	
	Computations.DiscountRate ( ServicesRow );
	Computations.Amount ( ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesVATCodeOnChange ( Item )
	
	ServicesRow.VATRate = DF.Pick ( ServicesRow.VATCode, "Rate" );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesVATOnChange ( Item )
	
	Computations.Total ( ServicesRow, Object.VATUse, false );
	
EndProcedure

// *****************************************
// *********** Group Footer

&AtClient
Procedure PricesOnChange ( Item )
	
	applyPrices ();
	
EndProcedure

&AtServer
Procedure applyPrices ()
	
	cache = new Map ();
	vatUse = Object.VATUse;
	date = Object.Date;
	prices = Object.Prices;
	currency = Object.Currency;
	for each row in Object.Items do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, , , , , currency );
		Computations.Discount ( row );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	cache = new Map ();
	for each row in Object.Services do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, , row.Feature, , , , , currency );
		Computations.Discount ( row );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure 

&AtClient
Procedure CurrencyOnChange ( Item )
	
	setRate ();
	
EndProcedure

&AtServer
Procedure setRate ()
	
	rates = CurrenciesSrv.Get ( Object.Currency );
	object.Rate = rates.Rate;
	object.Factor = rates.Factor;
	
EndProcedure 

&AtClient
Procedure VATUseOnChange ( Item )
	
	applyVATUse ();
	
EndProcedure

&AtServer
Procedure applyVATUse ()
	
	vatUse = Object.VATUse;
	for each row in Object.Items do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.Services do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	InvoiceForm.CalcTotals ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
EndProcedure

// *****************************************
// *********** Notes

&AtClient
Procedure NotesOnStartEdit ( Item, NewRow, Clone )
	
	initNote ();
	
EndProcedure

&AtClient
Procedure initNote ()
	
	currentData = Items.Notes.CurrentData;
	currentData.Date = CurrentDate ();
	currentData.User = CurrentUser;
	
EndProcedure
