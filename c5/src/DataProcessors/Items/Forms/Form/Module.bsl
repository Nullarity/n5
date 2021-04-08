&AtClient
var Cache;
&AtClient
var SelectedRow;
&AtClient
var SelectionFinished;
&AtClient
var ItemsExist;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	initOptions ();
	initLists ();
	initFilters ();
	setPeriod ();
	Options.SetAccuracy ( ThisObject, "ItemsListQuantity, CharsListQuantity, PackagesListQuantity, ItemWarehousesQuantity, SelectedItemsQuantityPkg,
	|SelectedItemsQuantity, SelectedServicesQuantity, PackagesListCapacity, WarehousesBalanceReserve, ItemsListReserve", , false );
	createTables ();
	Options.Company ( ThisObject, Source.Company );
	readAppearance ();
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Prices show ShowPrices;
	|GroupSelectedItems show ShowItems;
	|GroupSelectedServices show ShowItems and not ItemsOnly;
	|ShowPrices show ShowAmount;
	|ItemsListReserve PackagesListReserve FeaturesListReserve show ShowReserves;
	|ShowReserves enable ( Filter = FilterNone or Filter = FilterAvailableOnly );
	|SelectedItemsDiscountRate SelectedItemsDiscount SelectedServicesDiscountRate SelectedServicesDiscount show Discounts;
	|SelectedItemsPrice SelectedItemsAmount SelectedServicesPrice SelectedServicesAmount show ShowAmount;
	|WarehousesBalanceReserve show ShowReserves;
	|SelectedItemsVATCode SelectedItemsVAT SelectedItemsTotal SelectedServicesVATCode SelectedServicesVAT SelectedServicesTotal show ( ShowAmount and VATUse > 0 );
	|SelectedItemsProducerPrice show
	|( ShowPrices
	|	and ShowSocial
	|	and UseSocial );
	|SelectedItemsExtraCharge show
	|( ShowPrices
	|	and ShowExtraCharge
	|	and UseSocial )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadParams ()
	
	Source = Parameters.Source;
	Warehouse = Source.Warehouse;
	Date = Source.Date;
	Prices = Source.Prices;
	Discounts = Source.Discounts;
	ItemsOnly = Source.ItemsOnly;
	ShowAmount = Source.ShowAmount;
	VATUse = Source.VATUse;
	setSocial ();
	
EndProcedure

&AtServer
Procedure initOptions ()
	
	Features = Options.Features ();
	
EndProcedure 

&AtServer
Procedure initLists ()
	
	p = ItemsList.Parameters;
	p.SetParameterValue ( "Warehouse", Warehouse );
	if ( Source.ItemsOnly ) then
		p.SetParameterValue ( "ItemsOnly", false );
	endif; 
	p = FeaturesList.Parameters;
	p.SetParameterValue ( "Item", undefined );
	p.SetParameterValue ( "Features", undefined );
	p.SetParameterValue ( "Warehouse", Warehouse );
	p = PackagesList.Parameters;
	p.SetParameterValue ( "Warehouse", Warehouse );
	p.SetParameterValue ( "Item", undefined );
	p.SetParameterValue ( "Feature", undefined );
	
EndProcedure

&AtServer
Procedure initFilters () 

	FilterNone = 0;
	FilterAvailableOnly = 1;
	FilterReserveOnly = 2;

EndProcedure

&AtServer
Procedure setPeriod ()
	
	period = ? ( Date = Date ( 1, 1, 1 ), undefined, Date );
	ItemsList.Parameters.SetParameterValue ( "Period", period );
	FeaturesList.Parameters.SetParameterValue ( "Period", period );
	PackagesList.Parameters.SetParameterValue ( "Period", period );
	
EndProcedure

&AtServer
Procedure createTables ()
	
	meta = Source.Ref.Metadata ().TabularSections;
	columns = new Array ();
	for each column in meta.Items.Attributes do
		columns.Add ( new FormAttribute ( column.Name, column.Type, "OwnerItems" ) );
	enddo; 
	if ( meta.Find ( "Services" ) <> undefined ) then
		for each column in meta.Services.Attributes do
			columns.Add ( new FormAttribute ( column.Name, column.Type, "OwnerServices" ) );
		enddo; 
	endif; 
	ChangeAttributes ( columns );
	
EndProcedure 

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer ( Settings )
	
	fixSettings ( Settings );
	
EndProcedure

&AtServer
Procedure fixSettings ( Settings )
	
	if ( Settings [ "ShowPrices" ] <> undefined
		and not Source.ShowPrice ) then
		Settings.Delete ( "ShowPrices" );
	endif;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer ( Settings )
	
	filterByBalances ( Filter );
	
EndProcedure

&AtServer
Procedure filterByBalances ( val Setup )
	
	filterItems ( Setup );
	DC.ChangeFilter ( PackagesList, "Quantity", 0, Setup = FilterAvailableOnly, DataCompositionComparisonType.Greater );
	
EndProcedure 

&AtServer
Procedure filterItems ( Setup )
	
	DC.DeleteFilter ( ItemsList, "Quantity" );
	DC.DeleteFilter ( ItemsList, "IsReserve" );
	DC.DeleteFilter ( ItemsList, "Service" );
	DC.DeleteFilter ( FeaturesList, "Quantity" );
	DC.DeleteFilter ( FeaturesList, "Ref.Owner.Service" );
	DC.DeleteFilter ( FeaturesList, "Ref" );
	if ( Setup = FilterNone ) then
		return;
	elsif ( Setup = FilterAvailableOnly ) then
		set = getFilterGroup ( ItemsList );
		item = set.Items.Add ( Type ( "DataCompositionFilterItem" ) );
		item.Use = true;
		item.LeftValue = new DataCompositionField ( "Quantity" );
		item.ComparisonType = DataCompositionComparisonType.Greater;
		item.RightValue = 0;
		item = set.Items.Add ( Type ( "DataCompositionFilterItem" ) );
		item.Use = true;
		item.LeftValue = new DataCompositionField ( "Service" );
		item.RightValue = true;
		set = getFilterGroup ( FeaturesList );
		item = set.Items.Add ( Type ( "DataCompositionFilterItem" ) );
		item.Use = true;
		item.LeftValue = new DataCompositionField ( "Quantity" );
		item.ComparisonType = DataCompositionComparisonType.Greater;
		item.RightValue = 0;
		////item = set.Items.Add ( Type ( "DataCompositionFilterItem" ) );
		////item.Use = true;
		////item.LeftValue = new DataCompositionField ( "Ref.Owner.Service" );
		////item.RightValue = true;
		item = set.Items.Add ( Type ( "DataCompositionFilterItem" ) );
		item.Use = true;
		item.LeftValue = new DataCompositionField ( "Ref" );
		item.RightValue = PredefinedValue ( "Catalog.Features.EmptyRef" );
	elsif ( Setup = FilterReserveOnly ) then
		DC.AddFilter ( ItemsList, "IsReserve", true );
	endif; 
	
EndProcedure

&AtServer
Function getFilterGroup ( Source ) 

	set = Source.Filter.Items.Add ( Type ( "DataCompositionFilterItemGroup" ) );
	set.Use = true;
	set.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	set.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	return set;

EndFunction

&AtClient
Procedure OnOpen ( Cancel )
	
	initCache ();
	initFlags ();
	Appearance.Apply ( ThisObject );
	
EndProcedure
 
&AtClient
Procedure initCache ()
	
	Cache = new Structure ( "Prices, Rows", new Map (), new Map () );
	
EndProcedure

&AtClient
Procedure initFlags ()
	
	ItemsExist = false;
	SelectionFinished = false;
	
EndProcedure 

&AtClient
Procedure ChoiceProcessing ( Result, ChoiceSource )
	
	addRows ( Result );
	showNotification ();
	Appearance.Apply ( ThisObject, "UseSocial" );
	
EndProcedure

&AtClient
Procedure addRows ( Rows )
	
	if ( SelectedRow.Service ) then
		table = OwnerServices;
		commonTable = Object.SelectedServices;
		commonKeys = "Feature, DiscountRate, Item, Price, VATCode";
		keys = Source.Keys.ServiceKeys;
	else
		table = OwnerItems;
		commonTable = Object.SelectedItems;
		commonKeys = "Feature, DiscountRate, Item, Package, Price, VATCode";
		keys = Source.Keys.ItemKeys;
	endif;
	set = getArray ( Rows );
	completeTable ( table, set, keys );
	completeTable ( commonTable, set, commonKeys );
	
EndProcedure

&AtClient
Function getArray ( Rows )
	
	if ( TypeOf ( Rows ) = Type ( "Array" ) ) then
		return Rows;
	endif;
	a = new Array ();
	a.Add ( Rows );
	return a;
	
EndFunction 

&AtClient
Procedure completeTable ( Table, Rows, Keys )
	
	search = getSearch ( Rows, Keys );
	for each row in Rows do
		FillPropertyValues ( search, row );
		result = Table.FindRows ( search );
		if ( result.Count () = 0 ) then
			tableRow = Table.Add ();
			FillPropertyValues ( tableRow, row );
		else
			tableRow = result [ 0 ];
			tableRow.Quantity = tableRow.Quantity + row.Quantity;
			if ( not SelectedRow.Service ) then
				tableRow.QuantityPkg = tableRow.QuantityPkg + row.QuantityPkg;
			endif; 
		endif;
		setUseSocial ( row );
	enddo; 
	
EndProcedure 

&AtClient
Function getSearch ( Rows, Keys )
	
	search = new Structure ( Keys );
	row = Rows [ 0 ];
	trash = new Array ();
	for each item in search do
		name = item.Key;
		if ( not row.Property ( name ) ) then
			trash.Add ( name );
		endif; 
	enddo; 
	for each item in trash do
		search.Delete ( item );
	enddo; 
	return search;
	
EndFunction 

&AtClient
Procedure showNotification ()
	
	Output.ItemWasAddedToSelectedItems ( new Structure ( "Item", SelectedRow.Ref ) );
	ItemsExist = true;
		
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( Exit ) then
		Cancel = true;
		return;
	endif; 
	if ( not SelectionFinished and ItemsExist ) then
		Cancel = true;
		Output.MoveToDocumentConfirmation ( ThisObject );
	endif; 
	
EndProcedure

&AtClient
Procedure MoveToDocumentConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		performChoice ();
	elsif ( Answer = DialogReturnCode.No ) then
		SelectionFinished = true;
		Close ();
	endif; 
	
EndProcedure 

&AtClient
Procedure performChoice ()
	
	SelectionFinished = true;
	p = new Structure ();
	p.Insert ( "Operation", Enum.ChoiceOperationsPickItems () );
	p.Insert ( "Items", OwnerItems );
	p.Insert ( "Services", OwnerServices );
	NotifyChoice ( p );
			
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Finish ( Command )
	
	performChoice ();
	
EndProcedure

&AtClient
Procedure ShowPricesOnChange ( Item )
	
	toggleShowPrices ();
	
EndProcedure

&AtClient
Procedure toggleShowPrices ()
	
	if ( rowUndefined () ) then
		Object.Prices.Clear ();
	else
		table = getPrices ( Cache.Prices, formData () );
		Collections.DeserializeFormTable ( Object.Prices, table );
	endif; 
	Appearance.Apply ( ThisObject, "ShowPrices" );
	
EndProcedure

&AtClient
Function rowUndefined ()
	
	page = Items.GroupLists.CurrentPage;
	if ( page = Items.GroupItems ) then
		return Items.ItemsList.CurrentData = undefined;
	elsif ( page = Items.GroupFeatures ) then
		return Items.FeaturesList.CurrentData = undefined;
	elsif ( page = Items.GroupPackages ) then
		return Items.PackagesList.CurrentData = undefined;
	else
		return true;
	endif; 
	
EndFunction

&AtClient
Function formData ()
	
	data = new Structure ();
	page = Items.GroupLists.CurrentPage;
	if ( page = Items.GroupItems ) then
		row = Items.ItemsList.CurrentData;
		data.Insert ( "Feature" );
		data.Insert ( "Package" );
		data.Insert ( "PackagePrice", row.Package );
	elsif ( page = Items.GroupFeatures ) then
		row = SelectedRow;
		featureListRow = Items.FeaturesList.CurrentData;
		data.Insert ( "Feature", featureListRow.Ref );
		data.Insert ( "Package" );
		data.Insert ( "PackagePrice", row.Package );
	elsif ( page = Items.GroupPackages ) then
		row = SelectedRow;
		data.Insert ( "Feature", Feature );
		package = Items.PackagesList.CurrentData.Ref;
		data.Insert ( "Package", package );
		data.Insert ( "PackagePrice", package );
	endif; 
	data.Insert ( "Prices", Prices );
	data.Insert ( "ShowPrices", ShowPrices );
	data.Insert ( "Period", ? ( Date = Date ( 1, 1, 1 ), undefined, Date ) );
	data.Insert ( "Company", Source.Company );
	data.Insert ( "Item", row.Ref );
	data.Insert ( "Service", row.Service );
	data.Insert ( "CountPackages", row.CountPackages );
	data.Insert ( "Warehouse", Warehouse );
	data.Insert ( "ShowReserves", ShowReserves );
	data.Insert ( "Filter", Filter );
	data.Insert ( "FilterNone", FilterNone );
	data.Insert ( "FilterReserveOnly", FilterReserveOnly );
	data.Insert ( "FilterAvailableOnly", FilterAvailableOnly );
	data.Insert ( "Organization", getOrganization () );
	data.Insert ( "Contract", Source.Contract );
	data.Insert ( "VendorContract", isVendor () );
	return data;
	
EndFunction

&AtClient
Function getOrganization ()
	
	type = Source.Type;
	if ( type.SalesOrder
		or type.Bill
		or type.Invoice
		or type.Quote ) then
		return Source.Customer;
	elsif ( type.PurchaseOrder
		or type.VendorBill
		or type.VendorInvoice ) then
		return Source.Vendor;
	endif; 
	
EndFunction 

&AtClient
Function isVendor ()
	
	type = Source.Type;
	return type.PurchaseOrder
	or type.VendorBill
	or type.VendorInvoice;
	
EndFunction 

&AtServerNoContext
Function getPrices ( PricesCache, val Data )
	
	table = getPricesTable ( Data );
	calcPrices ( PricesCache, table, Data );
	return CollectionsSrv.Serialize ( table );
	
EndFunction

&AtServerNoContext
Function getPricesTable ( Data )
	
	if ( Data.ShowPrices ) then
		s = "
		|select Prices.Ref as Prices, ( Prices.Description + "", "" + Prices.Currency.Description ) as Presentation,
		|	0 as Price
		|from Catalog.Prices as Prices
		|where not Prices.DeletionMark
		|and Prices.Owner = &Company
		|order by Prices.Code
		|";
		q = new Query ( s );
		q.SetParameter ( "Company", Data.Company );
		return q.Execute ().Unload ();
	else
		table = new ValueTable ();
		table.Columns.Add ( "Prices", new TypeDescription ( "CatalogRef.Prices" ) );
		table.Columns.Add ( "Presentation", new TypeDescription ( "String" ) );
		table.Columns.Add ( "Price", new TypeDescription ( "Number" ) );
		if ( not Data.Prices.IsEmpty () ) then
			row = Table.Insert ( 0 );
			row.Prices = Data.Prices;
			row.Presentation = "" + Data.Prices + ", " + Data.Prices.Currency;
		endif;
		return table;
	endif; 
	
EndFunction

&AtServerNoContext
Procedure calcPrices ( PricesCache, Table, Data )
	
	period = Data.Period;
	item = Data.Item;
	package = Data.PackagePrice;
	feature = Data.Feature;
	organization = Data.Organization;
	contract = Data.Contract;
	vendorContract = Data.VendorContract;
	warehouse = Data.Warehouse;
	for each row in Table do
		row.Price = Goods.Price ( PricesCache, period, row.Prices, item, package, feature, organization, contract, vendorContract, warehouse );
	enddo;
	
EndProcedure

&AtClient
Procedure FilterOnChange ( Item )
	
	applyFilter ();
	startUpdate ( Items.ItemsList );
	
EndProcedure

&AtServer
Procedure applyFilter () 

	if ( Filter = FilterReserveOnly ) then
		ShowReserves = true;
		applyShowReserves ();
	endif;
	filterByBalances ( Filter );
	Appearance.Apply ( ThisObject, "Filter" );

EndProcedure

&AtClient
Procedure startUpdate ( Item )
	
	if ( Item.CurrentData = undefined ) then
		return;
	endif; 
	if ( Item = Items.ItemsList ) then
		if ( Item.CurrentData.IsFolder ) then
			return;
		endif; 
	endif; 
	AttachIdleHandler ( "updateInformation", 0.2, true );
	
EndProcedure

&AtClient
Procedure FilterClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure ShowItemsOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "ShowItems" );
	
EndProcedure

&AtClient
Procedure ShowReservesOnChange ( Item )
	
	applyShowReserves ();
	
EndProcedure

&AtServer
Procedure applyShowReserves () 

	Appearance.Apply ( ThisObject, "ShowReserves" );

EndProcedure

&AtClient
Procedure DateOnChange ( Item )
	
	setPeriod ();
	updateInformation ();
	resetCache ();
	
EndProcedure

&AtClient
Procedure resetCache ()
	
	Cache.Rows = new Map ();
	
EndProcedure 

// *****************************************
// *********** Table Items

&AtClient
Procedure BackToItems ( Command )
	
	activateItems ();
	
EndProcedure

&AtClient
Procedure activateItems ()
	
	Items.GroupLists.CurrentPage = Items.GroupItems;
		
EndProcedure

&AtClient
Procedure ItemsListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	setSelectedRow ();
	nextPage ( Item, StandardProcessing );
	
EndProcedure

&AtClient
Procedure setSelectedRow ()
	
	data = Items.ItemsList.CurrentData;
	SelectedRow = new Structure ();
	SelectedRow.Insert ( "Ref", data.Ref );
	SelectedRow.Insert ( "Service", data.Service );
	SelectedRow.Insert ( "CountPackages", data.CountPackages );
	SelectedRow.Insert ( "Package", data.Package );
	SelectedRow.Insert ( "Features", data.Features );
	
EndProcedure 

&AtClient
Procedure nextPage ( Item, StandardProcessing )
	
	data = Item.CurrentData;
	if ( Item = Items.ItemsList ) then
		leaveItem ( data, StandardProcessing );
	elsif ( Item = Items.FeaturesList ) then
		leaveFeature ( data, StandardProcessing );
	elsif ( Item = Items.PackagesList ) then
		leavePackage ( data, StandardProcessing );
	endif; 
	
EndProcedure

&AtClient
Procedure leaveItem ( Data, StandardProcessing )
	
	if ( Data.IsFolder ) then
		return;
	endif; 
	StandardProcessing = false;
	Feature = undefined;
	Package = undefined;
	if ( featureExists () ) then
		activateFeatures ();
	elsif ( Data.CountPackages ) then
		activatePackages ();
	else
		completeSelection ();
	endif; 
		
EndProcedure
 
&AtClient
Function featureExists ()
	
	return Features and not SelectedRow.Features.IsEmpty ();
	
EndFunction

&AtClient
Procedure leaveFeature ( Data, StandardProcessing )
	
	StandardProcessing = false;
	Feature = Data.Ref;
	if ( SelectedRow.CountPackages ) then
		activatePackages ();
	else
		completeSelection ();
	endif; 
		
EndProcedure

&AtClient
Procedure leavePackage ( Data, StandardProcessing )
	
	StandardProcessing = false;
	Package = Data.Ref;
	completeSelection ();
		
EndProcedure

&AtClient
Procedure activateFeatures ()
	
	filterFeatures ();
	Items.GroupLists.CurrentPage = Items.GroupFeatures;
		
EndProcedure

&AtClient
Procedure filterFeatures ()
	
	FeaturesList.Parameters.SetParameterValue ( "Item", SelectedRow.Ref );
	FeaturesList.Parameters.SetParameterValue ( "Features", SelectedRow.Features );
	
EndProcedure

&AtClient
Procedure activatePackages ()

	filterPackages ();
	Items.GroupLists.CurrentPage = Items.GroupPackages;

EndProcedure

&AtClient
Procedure filterPackages ()
	
	p = PackagesList.Parameters;
	p.SetParameterValue ( "Item", SelectedRow.Ref );
	p.SetParameterValue ( "Feature", Feature );
	
EndProcedure

&AtClient
Procedure completeSelection ()
	
	if ( AskDetails ) then
		openDetails ();
	else
		addRows ( getRow () );
		showNotification ();
	endif; 
	activateSelection ();
	
EndProcedure

&AtClient
Procedure openDetails ()
	
	service = SelectedRow.Service;
	p = new Structure ();
	p.Insert ( "Command", Enum.PickItemsCommandsSelect () );
	p.Insert ( "Source", Source );
	p.Insert ( "Service", service );
	p.Insert ( "TableRow", getRow () );
	p.Insert ( "Discounts", Discounts );
	p.Insert ( "CountPackages", ? ( service, false, SelectedRow.CountPackages ) );
	p.Insert ( "Organization", getOrganization () );
	type = Source.Type;
	if ( type.SalesOrder
		or type.InternalOrder ) then
		form = ? ( service, "OrderService", "OrderItem" );
	elsif ( type.PurchaseOrder
		or type.ProductionOrder ) then
		form = "ProvisionOrder";
	elsif ( type.Transfer
		or type.WriteOff ) then
		form = "Reservation";
	else
		form = "Common";
		p.Insert ( "ShowSocial", ShowSocial );
		p.Insert ( "ShowExtraCharge", ShowExtraCharge );
	endif; 
	OpenForm ( "DataProcessor.Items.Form." + form, p, ThisObject );
	
EndProcedure

&AtClient
Function getRow ()
	
	row = getCachedRow ();
	if ( row = undefined ) then
		type = Source.Type;
		if ( type.SalesOrder
			or type.InternalOrder ) then
			row = getOrderRow ( Cache.Prices, SelectedRow, Source, Prices, Package, Feature );
		elsif ( type.PurchaseOrder ) then
			row = getPurchaseOrderRow ( Cache.Prices, SelectedRow, Source, Prices, Package, Feature );
		elsif ( type.ProductionOrder ) then
			row = getProductionOrderRow ( SelectedRow, Source, Package, Feature );
		elsif ( type.Production ) then
			row = getProductionRow ( SelectedRow, Source, Package, Feature );	
		elsif ( type.VendorBill
			or type.Bill
			or type.Quote ) then
			row = getBillRow ( Cache.Prices, SelectedRow, Source, Prices, Package, Feature );
		elsif ( type.Invoice )
			or ( type.InvoiceRecord ) then
			row = getInvoiceRow ( Cache.Prices, SelectedRow, Source, Prices, Package, Feature );
		elsif ( type.Transfer
			or type.WriteOff ) then
			row = getTransferRow ( Cache.Prices, SelectedRow, Source, Prices, Package, Feature );
		elsif ( type.VendorInvoice
			or type.ExpenseReport ) then
			row = getVendorInvoiceRow ( Cache.Prices, SelectedRow, Source, Prices, Package, Feature );
		elsif ( type.Assembling
			or type.Disassembling ) then
			row = getAssemblingRow ( SelectedRow, Source, Package, Feature );	
		elsif ( type.ReceiveItems ) then
			row = getReceiveItemsRow ( Cache.Prices, SelectedRow, Source, Prices, Package, Feature );
		endif; 
		cacheRow ( row );
	endif; 
	return row;
	
EndFunction 

&AtClient
Function getCachedRow ()
	
	rowKey = getRowKey ();
	for each item in Cache.Rows do
		k = item.Key;
		if ( k.Item = rowKey.Item
			and k.Package = rowKey.Package
			and k.Feature = rowKey.Feature ) then
			return item.Value;
		endif; 
	enddo; 
	return undefined;
	
EndFunction 

&AtClient
Function getRowKey ()
	
	p = new Structure ();
	p.Insert ( "Item", SelectedRow.Ref );
	p.Insert ( "Package", Package );
	p.Insert ( "Feature", Feature );
	return p;
	
EndFunction 

&AtServerNoContext
Function getOrderRow ( val PricesCache, val SelectedRow, val Source, val Prices, val Package, val Feature )
	
	salesOrder = Source.Type.SalesOrder;
	row = new Structure ();
	item = SelectedRow.Ref;
	row.Insert ( "Item", item );
	row.Insert ( "Feature", Feature );
	row.Insert ( "DeliveryDate", Source.DeliveryDate );
	row.Insert ( "Prices", Prices );
	row.Insert ( "Quantity", 1 );
	data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
	row.Insert ( "VATCode", data.VAT );
	row.Insert ( "VATRate", data.Rate );
	row.Insert ( "Total", 0 );
	row.Insert ( "VAT", 0 );
	if ( SelectedRow.Service ) then
		pricePackage = undefined;
		row.Insert ( "Performer", Enums.Performers.None );
		row.Insert ( "Department", Catalogs.Departments.EmptyRef () );
		row.Insert ( "Description", DF.Pick ( item, "FullDescription" ) );
	else
		augmentPackage ( row, Package );
		pricePackage = row.Package;
		row.Insert ( "DocumentOrder" );
		row.Insert ( "DocumentOrderRowKey", Catalogs.RowKeys.EmptyRef () );
		row.Insert ( "Reservation", ? ( salesOrder, Enums.Reservation.None, Enums.Reservation.Invoice ) );
		row.Insert ( "Stock", Catalogs.Warehouses.EmptyRef () );
	endif; 
	if ( salesOrder ) then
		row.Insert ( "DiscountRate", 0 );
		row.Insert ( "Discount", 0 );
		row.Insert ( "Price", Goods.Price ( PricesCache, Source.Date, Prices, item, pricePackage, Feature,
		Source.Customer, Source.Contract, , Source.Warehouse, Source.Currency ) );
	else
		row.Insert ( "Price", Goods.Price ( PricesCache, Source.Date, Prices, item, pricePackage, Feature,
		, , , , Source.Currency ) );
	endif; 
	row.Insert ( "Amount", 0 );
	Computations.Amount ( row );
	Computations.Total ( row, Source.VATUse );
	return row;
	
EndFunction 

&AtServerNoContext
Procedure augmentPackage ( TableRow, Package )
	
	if ( Package.IsEmpty () ) then
		data = DF.Values ( TableRow.Item, "Package, Package.Capacity as Capacity" );
		TableRow.Insert ( "Package", data.Package );
		TableRow.Insert ( "Capacity", ? ( data.Capacity = 0, 1, data.Capacity ) );
	else
		TableRow.Insert ( "Package", Package );
		TableRow.Insert ( "Capacity", DF.Pick ( Package, "Capacity", 1 ) );
	endif; 
	TableRow.Insert ( "QuantityPkg", 1 );
	Computations.Units ( TableRow );
	
EndProcedure 

&AtServerNoContext
Function getPurchaseOrderRow ( val PricesCache, val SelectedRow, val Source, val Prices, val Package, val Feature )
	
	row = new Structure ();
	row.Insert ( "Feature", Feature );
	row.Insert ( "DeliveryDate", Source.DeliveryDate );
	row.Insert ( "DiscountRate", 0 );
	row.Insert ( "Discount", 0 );
	item = SelectedRow.Ref;
	row.Insert ( "Item", item );
	row.Insert ( "Prices", Prices );
	row.Insert ( "Quantity", 1 );
	row.Insert ( "DocumentOrder" );
	row.Insert ( "DocumentOrderRowKey", Catalogs.RowKeys.EmptyRef () );
	data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
	row.Insert ( "VATCode", data.VAT );
	row.Insert ( "VATRate", data.Rate );
	row.Insert ( "Total", 0 );
	row.Insert ( "VAT", 0 );
	if ( SelectedRow.Service ) then
		pricePackage = undefined;
		row.Insert ( "Description", DF.Pick ( item, "FullDescription" ) );
	else
		augmentPackage ( row, Package );
		pricePackage = row.Package;
		row.Insert ( "Provision", Enums.Provision.Free );
	endif; 
	row.Insert ( "Price", Goods.Price ( PricesCache, Source.Date, Prices, item, pricePackage, Feature,
	Source.Vendor, Source.Contract, true, Source.Warehouse, Source.Currency ) );
	row.Insert ( "Amount", 0 );
	Computations.Amount ( row );
	Computations.Total ( row, Source.VATUse );
	return row;
	
EndFunction 

&AtServerNoContext
Function getProductionOrderRow ( val SelectedRow, val Source, val Package, val Feature )
	
	row = new Structure ();
	row.Insert ( "Feature", Feature );
	row.Insert ( "DeliveryDate", Source.DeliveryDate );
	item = SelectedRow.Ref;
	row.Insert ( "Item", item );
	row.Insert ( "Quantity", 1 );
	row.Insert ( "DocumentOrder" );
	row.Insert ( "DocumentOrderRowKey", Catalogs.RowKeys.EmptyRef () );
	if ( SelectedRow.Service ) then
		row.Insert ( "Description", DF.Pick ( item, "FullDescription" ) );
	else
		augmentPackage ( row, Package );
		row.Insert ( "Provision", Enums.Provision.Free );
	endif; 
	return row;
	
EndFunction 

&AtServerNoContext
Function getProductionRow ( val SelectedRow, val Source, val Package, val Feature )
	
	row = new Structure ();
	row.Insert ( "Feature", Feature );
	item = SelectedRow.Ref;
	row.Insert ( "Item", item );
	row.Insert ( "Quantity", 1 );
	row.Insert ( "DocumentOrder" );
	row.Insert ( "DocumentOrderRowKey", Catalogs.RowKeys.EmptyRef () );
	if ( SelectedRow.Service ) then
		row.Insert ( "Description", DF.Pick ( item, "FullDescription" ) );
	else
		augmentPackage ( row, Package );
	endif; 
	return row;
	
EndFunction 

&AtServerNoContext
Function getBillRow ( val PricesCache, val SelectedRow, val Source, val Prices, val Package, val Feature )
	
	row = new Structure ();
	row.Insert ( "Feature", Feature );
	row.Insert ( "DiscountRate", 0 );
	row.Insert ( "Discount", 0 );
	item = SelectedRow.Ref;
	row.Insert ( "Item", item );
	row.Insert ( "Prices", Prices );
	row.Insert ( "Quantity", 1 );
	if ( SelectedRow.Service ) then
		pricePackage = undefined;
		row.Insert ( "Description", DF.Pick ( item, "FullDescription" ) );
	else
		augmentPackage ( row, Package );
		pricePackage = row.Package;
	endif; 
	type = Source.Type;
	if ( type.Bill
		or type.Quote ) then
		data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
		row.Insert ( "VATCode", data.VAT );
		row.Insert ( "VATRate", data.Rate );
		row.Insert ( "Total", 0 );
		row.Insert ( "VAT", 0 );
		row.Insert ( "Price", Goods.Price ( PricesCache, Source.Date, Prices, item, pricePackage, Feature,
		Source.Customer, Source.Contract, , Source.Warehouse, Source.Currency ) );
		if ( type.Quote ) then
			row.Insert ( "DeliveryDate", Source.DeliveryDate );
		endif; 
		row.Insert ( "Amount", 0 );
		Computations.Amount ( row );
		Computations.Total ( row, Source.VATUse );
	else
		row.Insert ( "Price", Goods.Price ( PricesCache, Source.Date, Prices, item, pricePackage, Feature,
		Source.Vendor, Source.Contract, true, Source.Warehouse, Source.Currency ) );
		row.Insert ( "Amount", 0 );
		Computations.Amount ( row );
	endif;
	return row;
	
EndFunction 

&AtServerNoContext
Function getInvoiceRow ( val PricesCache, val SelectedRow, val Source, val Prices, val Package, val Feature )
	
	row = new Structure ();
	row.Insert ( "Feature", Feature );
	row.Insert ( "DiscountRate", 0 );
	row.Insert ( "Discount", 0 );
	item = SelectedRow.Ref;
	row.Insert ( "Item", item );
	row.Insert ( "Prices", Prices );
	row.Insert ( "Quantity", 1 );
	row.Insert ( "Warehouse", Catalogs.Warehouses.EmptyRef () );
	row.Insert ( "Income" );
	row.Insert ( "VATAccount" );
	accounts = "Income, VAT";
	if ( SelectedRow.Service ) then
		pricePackage = undefined;
		row.Insert ( "Description", DF.Pick ( item, "FullDescription" ) );
	else
		augmentPackage ( row, Package );
		pricePackage = row.Package;
		row.Insert ( "Series", Catalogs.Series.EmptyRef () );
		row.Insert ( "SalesCost" );
		row.Insert ( "Account" );
		accounts = accounts + ", SalesCost, Account";
	endif;
	warehouse = Source.Warehouse;
	data = AccountsMap.Item ( item, Source.Company, warehouse, accounts );
	FillPropertyValues ( row, data );
	row.VATAccount = data.VAT;
	data = DF.Values ( item, "VAT, VAT.Rate as Rate, Social" );
	row.Insert ( "VATCode", data.VAT );
	row.Insert ( "VATRate", data.Rate );
	row.Insert ( "Total", 0 );
	row.Insert ( "VAT", 0 );
	social = data.Social;
	row.Insert ( "Social", social );
	date = Source.Date;
	row.Insert ( "Price", Goods.Price ( PricesCache, date, Prices, item, pricePackage, Feature,
	Source.Customer, Source.Contract, , warehouse, Source.Currency ) );
	if ( social ) then
		row.Insert ( "ProducerPrice", Goods.ProducerPrice ( row, date ) );
		row.Insert ( "ExtraCharge", 0 );
		Computations.ExtraCharge ( row );
	endif;
	row.Insert ( "Amount", 0 );
	Computations.Amount ( row );
	Computations.Total ( row, Source.VATUse );
	return row;
	
EndFunction

&AtServerNoContext
Function getTransferRow ( val PricesCache, val SelectedRow, val Source, val Prices, val Package, val Feature )
	
	row = new Structure ();
	row.Insert ( "Feature", Feature );
	item = SelectedRow.Ref;
	row.Insert ( "Item", item );
	row.Insert ( "Prices", Prices );
	row.Insert ( "Quantity", 1 );
	augmentPackage ( row, Package );
	pricePackage = row.Package;
	row.Insert ( "Series", Catalogs.Series.EmptyRef () );
	warehouse = Source.Warehouse;
	account = AccountsMap.Item ( item, Source.Company, warehouse, "Account" ).Account;
	row.Insert ( "Account", account );
	if ( Source.Type.Transfer ) then
		row.Insert ( "AccountReceiver", account );
	endif;	
	data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
	row.Insert ( "VATCode", data.VAT );
	row.Insert ( "VATRate", data.Rate );
	row.Insert ( "Total", 0 );
	row.Insert ( "VAT", 0 );
	row.Insert ( "Price", Goods.Price ( PricesCache, Source.Date, Prices, item, pricePackage, Feature, , , , warehouse, Source.Currency ) );
	row.Insert ( "Amount", 0 );
	row.Insert ( "DocumentOrder" );
	row.Insert ( "RowKey", Catalogs.RowKeys.EmptyRef () );
	Computations.Amount ( row );
	Computations.Total ( row, Source.VATUse );
	return row;
	
EndFunction 

&AtServerNoContext
Function getVendorInvoiceRow ( val PricesCache, val SelectedRow, val Source, val Prices, val Package, val Feature )
	
	row = new Structure ();
	item = SelectedRow.Ref;
	row.Insert ( "Item", item );
	row.Insert ( "Feature", Feature );
	row.Insert ( "DiscountRate", 0 );
	row.Insert ( "Discount", 0 );
	row.Insert ( "Prices", Prices );
	row.Insert ( "Quantity", 1 );
	row.Insert ( "Warehouse", Catalogs.Warehouses.EmptyRef () );
	warehouse = Source.Warehouse;
	accounts = "VAT";
	if ( SelectedRow.Service ) then
		pricePackage = undefined;
		row.Insert ( "Description", DF.Pick ( item, "FullDescription" ) );
		row.Insert ( "Account" );
		row.Insert ( "Expense" );
		row.Insert ( "Product" );
		row.Insert ( "ProductFeature" );
		row.Insert ( "Department" );
	else
		augmentPackage ( row, Package );
		pricePackage = row.Package;
		row.Insert ( "Series", Catalogs.Series.EmptyRef () );
		row.Insert ( "Account" );
		accounts = accounts + ", Account";
	endif; 
	accounts = AccountsMap.Item ( item, Source.Company, warehouse, accounts );
	FillPropertyValues ( row, accounts );
	row.Insert ( "VATAccount", accounts.VAT );
	data = DF.Values ( item, "VAT, VAT.Rate as Rate, Social" );
	row.Insert ( "VATCode", data.VAT );
	row.Insert ( "VATRate", data.Rate );
	row.Insert ( "Social", data.Social );
	row.Insert ( "Total", 0 );
	row.Insert ( "VAT", 0 );
	row.Insert ( "ProducerPrice", 0 );
	row.Insert ( "Price", Goods.Price ( PricesCache, Source.Date, Prices, item, pricePackage, Feature,
	Source.Vendor, Source.Contract, true, warehouse, Source.Currency ) );
	row.Insert ( "Amount", 0 );
	Computations.Amount ( row );
	Computations.Total ( row, Source.VATUse );
	return row;
	
EndFunction 

&AtClient
Procedure cacheRow ( Row )
	
	cacheKey = getRowKey ();
	Cache.Rows [ cacheKey ] = Row;
	
EndProcedure 

&AtClient
Procedure activateSelection ()
	
	if ( SelectedRow.Service ) then
		Items.GroupSelectedStuff.CurrentPage = Items.GroupSelectedServices;
	else
		Items.GroupSelectedStuff.CurrentPage = Items.GroupSelectedItems;
	endif; 
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	startUpdate ( Item );
	
EndProcedure

&AtClient
Procedure updateInformation ()
	
	if ( rowUndefined () ) then
		Object.Balances.Clear ();
		Object.Prices.Clear ();
		return;
	endif; 
	data = formData ();
	info = getInfo ( Cache.Prices, data );
	setInformation ( data, info );
	
EndProcedure

&AtServerNoContext
Function getInfo ( PricesCache, val Data )
	
	info = new Structure ();
	if ( not Data.Service ) then
		table = getBalances ( Data );
		info.Insert ( "Balances", CollectionsSrv.Serialize ( table ) );
	endif; 
	info.Insert ( "Prices", getPrices ( PricesCache, Data ) );
	return info;
	
EndFunction

&AtServerNoContext
Function getBalances ( Data )
	
	table = getBalancesTable ( Data );
	warehouse = Data.Warehouse;
	if ( not warehouse.IsEmpty () ) then
		if ( table.Find ( warehouse, "Warehouse" ) = undefined ) then
			row = Table.Insert ( 0 );
			row.Warehouse = warehouse;
			row.WarehousePresentation = "" + warehouse;
			row.Quantity = 0;
			if ( Data.ShowReserves ) then
				row.Reserve = 0;
			endif;
		endif; 
	endif;
	return table;
	
EndFunction

&AtServerNoContext
Function getBalancesTable ( Data ) 

	var env;
	SQL.Init ( env );
	if ( Data.ShowReserves ) then
		sqlReserves ( Data, env );
		sqlItemsReserves ( Data, env );
		sqlItems ( Data, env );
	else
		sqlBalances ( Data, env );
	endif;
	q = env.Q;
	q.SetParameter ( "Period", Data.Period );
	q.SetParameter ( "Warehouse", Data.Warehouse );
	q.SetParameter ( "Item", Data.Item );
	q.SetParameter ( "Feature", Data.Feature );
	q.SetParameter ( "Package", Data.Package );
	SQL.Prepare ( env );
	return q.Execute ().Unload ();

EndFunction

&AtServerNoContext
Procedure sqlReserves ( Data, Env )

	useFeature = ( Data.Feature <> undefined );
	usePackage = ( Data.Package <> undefined );
	s = "
	|// BalancesReserves
	|select Reserves.DocumentOrder as DocumentOrder, Reserves.RowKey as RowKey, Reserves.QuantityBalance as Reserve, Reserves.Warehouse as Warehouse
	|into BalancesReserves
	|from AccumulationRegister.Reserves.Balance ( &Period ) as Reserves
	|where Reserves.QuantityBalance > 0
	|index by Reserves.DocumentOrder, Reserves.RowKey
	|;
	|// ItemsReserves
	|select Reserves.Warehouse as Warehouse, Items.Package as Package, Items.Feature as Feature, Items.Item as Item,
	|	case when Items.Item.CountPackages then Reserves.Reserve / Items.Capacity else Reserves.Reserve end as Reserve
	|into Reserves
	|from BalancesReserves as Reserves
	|	//
	|	// SalesOrderItems
	|	//
	|	join Document.SalesOrder.Items as Items
	|	on Items.Ref = Reserves.DocumentOrder
	|	and Items.RowKey = Reserves.RowKey
	|where Items.Item = &Item";
	if ( useFeature ) then
		s = s + " and Items.Feature = &Feature";
	endif; 
	if ( usePackage ) then
		s = s + " and Items.Package = &Package";
	endif; 
	s = s + "
	|union all	
	|select Reserves.Warehouse, Items.Package, Items.Feature, Items.Item,
	|	case when Items.Item.CountPackages then Reserves.Reserve / Items.Capacity else Reserves.Reserve end
	|from BalancesReserves as Reserves
	|	//
	|	// InternalOrderItems
	|	//
	|	join Document.InternalOrder.Items as Items
	|	on Items.Ref = Reserves.DocumentOrder
	|	and Items.RowKey = Reserves.RowKey
	|where Items.Item = &Item";
	if ( useFeature ) then
		s = s + " and Items.Feature = &Feature";
	endif; 
	if ( usePackage ) then
		s = s + " and Items.Package = &Package";
	endif; 
	s = s + "
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServerNoContext
Procedure sqlItemsReserves ( Data, Env )

	s = "
	|// Items
	|select Balances.Warehouse as Warehouse, Balances.QuantityBalance as Quantity,
	|	Balances.Feature as Feature, Balances.Package as Package, Balances.Item as Item
	|into Items
	|from AccumulationRegister.Items.Balance ( &Period, Warehouse in ( select Ref from Catalog.Warehouses )
	|	and Item = &Item";
	if ( Data.Feature <> undefined ) then
		s = s + " and Feature = &Feature";
	endif; 
	if ( Data.Package <> undefined ) then
		s = s + " and Package = &Package";
	endif; 
	s = s + ") as Balances
	|;
	|// ItemsReserves
	|select Items.Warehouse as Warehouse, sum ( Items.Quantity ) as Quantity, sum ( Items.Reserve ) as Reserve, Items.Item as Item, Items.Package as Package
	|into ItemsReserves
	|from ( 
	|	select Items.Warehouse as Warehouse, Items.Quantity as Quantity, 0 as Reserve, Items.Item as Item, Items.Package as Package
	|	from Items as Items
	|	union all
	|	select Reserves.Warehouse, 0, Reserves.Reserve, Reserves.Item, Reserves.Package
	|	from Reserves as Reserves ) as Items
	|group by Items.Warehouse, Items.Item, Items.Package";
	filter = Data.Filter;
	if ( filter = Data.FilterReserveOnly ) then
		s = s + "
		|	having sum ( Items.Reserve ) > 0";
	elsif ( filter = Data.FilterAvailableOnly ) then
		s = s + "
		|	having sum ( Items.Quantity ) > 0";
	endif;
	s = s + "
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServerNoContext
Procedure sqlItems ( Data, Env )

	s = "
	|select Items.Warehouse as Warehouse, presentation ( Items.Warehouse ) as WarehousePresentation, Items.Quantity as Quantity, Items.Reserve as Reserve";
	if ( Options.Packages ()
		and Data.CountPackages ) then
		s = s + ", presentation ( Items.Package )";
	else
		s = s + ", presentation ( Items.Item.Unit )";
	endif; 
	s = s + " as PackagePresentation
	|from ItemsReserves as Items
	|order by case when Items.Warehouse = &Warehouse then 1 else 0 end desc, Items.Quantity desc, Items.Reserve desc
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServerNoContext
Procedure sqlBalances ( Data, Env )

	s = "
	|select Balances.Warehouse as Warehouse, presentation ( Balances.Warehouse ) as WarehousePresentation, Balances.QuantityBalance as Quantity
	|";
	if ( Options.Packages ()
		and Data.CountPackages ) then
		s = s + ", presentation ( Balances.Package )";
	else
		s = s + ", presentation ( Balances.Item.Unit )";
	endif; 
	s = s + " as PackagePresentation
	|from AccumulationRegister.Items.Balance ( &Period, Warehouse in ( select Ref from Catalog.Warehouses ) 
	|	and Item = &Item";
	if ( Data.Feature <> undefined ) then
		s = s + " and Feature = &Feature";
	endif; 
	if ( Data.Package <> undefined ) then
		s = s + " and Package = &Package";
	endif; 
	s = s + " ) as Balances
	|order by case when Balances.Warehouse = &Warehouse then 1 else 0 end desc, Balances.QuantityBalance desc
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtClient
Procedure setInformation ( Data, Info )
	
	if ( Data.Service ) then
		Object.Balances.Clear ();
	else
		Collections.DeserializeFormTable ( Object.Balances, Info.Balances );
	endif;
	Collections.DeserializeFormTable ( Object.Prices, Info.Prices );
	
EndProcedure

// *****************************************
// *********** Table FeaturesList

&AtClient
Procedure FeaturesListOnActivateRow ( Item )
	
	startUpdate ( Item );

EndProcedure

&AtClient
Procedure FeaturesListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	nextPage ( Item, StandardProcessing );
	
EndProcedure

// *****************************************
// *********** Table PackagesList

&AtClient
Procedure PackagesListOnActivateRow ( Item )
	
	startUpdate ( Item );
	
EndProcedure

&AtClient
Procedure PackagesListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	nextPage ( Item, StandardProcessing );
	
EndProcedure

&AtServerNoContext
Function getAssemblingRow ( val SelectedRow, val Source, val Package, val Feature )
	
	row = new Structure ();
	row.Insert ( "Feature", Feature );
	item = SelectedRow.Ref;
	row.Insert ( "Item", item );
	row.Insert ( "Quantity", 1 );
	augmentPackage ( row, Package );
	row.Insert ( "Series", Catalogs.Series.EmptyRef () );
	row.Insert ( "Account", AccountsMap.Item ( item, Source.Company, Source.Warehouse, "Account" ).Account );
	row.Insert ( "Warehouse", Catalogs.Warehouses.EmptyRef () );
	return row;
	
EndFunction 

&AtServerNoContext
Function getReceiveItemsRow ( val PricesCache, val SelectedRow, val Source, val Prices, val Package, val Feature )
	
	row = new Structure ();
	row.Insert ( "Feature", Feature );
	row.Insert ( "Series", Catalogs.Series.EmptyRef () );
	item = SelectedRow.Ref;
	row.Insert ( "Item", item );
	row.Insert ( "Prices", Prices );
	row.Insert ( "Quantity", 1 );
	row.Insert ( "Warehouse", Catalogs.Warehouses.EmptyRef () );
	augmentPackage ( row, Package );
	pricePackage = row.Package;
	warehouse = Source.Warehouse;
	accounts = AccountsMap.Item ( item, Source.Company, warehouse, "Account, VAT" );
	row.Insert ( "Account", accounts.Account );
	row.Insert ( "VATAccount", accounts.VAT );
	data = DF.Values ( item, "VAT, VAT.Rate as Rate, Social" );
	row.Insert ( "VATCode", data.VAT );
	row.Insert ( "VATRate", data.Rate );
	row.Insert ( "Social", data.Social );
	row.Insert ( "Total", 0 );
	row.Insert ( "VAT", 0 );
	row.Insert ( "ProducerPrice", 0 );
	row.Insert ( "Price", Goods.Price ( PricesCache, Source.Date, Prices, item, pricePackage, Feature, , , , warehouse, Source.Currency ) );
	row.Insert ( "Amount", 0 );
	Computations.Amount ( row );
	Computations.Total ( row, Source.VATUse );
	return row;
	
EndFunction

&AtServer
Procedure setSocial () 

	type = Source.Type;
	invoice = type.Invoice
	or type.InvoiceRecord;
	if ( type.ExpenseReport
		or invoice
		or type.ReceiveItems
		or type.VendorInvoice ) then
		ShowSocial = true;
		if ( invoice ) then
			ShowExtraCharge = true;
		endif;
	endif; 

EndProcedure

&AtClient
Procedure setUseSocial ( Row ) 

	if ( UseSocial
		or not ShowSocial ) then
		return;
	endif;
	UseSocial = row.Social

EndProcedure
