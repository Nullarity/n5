&AtServer
var Env;
&AtServer
var Base;
&AtClient
var ItemsRow;
&AtServer
var InvoiceRecordExists;
&AtServer
var ShipmentExists;
&AtServer
var ShipmentMetadata;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	InvoiceRecords.Read ( ThisObject );
	InvoiceForm.SetLocalCurrency ( ThisObject );
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( isNew () ) then
		InvoiceForm.SetLocalCurrency ( ThisObject );
		DocumentForm.Init ( Object );
		Base = Parameters.Basis;
		if ( Base = undefined ) then
			fillNew ();
		else
			baseType = TypeOf ( Base );
			if ( baseType = Type ( "DocumentRef.SalesOrder" )
				or baseType = Type ( "DocumentRef.InternalOrder" ) ) then
				fillByOrder ();
			elsif ( baseType = Type ( "DocumentRef.ShipmentStockman" ) ) then
				fillByShipmentStockman ();
			endif; 
		endif;
		Constraints.ShowAccess ( ThisObject );
	endif; 
	setAccuracy ();
	setLinks ();
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
	|Rate Factor enable Object.Currency <> LocalCurrency;
	|Links show ShowLinks;
	|Prices GrossAmount Amount VATUse show Object.ShowPrices;
	|VAT show ( Object.ShowPrices and Object.VATUse > 0 );
	|FormInvoice show filled ( InvoiceRecord );
	|NewInvoiceRecord show FormStatus = Enum.FormStatuses.Canceled or empty ( FormStatus );
	|Warning show ChangesDisallowed;
	|Header GroupItems Footer GroupMore lock ChangesDisallowed;
	|ItemsTableCommandBar disable ChangesDisallowed;
	|ItemsPrice ItemsAmount ItemsPrices show Object.ShowPrices;
	|ItemsVAT ItemsVATCode ItemsTotal show ( Object.ShowPrices and Object.VATUse > 0 )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Parameters.Basis <> undefined
		or not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	if ( Object.Sender.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Warehouse" );
		Object.Company = settings.Company;
		Object.Sender = settings.Warehouse;
	else
		Object.Company = DF.Pick ( Object.Sender, "Owner" );
	endif;
	if ( not Object.Receiver.IsEmpty () ) then
		company = DF.Pick ( Object.Receiver, "Owner" );
		if ( company <> Object.Company ) then
			Object.Receiver = undefined;
		endif; 
	endif;
	Object.Prices = DF.Pick ( Object.Company, "CostPrices" );
	Object.Currency = Application.Currency ();
	
EndProcedure 

#region Filling

&AtServer
Procedure fillByOrder ()
	
	setEnv ();
	setContext ();
	setSender ();
	sqlFields ();
	sqlReserves ();
	sqlItems ();
	SQL.Perform ( Env );
	headerByOrder ();
	itemsByOrder ();
	
EndProcedure

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	q = Env.Q;
	q.SetParameter ( "Base", Base );
	q.SetParameter ( "Warehouse", Object.Sender );
	
EndProcedure

&AtServer
Procedure setContext () 

	baseType = TypeOf ( Base );
	if ( baseType = Type ( "DocumentRef.SalesOrder" ) ) then
		Env.Insert ( "Table", "SalesOrder" );
	else
		Env.Insert ( "Table", "InternalOrder" );
	endif;

EndProcedure

&AtServer
Procedure setSender () 

	Object.Sender = Logins.Settings ( "Warehouse" ).Warehouse;;

EndProcedure

&AtServer
Procedure sqlFields () 

	s = "
	|// @Fields
	|select Documents.Warehouse as Warehouse, Documents.Company as Company, Documents.Currency as Currency
	|from Document." + Env.Table + " as Documents
	|where Documents.Ref = &Base
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServer
Procedure sqlReserves () 

	s = "
	|// Reserves
	|select Reserves.DocumentOrder as DocumentOrder, Reserves.RowKey as RowKey, Reserves.QuantityBalance as Quantity, Reserves.Warehouse as Warehouse
	|into Reserves
	|from AccumulationRegister.Reserves.Balance ( , DocumentOrder = &Base 
	|";
	if ( not Object.Sender.IsEmpty () ) then
		s = s + "and Warehouse = &Warehouse";
	endif;
	s = s + " ) as Reserves
	|where Reserves.QuantityBalance > 0
	|index by Reserves.DocumentOrder, Reserves.RowKey
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServer
Procedure sqlItems ()
	
	s = "
	|// #Items
	|select Items.Item as Item, Items.Feature as Feature, case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when Items.Item.CountPackages then Reserves.Quantity / Items.Capacity else Reserves.Quantity end as QuantityPkg,
	|	Reserves.DocumentOrder as DocumentOrder, Reserves.Quantity as Quantity, Reserves.RowKey as RowKey, Reserves.Warehouse as Sender
	|from Document." + Env.Table + ".Items as Items
	|	//
	|	// Reserves
	|	//
	|	join Reserves as Reserves
	|	on Reserves.RowKey = Items.RowKey
	|	and Reserves.DocumentOrder = Items.Ref
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByOrder () 

	fields = Env.Fields;
	Object.Company = fields.Company;
	Object.Receiver = fields.Warehouse;
	Object.Currency = fields.Currency;
	if ( Object.Sender.IsEmpty ()
		and Env.Items.Count () > 0 ) then
		Object.Sender = Env.Items [ 0 ].Sender;
	endif;

EndProcedure

&AtServer
Procedure itemsByOrder () 

	balances = Env.Items;
	if ( balances.Count () = 0 ) then
		return;
	endif;
	table = Object.Items;
	company = Env.Fields.Company;
	sender = Object.Sender;
	oneWarehouse = not Options.WarehousesInTable ( company );
	for each row in balances do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row );
		if ( oneWarehouse
			or sender = row.Sender ) then
			row.Sender = undefined;
		endif; 
		account = AccountsMap.Item ( row.Item, company, row.Sender, "Account" ).Account;
		newRow.Account = account;
		newRow.AccountReceiver = account;
	enddo;

EndProcedure

&AtServer
Procedure fillByShipmentStockman ()
	
	setEnv ();
	sqlShipmentStockman ();
	SQL.Perform ( Env );
	headerByShipmentStockman ();
	loadShipmentStockman ();
	
EndProcedure

&AtServer
Procedure sqlShipmentStockman ()
	
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.Warehouse as Sender, Documents.Stock as Receiver,
	|	Documents.Invoiced as Invoiced
	|from Document.ShipmentStockman as Documents
	|where Documents.Ref = &Base
	|;
	|// #Items
	|select Items.Item as Item, Items.Feature as Feature, Items.Series as Series, Items.Package as Package,
	|	Items.Capacity as Capacity, Items.Quantity as Quantity, Items.QuantityPkg as QuantityPkg,
	|	Items.Item.VAT as VATCode, Items.Item.VAT.Rate as VATRate
	|from Document.ShipmentStockman.Items as Items
	|where Items.Ref = &Base
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByShipmentStockman ()
	
	fields = Env.Fields;
	if ( fields.Invoiced ) then
		raise Output.DocumentAlreadyInvoiced ( new Structure ( "Document", Base ) );
	endif;
	FillPropertyValues ( Object, fields );
	Object.Shipment = Base;
	Object.Currency = Application.Currency ();
	
EndProcedure 

&AtServer
Procedure loadShipmentStockman ()
	
	company = Object.Company;
	sender = Object.Sender;
	itemsTable = Object.Items;
	for each row in Env.Items do
		newRow = itemsTable.Add ();
		FillPropertyValues ( newRow, row );
		account = AccountsMap.Item ( row.Item, company, sender, "Account" ).Account;
		newRow.Account = account;
		newRow.AccountReceiver = account;
	enddo; 

EndProcedure

#endregion

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
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
		q.SetParameter ( "Shipment", Object.Shipment );
		q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	selection = Env.Selection;
	ShipmentExists = Object.Shipment <> undefined;
	if ( ShipmentExists ) then
		ShipmentMetadata = Metadata.FindByType ( TypeOf ( Object.Shipment ) );
		s = "
		|// #Shipments
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document." + ShipmentMetadata.Name + " as Documents
		|where Documents.Ref = &Shipment
		|";
		selection.Add ( s );
	endif;
	if ( isNew () ) then
		return;
	endif;
	InvoiceRecordExists = not InvoiceRecord.IsEmpty ();
	if ( InvoiceRecordExists ) then
		s = "
		|// #InvoiceRecords
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.InvoiceRecord as Documents
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
	if ( ShipmentExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Shipments, ShipmentMetadata ) );
	endif;	
	if ( not isNew () ) then
		if ( InvoiceRecordExists ) then
			parts.Add ( URLPanel.DocumentsToURL ( Env.InvoiceRecords, meta.InvoiceRecord ) );
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
		calcTotals ( Object );
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

&AtClientAtServerNoContext
Procedure calcTotals ( Object )
	
	items = Object.Items;
	vat = items.Total ( "VAT" );
	amount = items.Total ( "Total" );
	Object.VAT = vat;
	Object.Amount = amount;
	Object.GrossAmount = amount - ? ( Object.VATUse = 2, vat, 0 );
	
EndProcedure 

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	readNewInvoice ( NewObject );
	
EndProcedure

&AtServer
Procedure readNewInvoice ( NewObject ) 

	type = TypeOf ( NewObject );
	if ( type = Type ( "DocumentRef.InvoiceRecord" ) ) then
		InvoiceRecords.Read ( ThisObject );
		setLinks ();
		Appearance.Apply ( ThisObject, "InvoiceRecord, ShowLinks, FormStatus, ChangesDisallowed" );
	endif;

EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	elsif ( EventName = Enum.InvoiceRecordsWrite ()
		and Source.Ref = InvoiceRecord ) then
		readPrinted ();	
	elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature, Series" );
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
		row.Series = Fields.Series;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Quantity = Fields.Quantity;
		sender = Object.Sender;
		row.Price = Goods.Price ( , Object.Date, Object.Prices, item, package, feature, , , , sender, Object.Currency );
		data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
		row.VATCode = data.VAT;
		row.VATRate = data.Rate;
		account = AccountsMap.Item ( item, Object.Company, sender, "Account" ).Account;
		row.Account = account;
		row.AccountReceiver = account;
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	Computations.Amount ( row );
	Computations.Total ( row, Object.VATUse );
	calcTotals ( Object );
	
EndProcedure 

&AtServer
Procedure readPrinted ()
	
	InvoiceRecords.Read ( ThisObject );
	Appearance.Apply ( ThisObject, "FormStatus, ChangesDisallowed" );
	
EndProcedure 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	Forms.DeleteLastRow ( Object.Items, "Item" );
	calcTotals ( Object );
	
EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	completeShipment ();
	if ( Object.Ref.IsEmpty () ) then
		return;
	endif;
	readPrinted ();
	Appearance.Apply ( ThisObject, "InvoiceRecord" );
	
EndProcedure

&AtServer
Procedure completeShipment ()
	
	shipment = Object.Shipment;
	if ( TypeOf ( shipment ) = Type ( "DocumentRef.ShipmentStockman" ) ) then
		Documents.ShipmentStockman.Complete ( shipment );
	endif;

EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageTransferIsSaved (), Object.Ref );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
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
	for each row in Object.Items do
		row.Prices = undefined;
		warehouse = getWarehouse ( row, Object );
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, , , , warehouse, currency );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	calcTotals ( Object );
	
EndProcedure 

&AtClientAtServerNoContext
Function getWarehouse ( TableRow, Object )
	
	return ? ( TableRow.Sender.IsEmpty (), Object.Sender, TableRow.Sender );
	
EndFunction 

&AtClient
Procedure ShowPricesOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.ShowPrices" );
	
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
	calcTotals ( Object );
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
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
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Warehouse", getWarehouse ( ItemsRow, Object ) );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	ItemsRow.VATCode = data.VAT;
	ItemsRow.VATRate = data.Rate;
	ItemsRow.Account = data.Account;
	ItemsRow.AccountReceiver = data.Account;
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate" );
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
	warehouse = getWarehouse ( ItemsRow, Object );
	ItemsRow.Price = Goods.Price ( , Object.Date, prices, ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature, , , , warehouse, Object.Currency );
	
EndProcedure 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Warehouse", getWarehouse ( ItemsRow, Object ) );
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
Procedure ItemsRangeStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	RegulatedRangesForm.Choose ( Item, Object, ItemsRow, getWarehouse ( ItemsRow, Object ) );
	
EndProcedure

