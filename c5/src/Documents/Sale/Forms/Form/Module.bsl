&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
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
	|ThisObject lock Object.Posted;
	|VAT ItemsVATCode ItemsVAT show Object.VATUse > 0;
	|ItemsTotal show Object.VATUse = 2;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Object.Warehouse.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Warehouse, Warehouse.Prices as Prices,
		|PaymentLocation, PaymentLocation.Method as Method" );
		Object.Company = settings.Company;
		Object.Warehouse = settings.Warehouse;
		Object.Location = settings.PaymentLocation;
		method = settings.Method;
		Object.Prices = settings.Prices;
	else
		fields = DF.Values ( Object.Warehouse, "Owner, Prices" );
		Object.Company = fields.Owner;
		Object.Prices = fields.Prices;
		settings = Logins.Settings ( "PaymentLocation, PaymentLocation.Method as Method" );
		Object.Location = settings.PaymentLocation;
		method = settings.Method;
	endif;
	if ( Metadata.Documents.Sale.Attributes.Method.ChoiceParameters [ 0 ].Value.Find ( method ) <> undefined ) then
		Object.Method = method;
	endif;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure updateTotals ( Form, Row = undefined, CalcVAT = true )

	object = Form.Object;
	if ( Row <> undefined ) then
		Computations.Total ( Row, object.VATUse, CalcVAT );
	endif;
	InvoiceForm.CalcTotals ( Form );

EndProcedure 

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
	
EndProcedure 

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	if ( SelectedValue.Operation = Enum.ChoiceOperationsPickItems () ) then
		addSelectedItems ( SelectedValue );
		updateTotals ( ThisObject );
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
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	endif; 
	
EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature, Series" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = Object.Items.Add ();
		item = Fields.Item;
		row.Item = item;
		package = Fields.Package;
		row.Package = package;
		row.Series = Fields.Series;
		feature = Fields.Feature;
		row.Feature = feature;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Quantity = Fields.Quantity;
		row.Price = Goods.Price ( , Object.Date, Object.Prices, item, package, feature, , , , Object.Warehouse );
		data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
		row.VATCode = data.VAT;
		row.VATRate = data.Rate;
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	Computations.Amount ( row );
	updateTotals ( ThisObject, row );
	
EndProcedure 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	Forms.DeleteLastRow ( Object.Items, "Item" );
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	updateTotals ( ThisObject );

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject, "Object.Posted" );	
	
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
	updateTotals ( ThisObject );

EndProcedure

&AtServer
Procedure applyPrices ()
	
	cache = new Map ();
	vatUse = Object.VATUse;
	date = Object.Date;
	prices = Object.Prices;
	warehouse = Object.Warehouse;
	for each row in Object.Items do
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, , , , warehouse );
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

&AtServer
Procedure applyVATUse ()
	
	vatUse = Object.VATUse;
	for each row in Object.Items do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
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
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
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
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Warehouse", Object.Warehouse );
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
	updateTotals ( ThisObject, ItemsRow )
	
EndProcedure

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate" );
	warehouse = Params.Warehouse;
	package = data.Package;
	price = Goods.Price ( , Params.Date, Params.Prices, item, package, , , , , warehouse );
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
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	ItemsRow.Price = Goods.Price ( , Object.Date, Object.Prices, ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature,
		, , , Object.Warehouse );
	
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
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Feature", ItemsRow.Feature );
	p.Insert ( "Package", ItemsRow.Package );
	p.Insert ( "Prices", Object.Prices );
	data = getPackageData ( p );
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	Computations.Units ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	date = Params.Date;
	price = Goods.Price ( , date, Params.Prices, Params.Item, package, Params.Feature, , , , Params.Warehouse );
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
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Discount ( ItemsRow );
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
Procedure ItemsVATCodeOnChange ( Item )
	
	ItemsRow.VATRate = DF.Pick ( ItemsRow.VATCode, "Rate" );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsVATOnChange ( Item )
	
	updateTotals ( ThisObject, ItemsRow, false );
	
EndProcedure
