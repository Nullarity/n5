&AtServer
var Base;
&AtServer
var Env;
&AtClient
var ItemsRow;
&AtClient
var ServicesRow;
&AtServer
var Copy;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	updateBalanceDue ();
	InvoiceForm.SetLocalCurrency ( ThisObject );
	InvoiceForm.SetContractCurrency ( ThisObject );
	InvoiceForm.SetCurrencyList ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateBalanceDue ()

	InvoiceForm.SetPaymentsApplied ( ThisObject );
	InvoiceForm.CalcBalanceDue ( ThisObject );
	Appearance.Apply ( ThisObject, "BalanceDue" );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( isNew () ) then
		Copy = not Parameters.CopyingValue.IsEmpty ();
		InvoiceForm.SetLocalCurrency ( ThisObject );
		InvoiceForm.SetCurrencyList ( ThisObject );
		DocumentForm.Init ( Object );
		if ( Parameters.Basis = undefined ) then
			fillNew ();
			fillByVendor ();
		else
			Base = Parameters.Basis;
			baseType = TypeOf ( Base );
			if ( baseType = Type ( "DocumentRef.SalesOrder" )
				or baseType = Type ( "DocumentRef.InternalOrder" ) ) then
				fillByOrder ();
			endif; 
		endif;
		updateBalanceDue ();
	endif; 
	setAccuracy ();
	setLinks ();
	ItemPictures.RestoreGallery ( ThisObject );
	Forms.ActivatePage ( ThisObject, "ItemsTable,Services" );
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|Rate Factor enable
	|filled ( LocalCurrency )
	|and filled ( ContractCurrency )
	|and ( Object.Currency <> LocalCurrency or ContractCurrency <> LocalCurrency );
	|CreatePayment show BalanceDue <> 0;
	|PicturesPanel show PicturesEnabled;
	|ItemsShowPictures press PicturesEnabled;
	|VAT show Object.VATUse > 0;
	|ItemsVATCode ItemsVAT ItemsTotal ServicesVATCode ServicesVAT ServicesTotal show Object.VATUse > 0
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Copy ) then
		return;
	endif; 
	if ( Object.Warehouse.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Warehouse" );
		Object.Company = settings.Company;
		Object.Warehouse = settings.Warehouse;
	else
		Object.Company = DF.Pick ( Object.Warehouse, "Owner" );
	endif;
	Object.Department = Logins.Settings ( "Department" ).Department;
	Object.Currency = Application.Currency ();
	
EndProcedure 

&AtServer
Procedure fillByVendor ()
	
	apply = Parameters.FillingValues.Property ( "Vendor" )
	and not Copy
	and not Object.Vendor.IsEmpty ();
	if ( apply ) then
		applyVendor ();
	endif;

EndProcedure 

&AtServer
Procedure applyVendor ()
	
	data = DF.Values ( Object.Vendor, "VendorContract, VATUse" );
	Object.Contract = data.VendorContract;
	Object.VATUse = data.VATUse;
	applyContract ();
	applyVATUse ();
	
EndProcedure

&AtServer
Procedure applyContract ()
	
	data = DF.Values ( Object.Contract, "VendorPrices, Currency, VendorDelivery as Delivery" );
	ContractCurrency = data.Currency;
	Object.Currency = ContractCurrency;
	Object.Prices = data.VendorPrices;
	currency = CurrenciesSrv.Get ( data.Currency, Object.Date );
	Object.Rate = currency.Rate;
	Object.Factor = currency.Factor;
	InvoiceForm.SetCurrencyList ( ThisObject );
	InvoiceForm.SetDelivery ( ThisObject, data );
	PaymentsTable.Fill ( Object );
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure

&AtClientAtServerNoContext
Procedure updateTotals ( Form, Row = undefined, CalcVAT = true )
	
	object = Form.Object;
	if ( Row <> undefined ) then
		Computations.Total ( Row, object.VATUse, CalcVAT );
	endif;
	items = object.Items;
	services = object.Services;
	vat = items.Total ( "VAT" )
	+ services.Total ( "VAT" );
	amount = items.Total ( "Total" )
	+ services.Total ( "Total" );
	object.VAT = vat;
	object.Amount = amount;
	object.Discount = items.Total ( "Discount" ) + services.Total ( "Discount" );
	object.GrossAmount = amount - ? ( object.VATUse = 2, vat, 0 ) + object.Discount;
	InvoiceForm.CalcBalanceDue ( Form );
	Appearance.Apply ( Form, "BalanceDue" );
	
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
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
EndProcedure

#region Filling

&AtServer
Procedure fillByOrder ()
	
	Object.Company = DF.Pick ( Base, "Company" );
	Object.Department = Logins.Settings ( "Department" ).Department;
	table = getAllocation ();
	loadAllocation ( table );
	updateTotals ( ThisObject );
	
EndProcedure 

&AtServer
Function getAllocation ()
	
	p = Filler.GetParams ();
	p.Report = "Allocation";
	filters = new Array ();
	item = DC.CreateFilter ( "DocumentOrder" );
	item.RightValue = Base;
	filters.Add ( item );
	p.Filters = filters;
	return FillerSrv.GetData ( p );
	
EndFunction 

&AtServer
Procedure loadAllocation ( Table )
	
	cache = new Map ();
	date = Object.Date;
	prices = Object.Prices;
	vendor = Object.Vendor;
	contract = Object.Contract;
	warehouse = Object.Warehouse;
	currency = Object.Currency;
	provision = Enums.Provision.Directly;
	salesOrder = Type ( "DocumentRef.SalesOrder" );
	services = Object.Services;
	itemsTable = Object.Items;
	vatUse = Object.VATUse;
	for each row in Table do
		item = row.Item;
		if ( row.ItemService ) then
			docRow = services.Add ();
			FillPropertyValues ( docRow, row );
			docRow.Description = DF.Pick ( item, "FullDescription" );
			package = undefined;
		else
			docRow = itemsTable.Add ();
			FillPropertyValues ( docRow, row );
			docRow.Provision = provision;
			docRow.QuantityPkg = row.QuantityPkgBalance;
			package = row.Package;
		endif;
		docRow.DocumentOrderRowKey = row.RowKey;
		docRow.Quantity = row.QuantityBalance;
		if ( TypeOf ( row.DocumentOrder ) = salesOrder ) then
			docRow.Price = Goods.Price ( cache, date, prices, item, package, row.Feature, vendor, contract, true, warehouse, currency );
		endif; 
		Computations.Amount ( docRow );
		Computations.Total ( docRow, vatUse );
	enddo; 
	
EndProcedure 

#endregion

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, ServicesQuantity" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
	
EndProcedure 

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Ref", Object.Ref );
		q.SetParameter ( "Contract", Object.Contract );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( isNew () ) then
		return;
	endif; 
	selection = Env.Selection;
	s = "
	|// #VendorInvoices
	|select Documents.Ref as Document,
	|	case when Documents.Ref.Reference = """" then Documents.Ref.Number else Documents.Ref.Reference end as Number,
	|	case when Documents.Ref.ReferenceDate = datetime ( 1, 1, 1 ) then Documents.Ref.Date else Documents.Ref.ReferenceDate end as Date
	|from (
	|	select Documents.Ref as Ref
	|	from Document.VendorInvoice as Documents
	|	where Documents.PurchaseOrder = &Ref
	|	union
	|	select Items.Ref
	|	from Document.VendorInvoice.Items as Items
	|	where Items.PurchaseOrder = &Ref
	|	union
	|	select Services.Ref
	|	from Document.VendorInvoice.Services as Services
	|	where Services.PurchaseOrder = &Ref
	|) as Documents
	|where not Documents.Ref.DeletionMark
	|order by Date
	|;
	|// #Payments
	|select Documents.Ref as Document, Documents.Date as Date,
	|	case when Documents.Reference = """" then Documents.Number else Documents.Reference end as Number
	|from Document.VendorPayment as Documents
	|where Documents.Ref in (
	|	select Documents.Ref as Ref
	|	from Document.VendorPayment as Documents
	|	where Documents.Contract = &Contract
	|	and Documents.Base = &Ref
	|	union
	|	select Documents.Ref as Ref
	|	from Document.VendorPayment.Payments as Documents
	|	where Documents.Contract = &Contract
	|	and &Ref in ( Documents.Detail, Documents.Document )
	|)
	|and not Documents.DeletionMark
	|";
	selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.VendorInvoices, meta.VendorInvoice ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.Payments, meta.VendorPayment ) );
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	elsif ( EventName = Enum.RefreshItemPictures () ) then
		ItemPictures.Refresh ( ThisObject );
	elsif ( EventName = Enum.MessageVendorPaymentIsSaved ()
		and Parameter.Contract = Object.Contract ) then
		updateLinks ();
		NotifyChanged ( Object.Ref );
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
		row.Price = Goods.Price ( , Object.Date, Object.Prices, item, package, feature, Object.Vendor, Object.Contract, true, Object.Warehouse, Object.Currency );
		data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
		row.VATCode = data.VAT;
		row.VATRate = data.Rate;
		row.Provision = PredefinedValue ( "Enum.Provision.Free" );
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	Computations.Amount ( row );
	updateTotals ( ThisObject, row );
	
EndProcedure 

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsPickItems () ) then
		addSelectedItems ( SelectedValue );
		addSelectedServices ( SelectedValue );
		updateTotals ( ThisObject );
	elsif ( operation = Enum.ChoiceOperationsAllocateItems () ) then
		allocateItem ( SelectedValue, false );
	elsif ( operation = Enum.ChoiceOperationsAllocateServices () ) then
		allocateItem ( SelectedValue, true );
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

&AtClient
Procedure allocateItem ( Params, Services )
	
	if ( Services ) then
		row = ServicesRow;
		table = Object.Services;
	else
		row = ItemsRow;
		table = Object.Items;
	endif; 
	result = Params.Result;
	FillPropertyValues ( row, result [ 0 ] );
	last = table.IndexOf ( row ) + 1;
	index = result.Ubound ();
	vatUse = Object.VATUse;
	while ( index > 0 ) do
		row = table.Insert ( last );
		FillPropertyValues ( row, result [ index ] );
		Computations.Total ( row, vatUse );
		index = index - 1;
	enddo; 
	updateTotals ( ThisObject, row );
	
EndProcedure 

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	type = TypeOf ( NewObject );
	alreadyProcessed = type = Type ( "DocumentRef.VendorPayment" );
	if ( alreadyProcessed ) then
		return;
	endif;
	updateLinks ();
	
EndProcedure

&AtServer
Procedure updateLinks ()
	
	setLinks ();
	updateBalanceDue ();

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	Forms.DeleteLastRow ( Object.Items, "Item" );
	Forms.DeleteLastRow ( Object.Services, "Item" );
	updateTotals ( ThisObject );
	PaymentsTable.Fix ( Object );
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( not setRowKeys ( CurrentObject ) ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

&AtServer
Function setRowKeys ( CurrentObject )
	
	error = not Catalogs.RowKeys.Set ( CurrentObject.Items, 1 );
	error = error or not Catalogs.RowKeys.Set ( CurrentObject.Services, 2 );
	return not error;
	
EndFunction

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	updateBalanceDue ();	
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessagePurchaseOrderIsSaved (), Object.Ref );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure VendorOnChange ( Item )
	
	applyVendor ();
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ContractOnChange ( Item )
	
	applyContract ();
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	updateTotals ( ThisObject );
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	InvoiceForm.SetRate ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure 

&AtClient
Procedure PricesOnChange ( Item )
	
	applyPrices ();
	updateTotals ( ThisObject );
	
EndProcedure

&AtServer
Procedure applyPrices ()
	
	cache = new Map ();
	date = Object.Date;
	prices = Object.Prices;
	vendor = Object.Vendor;
	contract = Object.Contract;
	warehouse = Object.Warehouse;
	currency = Object.Currency;
	vatUse = Object.VATUse;
	for each row in Object.Items do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, vendor, contract, true, warehouse, currency );
		Computations.Discount ( row );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	cache = new Map ();
	for each row in Object.Services do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, , row.Feature, vendor, contract, true, warehouse, currency );
		Computations.Discount ( row );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	
EndProcedure 

&AtClient
Procedure VATUseOnChange ( Item )
	
	applyVATUse ();
	updateTotals ( ThisObject );

EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure SelectItems ( Command )
	
	PickItems.Open ( ThisObject, pickParams () );
	
EndProcedure

&AtServer
Function pickParams ()
	
	return PickItems.GetParams ( ThisObject );
	
EndFunction 

&AtClient
Procedure AllocateItems ( Command )
	
	if ( ItemsRow = undefined ) then
		return;
	endif; 
	openAllocation ( false );
	
EndProcedure

&AtClient
Procedure openAllocation ( Services )
	
	if ( Services ) then
		rowIndex = Object.Services.IndexOf ( ServicesRow );
	else
		rowIndex = Object.Items.IndexOf ( ItemsRow );
	endif; 
	p = allocationParams ( rowIndex, Services );
	OpenForm ( "DataProcessor.Items.Form.ProvisionOrder", p, ThisObject );
	
EndProcedure 

&AtServer
Function allocationParams ( val RowIndex, val Services )
	
	p = new Structure ();
	p.Insert ( "Source", PickItems.GetParams ( ThisObject ) );
	p.Insert ( "Command", Enum.PickItemsCommandsAllocate () );
	p.Insert ( "Service", Services );
	tableRow = rowStructure ( RowIndex, Services );
	p.Insert ( "TableRow", tableRow );
	if ( Services ) then
		p.Insert ( "CountPackages", false );
	else
		p.Insert ( "CountPackages", DF.Pick ( tableRow.Item, "CountPackages" ) );
	endif; 
	return p;
	
EndFunction

&AtServer
Function rowStructure ( RowIndex, Services )
	
	table = ? ( Services, "Services", "Items" );
	row = new Structure ();
	for each item in Object.Ref.Metadata ().TabularSections [ table ].Attributes do
		row.Insert ( item.Name );
	enddo; 
	FillPropertyValues ( row, Object [ table ] [ RowIndex ] );
	return row;
	
EndFunction 

&AtClient
Procedure LoadOrders ( Command )
	
	Filler.Open ( fillingParams (), ThisObject );
	
EndProcedure

&AtServer
Function fillingParams ()
	
	p = Filler.GetParams ();
	p.Report = "Allocation";
	p.Filters = getFilters ();
	return p;
	
EndFunction

&AtServer
Function getFilters ()
	
	filters = new Array ();
	warehouse = Object.Warehouse;
	if ( not warehouse.IsEmpty () ) then
		filters.Add ( DC.CreateFilter ( "Warehouse", warehouse ) );
	endif; 
	vendor = Object.Vendor;
	if ( not vendor.IsEmpty () ) then
		filters.Add ( DC.CreateParameter ( "Vendor", vendor ) );
	endif; 
	item = DC.CreateParameter ( "Asof" );
	item.Value = Periods.GetBalanceDate ( Object );
	item.Use = ( item.Value <> undefined );
	filters.Add ( item );
	return filters;
	
EndFunction

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( not fillTables ( Result ) ) then
		Output.FillingDataNotFound ();
	endif;
	
EndProcedure 

&AtServer
Function fillTables ( val Result )
	
	table = Filler.Fetch ( Result );
	if ( table = undefined ) then
		return false;
	endif;
	if ( Result.ClearTable ) then
		Object.Items.Clear ();
		Object.Services.Clear ();
	endif; 
	loadAllocation ( table );
	updateTotals ( ThisObject );
	return true;
	
EndFunction

&AtClient
Procedure Scan ( Command )
	
	OpenForm ( "CommonForm.Scan", , ThisObject );
	
EndProcedure

&AtClient
Procedure ShowHidePictures ( Command )
	
	togglePictures ();
	
EndProcedure

&AtServer
Procedure togglePictures ()
	
	ItemPictures.Toggle ( ThisObject );
	
EndProcedure 

&AtClient
Procedure ResizeOnChange ( Item )
	
	ItemPictures.Refresh ( ThisObject );
	
EndProcedure

&AtClient
Procedure PictureOnClick ( Item, EventData, StandardProcessing )
	
	StandardProcessing = false;
	ItemPictures.ClickProcessing ( EventData.Element.id, UUID );
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	ShownProduct = ? ( ItemsRow = undefined, undefined, ItemsRow.Item );
	ItemPictures.Refresh ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	OrderRows.ResetProvision ( ItemsRow );
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Organization", Object.Vendor );
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
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, data.Package, , Params.Organization, Params.Contract, true, Params.Warehouse, Params.Currency );
	data.Insert ( "Price", price );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure ItemsFeatureOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	ItemsRow.Price = Goods.Price ( , Object.Date, prices, ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature, Object.Vendor, Object.Contract, true, Object.Warehouse, Object.Currency );
	
EndProcedure 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Organization", Object.Vendor );
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
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	price = Goods.Price ( , Params.Date, Params.Prices, Params.Item, package, Params.Feature, Params.Organization, Params.Contract, true, Params.Warehouse, Params.Currency );
	data = new Structure ();
	data.Insert ( "Capacity", capacity );
	data.Insert ( "Price", price );
	return data;
	
EndFunction 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPriceOnChange ( Item )

	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );

EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	Computations.Price ( ItemsRow );
	Computations.Discount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPricesOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsDiscountRateOnChange ( Item )
	
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsDiscountOnChange ( Item )
	
	Computations.DiscountRate ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsProvisionOnChange ( Item )
	
	OrderRows.ResetOrder ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsVATCodeOnChange ( Item )
	
	ItemsRow.VATRate = DF.Pick ( ItemsRow.VATCode, "Rate" );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsVATOnChange ( Item )
	
	updateTotals ( ThisObject, ItemsRow, false );
	
EndProcedure

// *****************************************
// *********** Table Services

&AtClient
Procedure AllocateServices ( Command )
	
	if ( ServicesRow = undefined ) then
		return;
	endif; 
	openAllocation ( true );
	
EndProcedure

&AtClient
Procedure ServicesOnActivateRow ( Item )
	
	ServicesRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ServicesOnEditEnd ( Item, NewRow, CancelEdit )
	
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ServicesAfterDeleteRow ( Item )
	
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ServicesItemOnChange ( Item )
	
	applyService ();
	
EndProcedure

&AtClient
Procedure applyService ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Organization", Object.Vendor );
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
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure 

&AtServerNoContext
Function getServiceData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "FullDescription, VAT, VAT.Rate as Rate" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, , , Params.Organization, Params.Contract, true, Params.Warehouse, Params.Currency );
	data.Insert ( "Price", price );
	return data;
	
EndFunction 

&AtClient
Procedure ServicesFeatureOnChange ( Item )
	
	priceService ();
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure priceService ()
	
	prices = ? ( ServicesRow.Prices.IsEmpty (), Object.Prices, ServicesRow.Prices );
	ServicesRow.Price = Goods.Price ( , Object.Date, prices, ServicesRow.Item, , ServicesRow.Feature, Object.Vendor, Object.Contract, true, Object.Warehouse, Object.Currency );
	
EndProcedure 

&AtClient
Procedure ServicesQuantityOnChange ( Item )
	
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesPriceOnChange ( Item )

	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );

EndProcedure

&AtClient
Procedure ServicesAmountOnChange ( Item )
	
	Computations.Price ( ServicesRow );
	Computations.Discount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesPricesOnChange ( Item )
	
	priceService ();
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesDiscountRateOnChange ( Item )
	
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesDiscountOnChange ( Item )
	
	Computations.DiscountRate ( ServicesRow );
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesVATCodeOnChange ( Item )
	
	ServicesRow.VATRate = DF.Pick ( ServicesRow.VATCode, "Rate" );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesVATOnChange ( Item )
	
	updateTotals ( ThisObject, ServicesRow, false );
	
EndProcedure

// *****************************************
// *********** Table Payments

&AtClient
Procedure CalcPayments ( Command )
	
	PaymentsTable.Calc ( Object );
	
EndProcedure
