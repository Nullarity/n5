&AtServer
var Env;
&AtServer
var Base;
&AtServer
var InventoryExists;
&AtServer
var LVIInventoryExists;
&AtServer
var AssetsInventoryExists;
&AtServer
var IntangibleAssetsInventoryExists;
&AtServer
var AccountData;
&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	setLocalCurrency ();
	readAccount ();
	labelDims ();
	setSocial ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure setLocalCurrency ()
	
	LocalCurrency = Application.Currency ();
	
EndProcedure 

&AtServer
Procedure readAccount ()
	
	AccountData = GeneralAccounts.GetData ( Object.Account );
	ExpensesLevel = AccountData.Fields.Level;
	
EndProcedure 

&AtServer
Procedure labelDims ()
	
	i = 1;
	for each dim in AccountData.Dims do
		Items [ "Dim" + i ].Title = dim.Presentation;
		i = i + 1;
	enddo; 
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		setLocalCurrency ();
		DocumentForm.Init ( Object );
		Base = Parameters.Basis;
		if ( Base = undefined ) then
			fillNew ();
		else
			baseType = TypeOf ( Base );
			if ( baseType = Type ( "DocumentRef.Inventory" ) 
				or baseType = Type ( "DocumentRef.LVIInventory" ) ) then
				fillByInventory ();
			elsif ( baseType = Type ( "DocumentRef.AssetsInventory" ) 
				or baseType = Type ( "DocumentRef.IntangibleAssetsInventory" ) ) then
				fillByAssetsInventory ();		
			endif;
		endif;
	endif; 
	setAccuracy ();
	setLinks ();
	setSocial ();
	Forms.ActivatePage ( ThisObject, "Items,FixedAssets,IntangibleAssets" );
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
	|Factor Rate enable filled ( LocalCurrency ) and Object.Currency <> LocalCurrency;
	|Dim1 show ExpensesLevel > 0;
	|Dim2 show ExpensesLevel > 1;
	|Dim3 show ExpensesLevel > 2;
	|VAT show Object.VATUse > 0;
	|ItemsVATCode ItemsVAT ItemsTotal FixedAssetsVATCode FixedAssetsVAT FixedAssetsTotal IntangibleAssetsVATCode IntangibleAssetsVAT IntangibleAssetsTotal show Object.VATUse > 0;
	|ItemsProducerPrice show UseSocial
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	if ( Object.Warehouse.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Warehouse" );
		Object.Company = settings.Company;
		Object.Warehouse = settings.Warehouse;
	else
		Object.Company = DF.Pick ( Object.Warehouse, "Owner" );
	endif;
	Object.Currency = Application.Currency ();
	setRate ();
	setPrices ();
	
EndProcedure 

&AtServer
Procedure setRate ()
	
	currencyInfo = CurrenciesSrv.Get ( Object.Currency );
	Object.Rate = currencyInfo.Rate;
	Object.Factor = currencyInfo.Factor;
	
EndProcedure 

&AtServer
Procedure setPrices ()
	
	data = DF.Values ( Object.Company, "CostPrices" );
	Object.Prices = data.CostPrices;
	
EndProcedure

&AtServer
Procedure fillByInventory ()
	
	setEnvInventory ();
	sqlInventory ();
	SQL.Perform ( Env );
	headerByInventory ();
	itemsByInventory ();
	recalcTotals ();
	
EndProcedure

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	
EndProcedure

&AtServer
Procedure sqlInventory ()
	
	table = Env.Table;
	s = "
	|// @Fields
	|select Document.Company as Company" + ? ( Env.IsInventory, ", Document.Warehouse as Warehouse", "" ) + "
	|from Document." + table + " as Document
	|where Document.Ref = &Base
	|;
	|// #Items
	|select Items.Item as Item, Items.Feature as Feature, Items.Capacity as Capacity, Items.Series as Series,
	|	Items.Account as Account, Items.QuantityDifference as Quantity, Items.QuantityPkgDifference as QuantityPkg, 
	|	Items.Package as Package, Items.AmountDifference as Amount, Items.Price as Price
	|from Document." + table + ".Items as Items
	|where Items.Ref = &Base 
	|and ( Items.QuantityDifference > 0 
	|	or Items.AmountDifference > 0 )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByInventory ()
	
	FillPropertyValues ( Object, Env.Fields );
	Object.Inventory = Base;
	Object.Currency = Application.Currency ();
	setRate ();
	setPrices ();
	
EndProcedure

&AtServer
Procedure itemsByInventory () 

	checkItemsFilling ();
	Object.Items.Load ( Env.Items );

EndProcedure

&AtServer
Procedure checkItemsFilling ()
	
	if ( Env.Items.Count () = 0 ) then
		raise Output.FillingDataNotFoundError ();
	endif;
	
EndProcedure

&AtServer
Procedure recalcTotals ()
	
	vatUse = Object.VATUse;
	for each row in Object.Items do
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.FixedAssets do
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.IntangibleAssets do
		Computations.Total ( row, vatUse );
	enddo; 
	calcTotals ( Object );
	
EndProcedure

&AtServer
Procedure fillByAssetsInventory ()
	
	setEnvAssets ();
	sqlAssetsInventory ();
	SQL.Perform ( Env );
	headerByInventory ();
	assetsByInventory ();
	recalcTotals ();
	
EndProcedure

&AtServer
Procedure setEnvAssets ()
	
	setEnv ();
	if ( TypeOf ( Base ) = Type ( "DocumentRef.AssetsInventory" ) ) then
		table = "AssetsInventory";
		isAssetsInventory = true;
	else
		table = "IntangibleAssetsInventory";
		isAssetsInventory = false;
	endif;
	Env.Insert ( "Table", table );
	Env.Insert ( "IsAssetsInventory", isAssetsInventory );
	
EndProcedure

&AtServer
Procedure sqlAssetsInventory ()
	
	table = Env.Table;
	s = "
	|// @Fields
	|select Document.Company as Company
	|from Document." + table + " as Document
	|where Document.Ref = &Base
	|;
	|// #Items
	|select Items.Item as Item,	Items.AmountDifference as Amount, value ( Enum.Amortization.Linear ) as Method,
	|	Items.Ref.Department as Department, Items.Ref.Employee as Employee
	|from Document." + table + ".Items as Items
	|where Items.Ref = &Base 
	|and ( Items.Difference > 0 
	|	or Items.AmountDifference > 0 )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure assetsByInventory () 

	checkItemsFilling ();
	if ( Env.IsAssetsInventory ) then
		Object.FixedAssets.Load ( Env.Items );
	else
		Object.IntangibleAssets.Load ( Env.Items );
	endif;

EndProcedure

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantity, ItemsTotalQuantityPkg", false );

EndProcedure 

&AtServer
Procedure setLinks ()
	
	setInventoryExists ();
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		Env.Q.SetParameter ( "Inventory", Object.Inventory );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;

EndProcedure 

&AtServer
Procedure setInventoryExists () 

	inventory = Object.Inventory;
	inventoryFilled = ValueIsFilled ( inventory );
	typeInventory = TypeOf ( inventory );
	InventoryExists = ( inventoryFilled and typeInventory = Type ( "DocumentRef.Inventory" ) );
	LVIInventoryExists = ( inventoryFilled and typeInventory = Type ( "DocumentRef.LVIInventory" ) );
	AssetsInventoryExists = ( inventoryFilled and typeInventory = Type ( "DocumentRef.AssetsInventory" ) );
	IntangibleAssetsInventoryExists = ( inventoryFilled and typeInventory = Type ( "DocumentRef.IntangibleAssetsInventory" ) );

EndProcedure

&AtServer
Procedure sqlLinks ()
	
	if ( InventoryExists ) then
		table = "Inventory";
	elsif ( LVIInventoryExists ) then
		table = "LVIInventory";	
	elsif ( AssetsInventoryExists ) then
		table = "AssetsInventory";
	elsif ( IntangibleAssetsInventoryExists ) then
		table = "IntangibleAssetsInventory";
	else
		return;
	endif;
	s = "
	|// #Inventory
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document." + table + " as Documents
	|where Documents.Ref = &Inventory
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( InventoryExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Inventory, meta.Inventory ) );
	elsif ( LVIInventoryExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Inventory, meta.LVIInventory ) );	
	elsif ( AssetsInventoryExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Inventory, meta.AssetsInventory ) );	
	elsif ( IntangibleAssetsInventoryExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Inventory, meta.IntangibleAssetsInventory ) );			
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
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	Forms.DeleteLastRow ( Object.Items, "Item" );
	Forms.DeleteLastRow ( Object.FixedAssets, "Item" );
	Forms.DeleteLastRow ( Object.IntangibleAssets, "Item" );
	calcTotals ( Object );
	
EndProcedure

&AtClientAtServerNoContext
Procedure calcTotals ( Object )
	
	items = Object.Items;
	fixedAssets = Object.FixedAssets;
	intangibleAssets = Object.IntangibleAssets;
	vat = items.Total ( "VAT" )
	+ fixedAssets.Total ( "VAT" )
	+ intangibleAssets.Total ( "VAT" );
	amount = items.Total ( "Total" )
	+ fixedAssets.Total ( "Total" )
	+ intangibleAssets.Total ( "Total" );
	Object.VAT = vat;
	Object.Amount = amount;
	
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
	p.Insert ( "HideVATAccount", true );
	p.Insert ( "NewRow", NewRow );
	if ( Table = Items.FixedAssets ) then
		form = "Document.VendorInvoice.Form.FixedAsset";
	else
		form = "Document.VendorInvoice.Form.IntangibleAsset";
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
		row.Price = Goods.Price ( , Object.Date, Object.Prices, item, package, feature, , , , Object.Warehouse, Object.Currency );
		accounts = AccountsMap.Item ( item, Object.Company, Object.Warehouse, "Account" );
		row.Account = accounts.Account;
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

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	setPrices ();
	
EndProcedure

&AtClient
Procedure PricesOnChange ( Item )
	
	applyPrices ();
	
EndProcedure

&AtServer
Procedure applyPrices ()
	
	cache = new Map ();
	date = Object.Date;
	prices = Object.Prices;
	warehouse = Object.Warehouse;
	currency = Object.Currency;
	vatUse = Object.VATUse;
	for each row in Object.Items do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, , , , warehouse, currency );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	calcTotals ( Object );
	
EndProcedure 

&AtClient
Procedure AccountOnChange ( Item )
	
	applyAccount ();
	
EndProcedure

&AtServer
Procedure applyAccount ()
	
	readAccount ();
	adjustDims ( AccountData, Object );
	labelDims ();
	Appearance.Apply ( ThisObject, "ExpensesLevel" );
	      	
EndProcedure 

&AtServer
Procedure adjustDims ( Data, Target )
	
	fields = Data.Fields;
	dims = Data.Dims;
	level = fields.Level;
	if ( level = 0 ) then
		Target.Dim1 = null;
		Target.Dim2 = null;
		Target.Dim3 = null;
	elsif ( level = 1 ) then
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = null;
		Target.Dim3 = null;
	elsif ( level = 2 ) then
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = dims [ 1 ].ValueType.AdjustValue ( Target.Dim2 );
		Target.Dim3 = null;
	else
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = dims [ 1 ].ValueType.AdjustValue ( Target.Dim2 );
		Target.Dim3 = dims [ 2 ].ValueType.AdjustValue ( Target.Dim3 );
	endif; 

EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	OpenForm ( "CommonForm.Scan", , ThisObject );
	
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
	ItemsRow.Social = data.Social;
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate, Social" );
	warehouse = Params.Warehouse;
	price = Goods.Price ( , Params.Date, Params.Prices, item, data.Package, , , , , warehouse, Params.Currency );
	accounts = AccountsMap.Item ( item, Params.Company, warehouse, "Account" );
	data.Insert ( "Price", price );
	data.Insert ( "Account", accounts.Account );
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
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsPriceOnChange ( Item )
	
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	Computations.Price ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsPricesOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
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
// *********** Group More

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	calcTotals ( Object );
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	setRate ();
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
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
	for each row in Object.FixedAssets do
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.IntangibleAssets do
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

&AtServer
Procedure setEnvInventory ()
	
	setEnv ();
	if ( TypeOf ( Base ) = Type ( "DocumentRef.Inventory" ) ) then
		table = "Inventory";
		isInventory = true;
	else
		table = "LVIInventory";
		isInventory = false;
	endif;
	Env.Insert ( "Table", table );
	Env.Insert ( "IsInventory", isInventory );
	
EndProcedure
