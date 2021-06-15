&AtServer
var Env;
&AtServer
var BaseExists;
&AtServer
var BaseMetadata;
&AtServer
var ViewWriteOff;
&AtClient
var ItemsRow;
&AtClient
var ServicesRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	InvoiceForm.SetLocalCurrency ( ThisObject );
	setSocial ();
	setWarning ( ThisObject );
	initStatuses ( ThisObject );
	Appearance.Apply ( ThisObject );

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

&AtClientAtServerNoContext
Procedure setWarning ( Form )
	
	items = Form.Items;
	if ( Form.Object.Range.IsEmpty () ) then
		items.Series.WarningOnEditRepresentation = WarningOnEditRepresentation.DontShow;
		items.FormNumber.WarningOnEditRepresentation = WarningOnEditRepresentation.DontShow;
	else
		items.Series.WarningOnEditRepresentation = WarningOnEditRepresentation.Show;
		items.FormNumber.WarningOnEditRepresentation = WarningOnEditRepresentation.Show;
	endif;
	
EndProcedure

&AtClientAtServerNoContext
Procedure initStatuses ( Form )
	
	list = Form.Items.Status.ChoiceList;
	list.Clear ();
	if ( DF.Pick ( Form.Object.Range, "Online" ) ) then
		Form.RangeOnline = true;
		list.Add ( PredefinedValue ( "Enum.FormStatuses.Saved" ) );
		list.Add ( PredefinedValue ( "Enum.FormStatuses.Waiting" ) );
		list.Add ( PredefinedValue ( "Enum.FormStatuses.Unloaded" ) );
		list.Add ( PredefinedValue ( "Enum.FormStatuses.Printed" ) );
		list.Add ( PredefinedValue ( "Enum.FormStatuses.Submitted" ) );
		list.Add ( PredefinedValue ( "Enum.FormStatuses.Canceled" ) );
	else
		Form.RangeOnline = false;
		list.Add ( PredefinedValue ( "Enum.FormStatuses.Saved" ) );
		list.Add ( PredefinedValue ( "Enum.FormStatuses.Printed" ) );
		list.Add ( PredefinedValue ( "Enum.FormStatuses.Submitted" ) );
		list.Add ( PredefinedValue ( "Enum.FormStatuses.Canceled" ) );
	endif;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	if ( isNew () ) then
		base = Parameters.Basis;
		InvoiceForm.SetLocalCurrency ( ThisObject );
		DocumentForm.Init ( Object );
		if ( base = undefined ) then
			fillNew ();
		else
			InvoiceRecords.Fill ( Object, base );
		endif;
		setSocial ();
		setRange ();
		setType ( Object );
		setWarning ( ThisObject );
		initStatuses ( ThisObject );
	endif;
	setAccuracy ();
	setLinks ();
	Forms.ActivatePage ( ThisObject, "Items,Services,Discounts" );
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	FormsFilter = Metadata.Documents.InvoiceRecord.Attributes.Range.ChoiceParameters [ 0 ].Value;
	
EndProcedure

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Rate Factor enable Object.Currency <> LocalCurrency;
	|Base show filled ( Object.Base );
	|PageServices show Object.ShowServices;
	|Company Customer Currency Rate Factor VATUse Items Services Discounts Prices Date LoadingPoint UnloadingPoint
	|lock filled ( Object.Base );
	|GroupHeader PageMain PageMore Footer unlock Object.Status = Enum.FormStatuses.Saved;
	|Warning hide Object.Status = Enum.FormStatuses.Saved;
	|LoadingAddress enable filled ( Object.LoadingPoint );
	|UnloadingAddress enable filled ( Object.UnloadingPoint );
	|ItemsSelectItems ItemsScan ServicesSelectItems enable empty ( Object.Base );
	|Redirects enable not Object.Transfer;
	|Links show ShowLinks;
	|Series FormNumber show filled ( Object.Range );
	|Number show empty ( Object.Range );
	|ItemsVAT ItemsVATCode ItemsTotal ServicesVAT ServicesVATCode ServicesTotal DiscountsVATCode
	|show Object.VATUse > 0;
	|ItemsProducerPrice ItemsExtraCharge show UseSocial;
	|FormUnloadInvoices FormLoadInvoices show RangeOnline;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	if ( Object.LoadingPoint.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Warehouse" );
		Object.Company = settings.Company;
		Object.LoadingPoint = settings.Warehouse;
	else
		Object.Company = DF.Pick ( Object.LoadingPoint, "Owner" );
	endif;
	Object.Base = undefined;
	Object.ShowServices = true;
	Object.Prices = DF.Pick ( Object.Company, "CostPrices" );
	Object.Currency = Application.Currency ();
	if ( not Object.LoadingPoint.IsEmpty () ) then
		setLoadingAddress ( Object );
	endif;
	if ( not Object.Company.IsEmpty () ) then
		setAccount ( Object );
	endif;
	if ( ValueIsFilled ( Object.Customer ) ) then
		setCustomerAccount ( Object );
	endif;
	
EndProcedure

&AtClientAtServerNoContext
Procedure setLoadingAddress ( Object ) 

	Object.LoadingAddress = DF.Pick ( Object.LoadingPoint, "Address" );

EndProcedure

&AtClientAtServerNoContext
Procedure setAccount ( Object ) 

	Object.Account = DF.Pick ( Object.Company, "BankAccount" );

EndProcedure

&AtClientAtServerNoContext
Procedure setCustomerAccount ( Object )

	customer = Object.Customer;
	if ( TypeOf ( customer ) = Type ( "CatalogRef.Companies" ) ) then
		account = DF.Pick ( customer, "BankAccount" );
	else
		account = DF.Pick ( customer, "CustomerContract.CustomerBank" );
	endif;
	Object.CustomerAccount = account;

EndProcedure

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
	
EndProcedure 

&AtServer
Procedure setRange ()
	
	s = "
	|select allowed top 1 Documents.Range as Range
	|from Document.InvoiceRecord as Documents
	|where Documents.Company = &Company
	|and Documents.Creator = &Creator
	|and not Documents.DeletionMark
	|order by Documents.Date desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Company", Object.Company );
	q.SetParameter ( "Creator", Object.Creator );
	table = q.Execute ().Unload ();
	Object.Range = ? ( table.Count () = 0, undefined, table [ 0 ].Range );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setType ( Object )
	
	type = DF.Pick ( Object.Range, "Print" );
	if ( type.IsEmpty () ) then
		return;
	endif;
	Object.Type = type;
	
EndProcedure

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Base", Object.Base );
		q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	selection = Env.Selection;
	BaseExists = ValueIsFilled ( Object.Base );
	if ( BaseExists ) then
		BaseMetadata = Metadata.FindByType ( TypeOf ( Object.Base ) );
		s = "
		|// #Base
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document." + BaseMetadata.Name + " as Documents
		|where Documents.Ref = &Base
		|";
		selection.Add ( s );
	endif;
	if ( isNew () ) then
		return;
	endif; 
	meta = Metadata.Documents;
	ViewWriteOff = AccessRight ( "View", meta.WriteOffForm );
	if ( ViewWriteOff ) then
		s = "
		|// #WriteOffs
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.WriteOffForm as Documents
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
	if ( BaseExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Base, BaseMetadata ) );
	endif; 
	if ( not isNew () ) then
		if ( ViewWriteOff ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.WriteOffs, meta.WriteOffForm ) );
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

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	if ( SelectedValue.Operation = Enum.ChoiceOperationsPickItems () ) then
		addSelectedItems ( SelectedValue );
		addSelectedServices ( SelectedValue );
		calcTotals ( Object );
		applySocial ();
	endif; 
	
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

&AtClientAtServerNoContext
Procedure calcTotals ( Object )
	
	items = Object.Items;
	services = Object.Services;
	discounts = Object.Discounts;
	Object.VAT = items.Total ( "VAT" ) + services.Total ( "VAT" ) - discounts.Total ( "VAT" );
	Object.Amount = items.Total ( "Total" ) + services.Total ( "Total" ) - discounts.Total ( "Amount" );
	
EndProcedure 

&AtClient
Procedure applySocial () 

	UseSocial = findSocial ( Object.Items );
	Appearance.Apply ( ThisObject, "UseSocial" );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	Forms.DeleteLastRow ( Object.Items, "Item" );
	calcTotals ( Object );
	
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
	itemsTable = Object.Items;
	rows = itemsTable.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = itemsTable.Add ();
		item = Fields.Item;
		row.Item = item;
		package = Fields.Package;
		row.Package = package;
		feature = Fields.Feature;
		row.Feature = feature;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Quantity = Fields.Quantity;
		row.Price = Goods.Price ( , Object.Date, Object.Prices, item, package, feature, Object.Customer, , , Object.LoadingPoint, Object.Currency );
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
Procedure AfterWrite ( WriteParameters ) 
	
	Appearance.Apply ( ThisObject, "Object.Status" );
	base = Object.Base;
	if ( not ValueIsFilled ( base ) ) then
		return;
	endif;
	Notify ( Enum.InvoiceRecordsWrite (), Object.Status, new Structure ( "Ref, Base", Object.Ref, base ) );
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	setLinks ();
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Print ( Command )
	
	checkAndPrint ();

EndProcedure

&AtClient
Procedure checkAndPrint ()
	
	status = Object.Status;
	if ( status = PredefinedValue ( "Enum.FormStatuses.Saved" ) ) then
		if ( not RangeOnline ) then
			Object.Status = PredefinedValue ( "Enum.FormStatuses.Printed" );
		endif;
	elsif ( status = PredefinedValue ( "Enum.FormStatuses.Unloaded" ) ) then
		Object.Status = PredefinedValue ( "Enum.FormStatuses.Printed" );
	endif;
	if ( Write () ) then
		FormsPrint.InvoiceRecord ( Object.Ref );
	endif;
	
EndProcedure

&AtClient
Procedure DateOnChange ( Item )
	
	applyDate ();
	
EndProcedure

&AtClient
Procedure applyDate ()
	
	Object.DeliveryDate = Object.Date;
	
EndProcedure

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	rates = CurrenciesSrv.Get ( object.Currency );
	object.Rate = rates.Rate;
	object.Factor = rates.Factor;
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure 

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	setAccount ( Object );
	
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
	currency = Object.Currency;
	vatUse = Object.VATUse;
	warehouse = Object.LoadingPoint;
	customer = Object.Customer;
	for each row in Object.Items do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, customer, , , warehouse, currency );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	calcTotals ( Object );
	
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
		Computations.ExtraCharge ( row );
	enddo;
	for each row in Object.Services do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	DiscountsTable.RecalcVAT ( ThisObject );
	calcTotals ( Object );
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
EndProcedure

&AtClient
Procedure LoadingPointOnChange ( Item )
	
	setLoadingAddress ( Object );
	Appearance.Apply ( ThisObject, "Object.LoadingPoint" );
	
EndProcedure

&AtClient
Procedure UnloadingPointOnChange ( Item )
	
	setUnloadingAddress ();
	Appearance.Apply ( ThisObject, "Object.UnloadingPoint" );
	
EndProcedure

&AtClient
Procedure setUnloadingAddress () 

	point = Object.UnloadingPoint;
	if ( TypeOf ( point ) = Type ( "CatalogRef.Warehouses" ) ) then
		address = DF.Pick ( point, "Address" );
	else
		address = DF.Pick ( point, "ShippingAddress" );
	endif;
	Object.UnloadingAddress = address;

EndProcedure

&AtClient
Procedure RangeStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	chooseRange ( Item );
	
EndProcedure

&AtClient
Procedure chooseRange ( Item )
	
	filter = new Structure ();
	date = Periods.GetBalanceDate ( Object );
	if ( date <> undefined
		and not Object.Ref.IsEmpty () ) then
		date = date - 1;
	endif;
	filter.Insert ( "Date", date );
	filter.Insert ( "Type", FormsFilter );
	filter.Insert ( "Warehouse", Object.LoadingPoint );
	OpenForm ( "Catalog.Ranges.Form.Balances", new Structure ( "Filter", filter ), Item );
	
EndProcedure

&AtClient
Procedure RangeOnChange ( Item )
	
	setWarning ( ThisObject );
	setType ( Object );
	initStatuses ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Range, RangeOnline" );
	
EndProcedure

&AtClient
Procedure CustomerOnChange ( Item )
	
	setCustomerAccount ( Object );
	
EndProcedure

&AtClient
Procedure TransferOnChange ( Item )
	
	if ( Object.Transfer ) then
		Object.Redirects = OutputCont.Transfer ();;
	else
		Object.Redirects = "";
	endif;
	Appearance.Apply ( ThisObject, "Object.Transfer" );
	
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
	enableColumns ();
	
EndProcedure

&AtClient
Procedure enableColumns () 

	if ( ItemsRow = undefined ) then
		return;
	endif;
	flag = TypeOf ( ItemsRow.Item ) <> Type ( "CatalogRef.Items" );
	Items.ItemsFeature.ReadOnly = flag;
	Items.ItemsSeries.ReadOnly = flag;
	Items.ItemsPackage.ReadOnly = flag;
	enableSocial ()

EndProcedure

&AtClient
Procedure enableSocial () 

	if ( ItemsRow = undefined ) then
		return;
	endif;
	flag = not ItemsRow.Social;
	Items.ItemsProducerPrice.ReadOnly = flag;
	Items.ItemsExtraCharge.ReadOnly = flag;

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
Procedure ItemsBeforeRowChange ( Item, Cancel )
	
	enableSocial ();
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	applySocial ();
	enableSocial ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	item = ItemsRow.Item;
	if ( TypeOf ( item ) = Type ( "CatalogRef.Items" ) ) then
		p = new Structure ();
		p.Insert ( "Date", Object.Date );
		p.Insert ( "Company", Object.Company );
		p.Insert ( "Warehouse", Object.LoadingPoint );
		p.Insert ( "Currency", Object.Currency );
		p.Insert ( "Item", item );
		p.Insert ( "Prices", Object.Prices );
		p.Insert ( "Customer", Object.Customer );
		p.Insert ( "Prices", Object.Prices );
		data = getItemData ( p );
		ItemsRow.Package = data.Package;
		ItemsRow.Capacity = data.Capacity;
		ItemsRow.Price = data.Price;
		ItemsRow.VATCode = data.VAT;
		ItemsRow.VATRate = data.Rate;
		ItemsRow.ProducerPrice = data.ProducerPrice;
		ItemsRow.Social = data.Social;
		Computations.Units ( ItemsRow );
		Computations.Amount ( ItemsRow );
		Computations.Total ( ItemsRow, Object.VATUse );
		Computations.ExtraCharge ( ItemsRow );
	else
		data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
		ItemsRow.VATCode = data.VAT;
		ItemsRow.VATRate = data.Rate;
	endif;
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	date = Params.Date;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate, Social" );
	package = data.Package;
	price = Goods.Price ( , date, Params.Prices, item, package, , Params.Customer, , , Params.Warehouse, Params.Currency );
	data.Insert ( "Price", price );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif;
	p = itemParams ( item, package );
	data.Insert ( "ProducerPrice", ? ( data.Social, Goods.ProducerPrice ( p, date ), 0 ) );
	return data;
	
EndFunction 

&AtClientAtServerNoContext
Function itemParams ( val Item, val Package, val Feature = undefined ) 

	p = new Structure ();
	p.Insert ( "Item", Item );
	p.Insert ( "Package", Package );
	p.Insert ( "Feature", Feature );
	return p;

EndFunction

&AtClient
Procedure ItemsFeatureOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	setProducerPrice ();
	Computations.ExtraCharge ( ItemsRow );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	ItemsRow.Price = Goods.Price ( , Object.Date, prices, ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature, Object.Customer, , , Object.LoadingPoint, Object.Currency );
	
EndProcedure 

&AtClient
Procedure setProducerPrice () 

	if ( not ItemsRow.Social ) then
		return
	endif;
	p = itemParams ( ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature );
	ItemsRow.ProducerPrice = Goods.ProducerPrice ( p, Object.Date );

EndProcedure

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Warehouse", Object.LoadingPoint );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Feature", ItemsRow.Feature );
	p.Insert ( "Package", ItemsRow.Package );
	p.Insert ( "Customer", Object.Customer );
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	p.Insert ( "Prices", prices );
	p.Insert ( "Social", ItemsRow.Social );
	data = getPackageData ( p );
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	Computations.ExtraCharge ( ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	date = Params.Date;
	price = Goods.Price ( , date, Params.Prices, Params.Item, package, Params.Feature, Params.Customer, , , Params.Warehouse, Params.Currency );
	data = new Structure ();
	data.Insert ( "Capacity", capacity );
	data.Insert ( "Price", price );
	data.Insert ( "ProducerPrice", ? ( Params.Social, Goods.ProducerPrice ( Params, date ), 0 ) );
	return data;
	
EndFunction 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	Computations.ExtraCharge ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	Computations.ExtraCharge ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPriceOnChange ( Item )

	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	Computations.ExtraCharge ( ItemsRow );

EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	Computations.Price ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	Computations.ExtraCharge ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPricesOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	Computations.ExtraCharge ( ItemsRow );
	
EndProcedure                                       

&AtClient
Procedure ItemsVATCodeOnChange ( Item )
	
	ItemsRow.VATRate = DF.Pick ( ItemsRow.VATCode, "Rate" );
	Computations.Total ( ItemsRow, Object.VATUse );
	Computations.ExtraCharge ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsVATOnChange ( Item )
	
	Computations.Total ( ItemsRow, Object.VATUse, false );
	Computations.ExtraCharge ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsProducerPriceOnChange ( Item )
	
	Computations.ExtraCharge ( ItemsRow );
	
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
	p.Insert ( "Warehouse", Object.LoadingPoint );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Customer", Object.Customer );
	p.Insert ( "Item", ServicesRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getServiceData ( p );
	ServicesRow.Price = data.Price;
	ServicesRow.Description = data.FullDescription;
	ServicesRow.VATCode = data.VAT;
	ServicesRow.VATRate = data.Rate;
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getServiceData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "FullDescription, VAT, VAT.Rate as Rate" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, , , Params.Customer, , , Params.Warehouse, Params.Currency );
	data.Insert ( "Price", price );
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
	ServicesRow.Price = Goods.Price ( , Object.Date, prices, ServicesRow.Item, , ServicesRow.Feature, Object.Customer, , , Object.LoadingPoint, Object.Currency );
	
EndProcedure 

&AtClient
Procedure ServicesQuantityOnChange ( Item )
	
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesPriceOnChange ( Item )
	
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesAmountOnChange ( Item )
	
	Computations.Price ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesPricesOnChange ( Item )
	
	priceService ();
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
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
// *********** Table Discounts

&AtClient
Procedure DiscountsOnEditEnd ( Item, NewRow, CancelEdit )

	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure DiscountsAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure DiscountsItemOnChange ( Item )
	
	DiscountsTable.ApplyItem ( ThisObject );

EndProcedure

&AtClient
Procedure DiscountsVATCodeOnChange ( Item )
	
	DiscountsTable.SetRate ( ThisObject );
	DiscountsTable.CalcVAT ( ThisObject );
	
EndProcedure

&AtClient
Procedure DiscountsAmountOnChange ( Item )
	
	DiscountsTable.CalcVAT ( ThisObject );

EndProcedure
