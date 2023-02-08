&AtServer
var Env;
&AtServer
var Copy;
&AtServer
var ViewSalesOrders;
&AtClient
var ItemsRow;
&AtClient
var ServicesRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	initCurrency ();
	setRejection ();
	updateChangesPermission ();
	Constraints.ShowSales ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure initCurrency ()
	
	InvoiceForm.SetLocalCurrency ( ThisObject );
	InvoiceForm.SetContractCurrency ( ThisObject );
	InvoiceForm.SetCurrencyList ( ThisObject );
	
EndProcedure

&AtServer
Procedure setRejection ()
	
	s = "
	|select RejectedQuotes.Cause as Cause
	|from InformationRegister.RejectedQuotes as RejectedQuotes
	|where RejectedQuotes.Quote = &Quote
	|";
	q = new Query ( s );
	q.SetParameter ( "Quote", Object.Ref );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		return;
	endif; 
	RejectionCause = table [ 0 ].Cause;
	ThisObject.ReadOnly = true;
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		Copy = not Parameters.CopyingValue.IsEmpty ();
		initCurrency ();
		DocumentForm.Init ( Object );
		fillNew ();
		fillByCustomer ();
		updateChangesPermission ();
	endif; 
	setLinks ();
	setAccuracy ();
	Forms.ActivatePage ( ThisObject, "Items,Services" );
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|ContractAmount show filled ( ContractCurrency ) and ContractCurrency <> Object.Currency;
	|ContractAmount title/Form.ContractCurrency ContractCurrency <> Object.Currency;
	|Rate Factor enable
	|filled ( LocalCurrency )
	|and filled ( ContractCurrency )
	|and ( Object.Currency <> LocalCurrency or ContractCurrency <> LocalCurrency );
	|Rejection show filled ( RejectionCause );
	|FormDocumentQuoteCancel show empty ( RejectionCause );
	|VAT ItemsVATCode ItemsVAT ServicesVATCode ServicesVAT show Object.VATUse > 0;
	|ItemsTotal ServicesTotal show Object.VATUse = 2;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Copy ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company, Warehouse" );
	Object.Company = settings.Company;
	Object.Warehouse = settings.Warehouse;
	Object.Currency = Application.Currency ();
	
EndProcedure 

&AtServer
Procedure fillByCustomer ()
	
	apply = Parameters.FillingValues.Property ( "Customer" )
	and not Copy
	and not Object.Customer.IsEmpty ();
	if ( apply ) then
		applyCustomer ();
	endif;

EndProcedure 

&AtServer
Procedure applyCustomer ()
	
	data = DF.Values ( Object.Customer, "CustomerContract, VATUse" );
	Object.Contract = data.CustomerContract;
	Object.VATUse = data.VATUse;
	applyContract ();
	applyVATUse ();
	
EndProcedure

&AtServer
Procedure applyContract ()

	data = DF.Values ( Object.Contract,
		"CustomerPrices, Currency, CustomerDelivery as Delivery, CustomerRateType, CustomerRate, CustomerFactor" );
	ContractCurrency = data.Currency;
	if ( data.CustomerRateType = Enums.CurrencyRates.Fixed
		and data.CustomerRate <> 0 ) then
		currency = new Structure ( "Rate, Factor", data.CustomerRate, data.CustomerFactor );
	else
		currency = CurrenciesSrv.Get ( data.Currency, Object.Date );
	endif;
	Object.Rate = currency.Rate;
	Object.Factor = currency.Factor;
	Object.Currency = ContractCurrency;
	Object.Prices = data.CustomerPrices;
	InvoiceForm.SetCurrencyList ( ThisObject );
	InvoiceForm.SetDelivery ( ThisObject, data );
	PaymentsTable.Fill ( Object );
	Constraints.ShowSales ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Currency" );

EndProcedure

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		Env.Q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( Object.Ref.IsEmpty () ) then
		return;
	endif; 
	ViewSalesOrders = AccessRight ( "View", Metadata.Documents.SalesOrder );
	if ( ViewSalesOrders ) then
		s = "
		|// #SalesOrders
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.SalesOrder as Documents
		|where Documents.Quote = &Ref
		|and not Documents.DeletionMark
		|";
		Env.Selection.Add ( s );
	endif;
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	if ( ViewSalesOrders ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.SalesOrders, Metadata.Documents.SalesOrder ) );
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, ServicesQuantity" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
		
EndProcedure 

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	setLinks ();
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	Forms.DeleteLastRow ( Object.Items, "Item" );
	Forms.DeleteLastRow ( Object.Services, "Item" );
	InvoiceForm.CalcTotals ( ThisObject );
	PaymentsTable.Fix ( Object );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageQuoteCanceled ()
		and Parameter = Object.Ref ) then
		applyRejectionCause ();
	elsif ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	elsif ( EventName = Enum.MessageSalesPermissionIsSaved ()
		and Parameter = Object.Ref ) then
		updateSalesPermission ();
	elsif ( EventName = Enum.MessageUpdateSalesPermission ()
		and Parameter = UUID ) then
		updateSalesPermission ();
	endif;

EndProcedure

&AtServer
Procedure applyRejectionCause ()
	
	setRejection ();
	Appearance.Apply ( ThisObject, "RejectionCause" );
	
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
		row.Price = Goods.Price ( , Object.Date, Object.Prices, item, package, feature, Object.Customer, Object.Contract, , Object.Warehouse, Object.Currency );
		data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
		row.VATCode = data.VAT;
		row.VATRate = data.Rate;
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	Computations.Discount ( row );
	Computations.Amount ( row );
	Computations.Total ( row, Object.VATUse );
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure 

&AtServer
Procedure updateSalesPermission ()

	Constraints.ShowSales ( ThisObject );

EndProcedure

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	if ( SelectedValue.Operation = Enum.ChoiceOperationsPickItems () ) then
		addSelectedItems ( SelectedValue );
		addSelectedServices ( SelectedValue );
		InvoiceForm.CalcTotals ( ThisObject );
	endif; 
	
EndProcedure

&AtClient
Procedure addSelectedItems ( Params )
	
	itemsTable = Object.Items;
	for each selectedRow in Params.Items do
		row = itemsTable.Add ();
		FillPropertyValues ( row, selectedRow );
	enddo; 
	
EndProcedure

&AtClient
Procedure addSelectedServices ( Params )
	
	services = Object.Services;
	for each selectedRow in Params.Services do
		row = services.Add ();
		FillPropertyValues ( row, selectedRow );
	enddo; 
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure CustomerOnChange ( Item )
	
	applyCustomer ();
	
EndProcedure

&AtClient
Procedure ContractOnChange ( Item )
	
	applyContract ();
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure

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
	customer = Object.Customer;
	contract = Object.Contract;
	warehouse = Object.Warehouse;
	currency = Object.Currency;
	for each row in Object.Items do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, customer, contract, , warehouse, currency );
		Computations.Discount ( row );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	cache = new Map ();
	for each row in Object.Services do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, , row.Feature, customer, contract, , warehouse, currency );
		Computations.Discount ( row );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure 

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	InvoiceForm.SetRate ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure 

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure SelectItems ( Command )
	
	PickItems.Open ( ThisObject, pickParams () );
	
EndProcedure

&AtServer
Function pickParams ()
	
	return PickItems.GetParams ( ThisObject );
	
EndFunction 

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
	p.Insert ( "Organization", Object.Customer );
	p.Insert ( "Contract", Object.Contract );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	ItemsRow.VATCode = data.VAT;
	ItemsRow.VATRate = data.Rate;
	Computations.Units ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, data.Package, , Params.Organization, Params.Contract, , Params.Warehouse, Params.Currency );
	data.Insert ( "Price", price );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure ItemsFeatureOnChange ( Item )
	
	priceItem ();
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	ItemsRow.Price = Goods.Price ( , Object.Date, prices, ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature, Object.Customer, Object.Contract, , Object.Warehouse, Object.Currency );
	
EndProcedure 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Organization", Object.Customer );
	p.Insert ( "Contract", Object.Contract );
	p.Insert ( "Warehouse", Object.Warehouse );
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
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	price = Goods.Price ( , Params.Date, Params.Prices, Params.Item, package, Params.Feature, Params.Organization, Params.Contract, , Params.Warehouse, Params.Currency );
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
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsPriceOnChange ( Item )

	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );

EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	Computations.Price ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsPricesOnChange ( Item )
	
	priceItem ();
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsDiscountRateOnChange ( Item )
	
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsDiscountOnChange ( Item )
	
	Computations.DiscountRate ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
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
	p.Insert ( "Organization", Object.Customer );
	p.Insert ( "Contract", Object.Contract );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ServicesRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getServiceData ( p );
	ServicesRow.Price = data.Price;
	ServicesRow.Description = data.FullDescription;
	ServicesRow.VATCode = data.VAT;
	ServicesRow.VATRate = data.Rate;
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getServiceData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "FullDescription, VAT, VAT.Rate as Rate" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, , , Params.Organization, Params.Contract, , Params.Warehouse, Params.Currency );
	data.Insert ( "Price", price );
	return data;
	
EndFunction 

&AtClient
Procedure ServicesFeatureOnChange ( Item )
	
	priceService ();
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure priceService ()
	
	prices = ? ( ServicesRow.Prices.IsEmpty (), Object.Prices, ServicesRow.Prices );
	ServicesRow.Price = Goods.Price ( , Object.Date, prices, ServicesRow.Item, , ServicesRow.Feature, Object.Customer, Object.Contract, , Object.Warehouse, Object.Currency );
	
EndProcedure 

&AtClient
Procedure ServicesQuantityOnChange ( Item )
	
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesPriceOnChange ( Item )

	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );

EndProcedure

&AtClient
Procedure ServicesAmountOnChange ( Item )
	
	Computations.Price ( ServicesRow );
	Computations.Discount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesPricesOnChange ( Item )
	
	priceService ();
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesDiscountRateOnChange ( Item )
	
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesDiscountOnChange ( Item )
	
	Computations.DiscountRate ( ServicesRow );
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

// *****************************************
// *********** Table Payments

&AtClient
Procedure CalcPayments ( Command )
	
	PaymentsTable.Calc ( Object );
	
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

&AtClient
Procedure VATUseOnChange ( Item )
	
	applyVATUse ();
	
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

&AtClient
Procedure ServicesVATCodeOnChange ( Item )
	
	ServicesRow.VATRate = DF.Pick ( ServicesRow.VATCode, "Rate" );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesVATOnChange ( Item )
	
	Computations.Total ( ServicesRow, Object.VATUse, false );
	
EndProcedure
