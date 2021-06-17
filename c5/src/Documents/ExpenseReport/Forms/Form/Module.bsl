&AtServer
var Env;
&AtServer
var ViewCommissionings;
&AtServer
var ViewIntangibleAssetsCommissionings;
&AtServer
var Base;
&AtServer
var BaseType;
&AtClient
var ItemsRow;
&AtClient
var ServicesRow;
&AtClient
var AccountsRow;
&AtClient
var AccountData;
&AtClient
var PaymentsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	InvoiceForm.SetLocalCurrency ( ThisObject );
	setSocial ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	ref = Object.Ref;
	if ( isNew () ) then
		Base = Parameters.Basis;
		сopy = not Parameters.CopyingValue.IsEmpty ();
		InvoiceForm.SetLocalCurrency ( ThisObject );
		DocumentForm.Init ( Object );
		if ( Base = undefined ) then
			if ( not сopy ) then
				fillNew ();
			endif;
		else
			BaseType = TypeOf ( Base );
			if ( BaseType = Type ( "DocumentRef.InternalOrder" )
				or BaseType = Type ( "DocumentRef.SalesOrder" ) ) then
				fillByOrder ();
			endif; 
		endif;
		if ( not сopy ) then
			setAccount ();
		endif;
	endif;
	setLinks ();
	filterPayments ( ref );
	if ( not isNew () ) then
		setPaymentsCount ( PaymentsCount, ref );
	endif;
	setAccuracy ();
	setSocial ();
	Forms.ActivatePage ( ThisObject, "ItemsTable,Services,FixedAssets,IntangibleAssets,Accounts" );
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
	|Rate Factor enable
	|filled ( LocalCurrency )
	|and ( Object.Currency <> LocalCurrency );
	|Write show empty ( Object.Ref );
	|Payments enable filled ( Object.Ref );
	|Links show ShowLinks;
	|VAT ItemsVATAccount ServicesVATAccount FixedAssetsVATAccount IntangibleAssetsVATAccount AccountsVATAccount show Object.VATUse > 0;
	|ItemsVATCode ItemsVAT ItemsTotal ServicesVATCode ServicesVAT ServicesTotal FixedAssetsVATCode FixedAssetsVAT FixedAssetsTotal IntangibleAssetsVATCode IntangibleAssetsVAT IntangibleAssetsTotal AccountsVATCode AccountsVAT AccountsTotal show Object.VATUse > 0;
	|ItemsProducerPrice show UseSocial
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Object.Warehouse.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Warehouse" );
		Object.Company = settings.Company;
		Object.Warehouse = settings.Warehouse;
	else
		Object.Company = DF.Pick ( Object.Warehouse, "Owner" );
	endif;
	Object.Currency = Application.Currency ();
	
EndProcedure

#region Filling

&AtServer
Procedure fillByOrder ()
	
	setEnv ();
	sqlOrder ();
	SQL.Perform ( Env );
	headerByOrder ();
	if ( BaseType = Type ( "DocumentRef.InternalOrder" ) ) then
		table = FillerSrv.GetData ( fillingParams ( "InternalOrders", Base ) );
		loadInternalOrders ( table );
	else
		table = FillerSrv.GetData ( fillingParams ( "SalesOrderItems", Base ) );
		loadSalesOrders ( table );
	endif; 
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure 

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	
EndProcedure

&AtServer
Procedure sqlOrder ()
	
	if ( BaseType = Type ( "DocumentRef.InternalOrder" ) ) then
		name = "InternalOrder";
	else
		name = "SalesOrder";
	endif; 
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.Currency as Currency, Documents.Prices as Prices,
	|	Documents.VATUse as VATUse, Documents.Warehouse as Warehouse
	|from Document." + name + " as Documents
	|where Documents.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByOrder ()
	
	FillPropertyValues ( Object, Env.Fields );
	setRates ( Object, Object.Currency, Object.Date );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setRates ( Source, Currency, Date = undefined ) 

	rates = CurrenciesSrv.Get ( Currency, Date );
	Source.Rate = rates.Rate;
	Source.Factor = rates.Factor;

EndProcedure

&AtServer
Function fillingParams ( val Report, val BaseDocument )
	
	p = Filler.GetParams ();
	p.Report = Report;
	if ( Report = Metadata.Reports.SalesOrderItems.Name ) then
		p.Variant = "#FillVendorInvoice";
	endif; 
	p.Filters = getFilters ( Report, BaseDocument );
	return p;
	
EndFunction

&AtServer
Function getFilters ( Report, BaseDocument )
	
	warehouse = Object.Warehouse;
	filters = new Array ();
	if ( BaseDocument = undefined ) then
		if ( not warehouse.IsEmpty () ) then
			filters.Add ( DC.CreateFilter ( "Warehouse", warehouse ) );
		endif; 
	else
		if ( Report = Metadata.Reports.InternalOrders.Name ) then
			filters.Add ( DC.CreateFilter ( "InternalOrder", BaseDocument ) );
		else
			filters.Add ( DC.CreateFilter ( "SalesOrder", BaseDocument ) );
		endif;
	endif;
	item = DC.CreateParameter ( "ReportDate" );
	item.Value = Catalogs.Calendar.GetDate ( Periods.GetBalanceDate ( Object ) );
	item.Use = not item.Value.IsEmpty ();
	filters.Add ( item );
	return filters;
	
EndFunction

&AtServer
Procedure loadInternalOrders ( Table )
	
	company = Object.Company;
	warehouses = Options.WarehousesInTable ( company );
	warehouse = Object.Warehouse;
	services = Object.Services;
	tableItems = Object.Items;
	vatUse = Object.VATUse;
	for each row in Table do
		if ( row.ItemService = null ) then
			continue;
		endif;
		if ( row.ItemService ) then
			docRow = services.Add ();
			FillPropertyValues ( docRow, row );
			item = row.Item;
			accounts = AccountsMap.Item ( item, company, warehouse, "VAT" );
			docRow.VATAccount = accounts.VAT;
		else
			docRow = tableItems.Add ();
			FillPropertyValues ( docRow, row );
			Computations.Packages ( docRow );
			if ( warehouses
				and docRow.Warehouse = warehouse ) then
				docRow.Warehouse = undefined;
			endif; 
			accounts = AccountsMap.Item ( docRow.Item, company, warehouse, "Account, VAT" );
			docRow.Account = accounts.Account;
			docRow.VATAccount = accounts.VAT;
		endif; 
		Computations.Amount ( docRow );
		Computations.Total ( docRow, vatUse );
		docRow.DocumentOrder = row.InternalOrder;
		docRow.DocumentOrderRowKey = row.RowKey;
	enddo; 
	
EndProcedure 

&AtServer
Procedure loadSalesOrders ( Table )
	
	company = Object.Company;
	warehouses = not Options.WarehousesInTable ( company );
	warehouse = Object.Warehouse;
	services = Object.Services;
	tableItems = Object.Items;
	for each row in Table do
		if ( row.ItemService = null ) then
			continue;
		endif;
		if ( row.ItemService ) then
			docRow = services.Add ();
			FillPropertyValues ( docRow, row );
			item = row.Item;
			accounts = AccountsMap.Item ( item, company, warehouse, "VAT" );
			docRow.VATAccount = accounts.VAT;
		else
			docRow = tableItems.Add ();
			FillPropertyValues ( docRow, row );
			if ( warehouses
				or docRow.Warehouse = warehouse ) then
				docRow.Warehouse = undefined;
			endif; 
			accounts = AccountsMap.Item ( docRow.Item, company, warehouse, "Account, VAT" );
			docRow.Account = accounts.Account;
			docRow.VATAccount = accounts.VAT;
		endif;
		docRow.DocumentOrder = row.SalesOrder;
		docRow.DocumentOrderRowKey = row.RowKey;
	enddo; 
	
EndProcedure 

#endregion

&AtServer
Procedure setAccount () 

	info = InformationRegisters.Settings.GetLast ( , new Structure ( "Parameter", ChartsOfCharacteristicTypes.Settings.ExpenseReportAccount ) );
	Object.EmployeeAccount = info.Value;

EndProcedure

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		Env.Q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( env );
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
	meta = Metadata.Documents;
	ViewCommissionings = AccessRight ( "View", meta.Commissioning );
	if ( ViewCommissionings ) then
		s = "
		|// #Commissionings
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.Commissioning as Documents
		|where Documents.Base = &Ref
		|and not Documents.DeletionMark
		|";
		selection.Add ( s );
	endif;
	ViewIntangibleAssetsCommissionings = AccessRight ( "View", meta.IntangibleAssetsCommissioning );
	if ( ViewIntangibleAssetsCommissionings ) then
		s = "
		|// #IntangibleAssetsCommissionings
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.IntangibleAssetsCommissioning as Documents
		|where Documents.Base = &Ref
		|and not Documents.DeletionMark
		|";
		selection.Add ( s );
	endif; 
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not isNew () ) then
		if ( ViewCommissionings ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.Commissionings, meta.Commissioning ) );
		endif; 
		if ( ViewIntangibleAssetsCommissionings ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.IntangibleAssetsCommissionings, meta.IntangibleAssetsCommissioning ) );
		endif; 
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
Procedure filterPayments ( Ref ) 

	Payments.Parameters.SetParameterValue ( "Ref", Ref );

EndProcedure

&AtServerNoContext
Procedure setPaymentsCount ( PaymentsCount, Ref ) 

	s = "
	|select count ( 1 ) as Count
	|from Document.VendorPayment as Documents
	|where Documents.ExpenseReport = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	table = q.Execute ().Unload ();
	PaymentsCount = ? ( table.Count () = 0, 0, table [ 0 ].Count );

EndProcedure

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, ServicesQuantity, AccountsQuantity" );
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
	Forms.DeleteLastRow ( Object.FixedAssets, "Item" );
	Forms.DeleteLastRow ( Object.IntangibleAssets, "Item" );
	Forms.DeleteLastRow ( Object.Accounts, "Account" );
	calcTotals ( Object );
	
EndProcedure

&AtClientAtServerNoContext
Procedure calcTotals ( Object )
	
	items = Object.Items;
	services = Object.Services;
	accounts = Object.Accounts;
	fixedAssets = Object.FixedAssets;
	intangibleAssets = Object.IntangibleAssets;
	vat = items.Total ( "VAT" )
	+ services.Total ( "VAT" )
	+ accounts.Total ( "VAT" )
	+ fixedAssets.Total ( "VAT" )
	+ intangibleAssets.Total ( "VAT" );
	amount = items.Total ( "Total" )
	+ services.Total ( "Total" )
	+ accounts.Total ( "Total" )
	+ fixedAssets.Total ( "Total" )
	+ intangibleAssets.Total ( "Total" );
	Object.VAT = vat;
	Object.Amount = amount;
	Object.Discount = items.Total ( "Discount" ) + services.Total ( "Discount" );
	Object.GrossAmount = amount - ? ( Object.VATUse = 2, vat, 0 ) + Object.Discount;
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( Object.Ref.IsEmpty () ) then
		filterPayments ( CurrentObject.Ref );
	endif;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
		applySocial ();
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
		warehouse = Object.Warehouse;
		row.Price = Goods.Price ( , Object.Date, Object.Prices, item, package, feature, , , , warehouse, Object.Currency );
		accounts = AccountsMap.Item ( item, Object.Company, warehouse, "Account, VAT" );
		row.Account = accounts.Account;
		row.VATAccount = accounts.VAT;
		data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
		row.VATCode = data.VAT;
		row.VATRate = data.Rate;
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	Computations.Amount ( row );
	Computations.Total ( row, Object.VATUse );
	calcTotals ( Object );
	
EndProcedure 

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsFixedAsset () ) then
		loadRow ( SelectedValue, Items.FixedAssets );
	elsif ( operation = Enum.ChoiceOperationsIntangibleAsset () ) then
		loadRow ( SelectedValue, Items.IntangibleAssets );
	elsif ( operation = Enum.ChoiceOperationsFixedAssetSaveAndNew () ) then
		loadAndNew ( SelectedValue, Items.FixedAssets );
	elsif ( operation = Enum.ChoiceOperationsIntangibleAssetSaveAndNew () ) then
		loadAndNew ( SelectedValue, Items.IntangibleAssets );	
	elsif ( operation = Enum.ChoiceOperationsPickItems () ) then
		addSelectedItems ( SelectedValue );
		addSelectedServices ( SelectedValue );
		calcTotals ( Object );
		applySocial ();
	endif;
	
EndProcedure

&AtClient
Procedure loadRow ( Params, Table )
	
	value = Params.Value;
	if ( value = undefined ) then
		if ( Params.NewRow ) then
			Object [ Table.Name ].Delete ( Table.CurrentData );
		endif;
	else
		data = Table.CurrentData;
		FillPropertyValues ( data, value );
		calcTotals ( Object );
	endif;
	
EndProcedure

&AtClient
Procedure loadAndNew ( Result, Table ) 

	loadRow ( Result, Table );	
	newRow ( Table, false );

EndProcedure

&AtClient
Procedure newRow ( Item, Clone )
	
	Forms.NewRow ( ThisObject, Item, Clone );
	editRow ( Item, true );
	
EndProcedure

&AtClient
Procedure editRow ( Table, NewRow = false )
	
	if ( Table.CurrentData = undefined ) then
		return;
	endif; 
	p = new Structure ();
	p.Insert ( "Company", Object.Company );
	p.Insert ( "NewRow", NewRow );
	if ( Table = Items.FixedAssets ) then
		form = "Document.ExpenseReport.Form.FixedAsset";
	else
		form = "Document.ExpenseReport.Form.IntangibleAsset";
	endif; 
	OpenForm ( form, p, ThisObject );
	
EndProcedure 

&AtClient
Procedure addSelectedItems ( Params )
	
	tableItems = Object.Items;
	for each selectedRow in Params.Items do
		row = tableItems.Add ();
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
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure PricesOnChange ( Item )
	
	applyPrices ();
	
EndProcedure

&AtServer
Procedure applyPrices ()
	
	prices = Object.Prices;
	date = Object.Date;
	warehouse = Object.Warehouse;
	currency = Object.Currency;
	vatUse = Object.VATUse;
	cache = new Map ();
	for each row in Object.Items do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, , , , warehouse, currency );
		Computations.Discount ( row );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	cache = new Map ();
	for each row in Object.Services do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, , row.Feature, , , , warehouse, currency );
		Computations.Discount ( row );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	calcTotals ( Object );
	
EndProcedure 

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	OpenForm ( "CommonForm.Scan", , ThisObject );
	
EndProcedure

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( not fillTables ( Result, Params.Report ) ) then
		Output.FillingDataNotFound ();
	endif;
	
EndProcedure 

&AtServer
Function fillTables ( val Result, val Report )
	
	table = Filler.Fetch ( Result );
	if ( table = undefined ) then
		return false;
	endif;
	if ( Result.ClearTable ) then
		Object.Items.Clear ();
		Object.Services.Clear ();
	endif; 
	meta = Metadata.Reports;
	if ( Report = meta.InternalOrders.Name ) then
		loadInternalOrders ( table );
	elsif ( Report = meta.SalesOrderItems.Name ) then
		loadSalesOrders ( table );
	endif; 
	calcTotals ( Object );
	return true;
	
EndFunction

&AtClient
Procedure ApplySalesOrders ( Command )
	
	Filler.Open ( fillingParams ( "SalesOrderItems", undefined ), ThisObject );
	
EndProcedure

&AtClient
Procedure ApplyInternalOrders ( Command )
	
	Filler.Open ( fillingParams ( "InternalOrders", undefined ), ThisObject );
	
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
	enableSocial ();
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	applySocial ();
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	applySocial ();
	enableSocial ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	ItemsRow.Account = data.Account;
	ItemsRow.VATCode = data.VAT;
	ItemsRow.VATRate = data.Rate;
	ItemsRow.VATAccount = data.VATAccount;
	ItemsRow.Social = data.Social;
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	warehouse = Params.Warehouse;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate, Social" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, data.Package, , , , , warehouse, Params.Currency );
	accounts = AccountsMap.Item ( item, Params.Company, warehouse, "Account, VAT" );
	data.Insert ( "Price", price );
	data.Insert ( "Account", accounts.Account );
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
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	ItemsRow.Price = Goods.Price ( , Object.Date, prices, ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature, , , , Object.Warehouse, Object.Currency );
	
EndProcedure 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
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
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	price = Goods.Price ( , Params.Date, Params.Prices, Params.Item, package, Params.Feature, , , , Params.Warehouse, Params.Currency );
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
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ServicesAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ServicesItemOnChange ( Item )
	
	applyService ();
	
EndProcedure

&AtClient
Procedure applyService ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Warehouse", Object.Warehouse );
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
	warehouse = Params.Warehouse;
	price = Goods.Price ( , Params.Date, Params.Prices, item, , , , , , warehouse, Params.Currency );
	accounts = AccountsMap.Item ( item, Params.Company, warehouse, "VAT" );
	data.Insert ( "Price", price );
	data.Insert ( "VATAccount", accounts.VAT );
	return data;
	
EndFunction 

&AtClient
Procedure ServicesFeatureOnChange ( Item )
	
	priceService ();
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure priceService ()
	
	prices = ? ( ServicesRow.Prices.IsEmpty (), Object.Prices, ServicesRow.Prices );
	ServicesRow.Price = Goods.Price ( , Object.Date, prices, ServicesRow.Item, , ServicesRow.Feature, , , , Object.Warehouse, Object.Currency );
	
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
// *********** Group FixedAssets

&AtClient
Procedure Edit ( Command )
	
	if ( Items.Pages.CurrentPage = Items.GroupFixedAssets ) then
		editRow ( Items.FixedAssets );
	else
		editRow ( Items.IntangibleAssets );
	endif; 
	
EndProcedure

&AtClient
Procedure FixedAssetsBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure FixedAssetsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	editRow ( Item );
	
EndProcedure

&AtClient
Procedure FixedAssetsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	newRow ( Item, Clone );
	
EndProcedure

&AtClient
Procedure FixedAssetsAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

// *****************************************
// *********** Group IntangibleAssets

&AtClient
Procedure IntangibleAssetsBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure IntangibleAssetsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	editRow ( Item );
	
EndProcedure

&AtClient
Procedure IntangibleAssetsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	newRow ( Item, Clone );
	
EndProcedure

&AtClient
Procedure IntangibleAssetsAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

// *****************************************
// *********** Group Accounts

&AtClient
Procedure AccountsOnActivateRow ( Item )
	
	AccountsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure AccountsOnEditEnd ( Item, NewRow, CancelEdit )
	
	resetDims ();
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure resetDims ()
	
	Items.AccountsQuantity.ReadOnly = false;
	Items.AccountsCurrency.ReadOnly = false;
	Items.AccountsCurrencyAmount.ReadOnly = false;
	Items.AccountsRate.ReadOnly = false;
	Items.AccountsFactor.ReadOnly = false;
	Items.AccountsDim1.ReadOnly = false;
	Items.AccountsDim2.ReadOnly = false;
	Items.AccountsDim3.ReadOnly = false;
	
EndProcedure 

&AtClient
Procedure AccountsAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure AccountsBeforeRowChange ( Item, Cancel )
	
	readAccount ();
	enableDims ();
	
EndProcedure

&AtClient
Procedure readAccount ()
	
	AccountData = GeneralAccounts.GetData ( AccountsRow.Account );
	
EndProcedure 

&AtClient
Procedure enableDims ()
	
	fields = AccountData.Fields;
	local = not fields.Currency;
	Items.AccountsQuantity.ReadOnly = not fields.Quantitative;
	Items.AccountsCurrency.ReadOnly = local;
	Items.AccountsCurrencyAmount.ReadOnly = local;
	Items.AccountsRate.ReadOnly = local;
	Items.AccountsFactor.ReadOnly = local;
	level = fields.Level;
	for i = 1 to 3 do
		disable = ( level < i );
		Items [ "AccountsDim" + i ].ReadOnly = disable;
	enddo; 
	
EndProcedure 

&AtClient
Procedure AccountsAccountOnChange ( Item )
	
	readAccount ();
	adjustDims ();
	enableDims ();
	
EndProcedure

&AtClient
Procedure adjustDims ()
	
	fields = AccountData.Fields;
	dims = AccountData.Dims;
	if ( not fields.Quantitative ) then
		AccountsRow.Quantity = 0;
	endif; 
	if ( not fields.Currency ) then
		AccountsRow.Currency = undefined;
		AccountsRow.CurrencyAmount = 0;
		AccountsRow.Rate = 0;
		AccountsRow.Factor = 0;
	endif; 
	level = fields.Level;
	if ( level = 0 ) then
		AccountsRow.Dim1 = undefined;
		AccountsRow.Dim2 = undefined;
		AccountsRow.Dim3 = undefined;
	elsif ( level = 1 ) then
		AccountsRow.Dim1 = dims [ 0 ].ValueType.AdjustValue ( AccountsRow.Dim1 );
		AccountsRow.Dim2 = undefined;
		AccountsRow.Dim3 = undefined;
	elsif ( level = 2 ) then
		AccountsRow.Dim1 = dims [ 0 ].ValueType.AdjustValue ( AccountsRow.Dim1 );
		AccountsRow.Dim2 = dims [ 1 ].ValueType.AdjustValue ( AccountsRow.Dim2 );
		AccountsRow.Dim3 = undefined;
	else
		AccountsRow.Dim1 = dims [ 0 ].ValueType.AdjustValue ( AccountsRow.Dim1 );
		AccountsRow.Dim2 = dims [ 1 ].ValueType.AdjustValue ( AccountsRow.Dim2 );
		AccountsRow.Dim3 = dims [ 2 ].ValueType.AdjustValue ( AccountsRow.Dim3 );
	endif; 

EndProcedure 

&AtClient
Procedure AccountsDim1StartChoice ( Item, ChoiceData, StandardProcessing )
	
	chooseDimension ( Item, 1, StandardProcessing );
	
EndProcedure

&AtClient
Procedure chooseDimension ( Item, Level, StandardProcessing )
	
	p = Dimensions.GetParams ();
	p.Company = Object.Company;
	p.Level = Level;
	p.Dim1 = AccountsRow.Dim1;
	p.Dim2 = AccountsRow.Dim2;
	p.Dim3 = AccountsRow.Dim3;
	Dimensions.Choose ( p, Item, StandardProcessing );
	
EndProcedure 

&AtClient
Procedure AccountsDim2StartChoice ( Item, ChoiceData, StandardProcessing )
	
	chooseDimension ( Item, 2, StandardProcessing );
	
EndProcedure

&AtClient
Procedure AccountsDim3StartChoice ( Item, ChoiceData, StandardProcessing )
	
	chooseDimension ( Item, 3, StandardProcessing );
	
EndProcedure

&AtClient
Procedure AccountsCurrencyOnChange ( Item )
	
	setRates ( AccountsRow, AccountsRow.Currency, Object.Date );
	calcAmount ();
	Computations.Total ( AccountsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure calcAmount ()
	
	AccountsRow.Amount = AccountsRow.CurrencyAmount * AccountsRow.Rate / AccountsRow.Factor;
	
EndProcedure 

&AtClient
Procedure AccountsRateOnChange ( Item )
	
	calcAmount ();
	Computations.Total ( AccountsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure AccountsFactorOnChange ( Item )
	
	calcAmount ();
	Computations.Total ( AccountsRow, Object.VATUse );

EndProcedure

&AtClient
Procedure AccountsCurrencyAmountOnChange ( Item )
	
	calcAmount ();
	Computations.Total ( AccountsRow, Object.VATUse );
	
EndProcedure

// *****************************************
// *********** Group More

&AtClient
Procedure CurrencyOnChange ( Item )
	
	setRates ( Object, Object.Currency );
	calcTotals ( Object );
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure

// *****************************************
// *********** Table Payments

&AtClient
Procedure PaymentsOnChange ( Item )
	
	setPaymentsCount ( PaymentsCount, Object.Ref );
	
EndProcedure

&AtClient
Procedure PaymentsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	if ( Clone ) then
		openVendorPayment ( new Structure ( "CopyingValue", PaymentsRow.Ref ) );
	else
		values = new Structure ();
		values.Insert ( "ExpenseReport", Object.Ref );
		openVendorPayment ( new Structure ( "FillingValues", values ) );
	endif;
	
EndProcedure

&AtClient
Procedure openVendorPayment ( Params ) 

	OpenForm ( "Document.VendorPayment.ObjectForm", Params, , , , , , FormWindowOpeningMode.LockOwnerWindow );

EndProcedure

&AtClient
Procedure PaymentsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	openVendorPayment ( new Structure ( "Key", SelectedRow ) );
	
EndProcedure

&AtClient
Procedure PaymentsBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	openVendorPayment ( new Structure ( "Key", PaymentsRow.Ref ) );
	
EndProcedure

&AtClient
Procedure PaymentsOnActivateRow ( Item )
	
	PaymentsRow = Item.CurrentData;
	
EndProcedure

&AtServer
Procedure setSocial () 

	UseSocial = findSocial ( Object.Items );

EndProcedure

&AtClientAtServerNoContext
Function findSocial ( Items ) 

	for each row in Items do
		if ( row.Social ) then
			return true;
		endif;
	enddo;
	return false;

EndFunction

&AtClient
Procedure applySocial () 

	UseSocial = findSocial ( Object.Items );
	Appearance.Apply ( ThisObject, "UseSocial" );

EndProcedure

&AtClient
Procedure VATUseOnChange ( Item )
	
	applyVATUse ();
	
EndProcedure

&AtClient
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
	for each row in Object.FixedAssets do
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.IntangibleAssets do
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.Accounts do
		Computations.Total ( row, vatUse );
	enddo;
	calcTotals ( Object );
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
EndProcedure

&AtClient
Procedure enableSocial () 

	if ( ItemsRow = undefined ) then
		return;
	endif;
	Items.ItemsProducerPrice.ReadOnly = not ItemsRow.Social;

EndProcedure

&AtClient
Procedure ItemsBeforeRowChange ( Item, Cancel )
	
	enableSocial ();
	
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

&AtClient
Procedure AccountsVATCodeOnChange ( Item )
	
	AccountsRow.VATRate = DF.Pick ( AccountsRow.VATCode, "Rate" );
	Computations.Total ( AccountsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure AccountsVATOnChange ( Item )
	
	Computations.Total ( AccountsRow, Object.VATUse, false );
	
EndProcedure

&AtClient
Procedure AccountsAmountOnChange ( Item )
	
	Computations.Total ( AccountsRow, Object.VATUse );
	
EndProcedure
