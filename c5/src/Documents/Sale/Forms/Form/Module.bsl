&AtServer
var Env;
&AtServer
var Copying;
&AtServer
var Base;
&AtServer
var BaseExists;
&AtServer
var BaseMetadata;
&AtServer
var BaseMetadataName;
&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	InvoiceRecords.Read ( ThisObject );
	findRetailSales ();
	calcChange ( ThisObject );
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure findRetailSales ()
	
	ref = Documents.RetailSales.Fetch ( Object.Date, Object.Warehouse, Object.Location, Object.Method );
	RetailSalesPosted = ref <> undefined;

EndProcedure

&AtClientAtServerNoContext
Procedure calcChange ( Form )
	
	object = Form.Object;
	Form.Change = Max ( 0, object.Taken - object.Amount );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	if ( isNew () ) then
		DocumentForm.Init ( Object );
		if ( BaseExists and not Copying ) then
			if ( BaseMetadata = Metadata.Documents.Invoice ) then
				fillByInvoice ();
			elsif ( BaseMetadata = Metadata.Documents.Return ) then
				fillByReturn ();
			endif;
		else
			fillNew ();
		endif;
		Constraints.ShowAccess ( ThisObject );
	endif; 
	setAccuracy ();
	setLinks ();
	Options.Company ( ThisObject, Object.Company );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	Copying = not Parameters.CopyingValue.IsEmpty ();
	getBase ();

EndProcedure

&AtServer
Procedure changeBase ( Value )
	
	Object.Base = Value;
	Base = undefined;
	getBase ();

EndProcedure

&AtServer
Procedure getBase ()
	
	if ( Base <> undefined ) then
		return;
	endif;
	basis = undefined;
	Parameters.Property ( "Basis", basis );
	Base = ? ( Object.Base = undefined, basis, Object.Base );
	BaseExists = Base <> undefined;
	if ( BaseExists ) then
		BaseMetadata = Metadata.FindByType ( TypeOf ( Base ) );
		BaseMetadataName = BaseMetadata.Name;
	else
		BaseMetadata = undefined;
		BaseMetadataName = undefined;
	endif;

EndProcedure

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

#region Filling

&AtServer
Procedure fillByInvoice ()
	
	Object.Base = Base;
	setEnv ();
	sqlInvoiceFields ();
	sqlInvoiceItems ();
	SQL.Perform ( Env );
	FillPropertyValues ( Object, Env.Fields );
	Object.Items.Load ( Env.Items );
	InvoiceForm.CalcTotals ( ThisObject );

EndProcedure

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	Env.Q.SetParameter ( "Me", SessionParameters.User );
	
EndProcedure

&AtServer
Procedure sqlInvoiceFields ()
	
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.Prices as Prices, Documents.VATUse as VATUse,
	|	Documents.Warehouse as Warehouse,
	|	Settings.PaymentLocation as Location, Settings.PaymentLocation.Method as Method
	|from Document.Invoice as Documents
	|	//
	|	// Settings
	|	//
	|	left join Catalog.UserSettings as Settings
	|	on Settings.Owner = &Me
	|	and Settings.Company = Documents.Company
	|where Documents.Ref = &Base
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServer
Procedure sqlInvoiceItems ()
	
	s = "
	|// #Items
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Package as Package, Items.Capacity as Capacity,
	|	Items.DiscountRate as DiscountRate, Items.Feature as Feature, Items.Quantity as Quantity,
	|	Items.QuantityPkg as QuantityPkg, Items.VATCode as VATCode, Items.VATRate as VATRate,
	|	case Items.Ref.Currency
	|		when Constants.Currency then Items.Discount
	|		else cast ( Items.Discount * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|	end as Discount,
	|	case Items.Ref.Currency
	|		when Constants.Currency then Items.Price
	|		else cast ( Items.Price * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|	end as Price,
	|	case Items.Ref.Currency
	|		when Constants.Currency then Items.VAT
	|		else cast ( Items.VAT * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|	end as VAT,
	|	case Items.Ref.Currency
	|		when Constants.Currency then Items.Total
	|		else cast ( Items.Total * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|	end as Total,
	|	case when Items.Ref.VATUse = 2 then
	|			case Items.Ref.Currency
	|				when Constants.Currency then Items.Amount
	|				else cast ( Items.Total * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|					- cast ( Items.VAT * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|			end
	|		else
	|			case Items.Ref.Currency
	|				when Constants.Currency then Items.Amount
	|				else cast ( Items.Amount * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|			end
	|	end as Amount
	|from Document.Invoice.Items as Items
	|	//
	|	// Constants
	|	//
	|	join Constants
	|	on true
	|where Items.Ref = &Base
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServer
Procedure fillByReturn ()
	
	Object.Base = Base;
	setEnv ();
	sqlReturnFields ();
	sqlReturnItems ();
	SQL.Perform ( Env );
	FillPropertyValues ( Object, Env.Fields );
	Object.Items.Load ( Env.Items );
	InvoiceForm.CalcTotals ( ThisObject );
	Object.Return = true;
	revert ( Object );

EndProcedure

&AtServer
Procedure sqlReturnFields ()
	
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.VATUse as VATUse,
	|	Documents.Warehouse as Warehouse, Invoices.Invoice.Prices as Prices,
	|	Settings.PaymentLocation as Location, Settings.PaymentLocation.Method as Method
	|from Document.Return as Documents
	|	//
	|	// Settings
	|	//
	|	left join Catalog.UserSettings as Settings
	|	on Settings.Owner = &Me
	|	and Settings.Company = Documents.Company
	|	//
	|	// First Invoice
	|	//
	|	left join Document.Return.Items as Invoices
	|	on Invoices.Ref = &Base
	|	and Invoices.LineNumber = 1
	|where Documents.Ref = &Base
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServer
Procedure sqlReturnItems ()
	
	s = "
	|// #Items
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Package as Package, Items.Capacity as Capacity,
	|	Items.DiscountRate as DiscountRate, Items.Feature as Feature, Items.Quantity as Quantity,
	|	Items.QuantityPkg as QuantityPkg, Items.VATCode as VATCode, Items.VATRate as VATRate,
	|	case Items.Ref.Currency
	|		when Constants.Currency then Items.Discount
	|		else cast ( Items.Discount * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|	end as Discount,
	|	case Items.Ref.Currency
	|		when Constants.Currency then Items.Price
	|		else cast ( Items.Price * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|	end as Price,
	|	case Items.Ref.Currency
	|		when Constants.Currency then Items.VAT
	|		else cast ( Items.VAT * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|	end as VAT,
	|	case Items.Ref.Currency
	|		when Constants.Currency then Items.Total
	|		else cast ( Items.Total * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|	end as Total,
	|	case when Items.Ref.VATUse = 2 then
	|			case Items.Ref.Currency
	|				when Constants.Currency then Items.Amount
	|				else cast ( Items.Total * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|					- cast ( Items.VAT * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|			end
	|		else
	|			case Items.Ref.Currency
	|				when Constants.Currency then Items.Amount
	|				else cast ( Items.Amount * Items.Ref.Rate / Items.Ref.Factor as Number ( 15, 2 ) )
	|			end
	|	end as Amount
	|from Document.Return.Items as Items
	|	//
	|	// Constants
	|	//
	|	join Constants
	|	on true
	|where Items.Ref = &Base
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );

EndProcedure

#endregion

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|ThisObject lock Object.Posted;
	|Warning show RetailSalesPosted;
	|WarningTaxInvoice show ChangesDisallowed;
	|VAT ItemsVATCode ItemsVAT show Object.VATUse > 0;
	|ItemsTotal show Object.VATUse = 2;
	|Taken Change show not ( Object.Posted or Object.Return ) and Object.Method = Enum.PaymentMethods.Cash;
	|FormInvoice show filled ( InvoiceRecord );
	|NewInvoiceRecord show Object.Base = undefined and ( FormStatus = Enum.FormStatuses.Canceled or empty ( FormStatus ) );
	|FormInvoice show filled ( InvoiceRecord );
	|GroupItems GroupMore lock ChangesDisallowed;
	|ItemsTableCommandBar disable ChangesDisallowed;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	Object.Taken = 0;
	if ( Copying ) then
		if ( BaseExists ) then
			changeBase ( undefined );
		else
			returning = not DF.Pick ( Parameters.CopyingValue, "Return" );
			if ( returning ) then
				Object.Return = true;
				revert ( Object );
			endif;
		endif;
	else
		if ( Object.Warehouse.IsEmpty () ) then
			settings = Logins.Settings ( "Company, Warehouse, Warehouse.Prices as Prices" );
			Object.Company = settings.Company;
			Object.Warehouse = settings.Warehouse;
			Object.Prices = settings.Prices;
		else
			fields = DF.Values ( Object.Warehouse, "Owner, Prices" );
			Object.Company = fields.Owner;
			Object.Prices = fields.Prices;
		endif;
		if ( Object.Location.IsEmpty () ) then
			settings = Logins.Settings ( "PaymentLocation, PaymentLocation.Method as Method" );
			Object.Location = settings.PaymentLocation;
			method = settings.Method;
		endif;
		if ( Metadata.Documents.Sale.Attributes.Method.ChoiceParameters [ 0 ].Value.Find ( method ) <> undefined ) then
			Object.Method = method;
		endif;
	endif;
	
EndProcedure

&AtClientAtServerNoContext
Procedure revert ( Object )
	
	for each row in Object.Items do
		row.Quantity = - row.Quantity;
		row.QuantityPkg = - row.QuantityPkg;
		row.VAT = - row.VAT;
		row.Total = - row.Total;
		row.Amount = - row.Amount;
	enddo;
	Object.Amount = - Object.Amount;
	Object.Discount = - Object.Discount;
	Object.GrossAmount = - Object.GrossAmount;
	Object.VAT = - Object.VAT;

EndProcedure 

&AtClientAtServerNoContext
Procedure updateTotals ( Form, Row = undefined, CalcVAT = true )

	object = Form.Object;
	if ( Row <> undefined ) then
		Computations.Total ( Row, object.VATUse, CalcVAT );
	endif;
	InvoiceForm.CalcTotals ( Form );
	calcChange ( Form );

EndProcedure 

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	
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
		q.SetParameter ( "Base", Object.Base );
		SQL.Perform ( Env, false );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()

	getBase ();
	if ( BaseExists ) then
		s = "
		|// #Base
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document." + BaseMetadataName + " as Documents
		|where Documents.Ref = &Base
		|";
		Env.Selection.Add ( s );
	endif;
	if ( isNew () ) then
		return;
	endif; 
	s = "
	|// #RetailSales
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.RetailSales as Documents
	|	//
	|	// Sale
	|	//
	|	join Document.Sale as Sales
	|	on Sales.Ref = &Ref
	|	and Sales.Warehouse = Documents.Warehouse
	|	and Sales.Location = Documents.Location
	|	and Sales.Method = Documents.Method
	|where Documents.Date between beginofperiod ( Sales.Date, day ) and endofperiod ( Sales.Date, day )
	|and not Documents.DeletionMark
	|;
	|// #InvoiceRecords
	|select Documents.Ref as Document, Documents.DeliveryDate as Date, Documents.Number as Number
	|from Document.InvoiceRecord as Documents
	|where Documents.Base = &Ref
	|and not Documents.DeletionMark
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setURLPanel ()
	
	meta = Metadata.Documents;
	parts = new Array ();
	if ( BaseExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Base, BaseMetadata ) );
	endif; 
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.RetailSales, meta.RetailSales ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.InvoiceRecords, meta.InvoiceRecord ) );
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
		updateTotals ( ThisObject );
		activateTaken ();
	endif; 
	
EndProcedure

&AtClient
Procedure activateTaken ()
	
	CurrentItem = Items.Taken;

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

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	readNewInvoices ( NewObject );
	setLinks ();
	
EndProcedure

&AtServer
Procedure readNewInvoices ( NewObject ) 

	type = TypeOf ( NewObject );
	if ( type = Type ( "DocumentRef.InvoiceRecord" ) ) then
		InvoiceRecords.Read ( ThisObject );
		Appearance.Apply ( ThisObject, "InvoiceRecord, FormStatus, ChangesDisallowed" );
	endif;

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
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	updateTotals ( ThisObject );

EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( Object.Ref.IsEmpty () ) then
		return;
	endif;
	readPrinted ();
	Appearance.Apply ( ThisObject, "InvoiceRecord" );
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject, "Object.Posted" );	
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	if ( WriteParameters.WriteMode = DocumentWriteMode.Posting ) then
		printBill ();
	endif;
	Notify ( Enum.MessageSaleIsSaved (), Object.Ref );
	
	
EndProcedure

&AtClient
async Procedure printBill ()
	
	if ( not Object.Posted ) then
		return;
	endif;
	folder = Application.ReceipsFolder ();
	if ( folder = "" ) then
		unpost ();
		raise Output.ReceipsFolderIsEmpty ();
	endif;
	text = new TextDocument ();
	data = billData ();
	text.SetText ( data );
	file = folder + GetPathSeparator () + "export" + TrimAll ( Object.Number ) + ".inp";
	try
		await text.WriteAsync ( file );
	except
		// 8.3.20.1674 Bug workaroud: BriefErrorDescription doesn't exists as a method
		// Will use russian method:
		error = ErrorProcessing.КраткоеПредставлениеОшибки ( ErrorInfo () );
		unpost ();
		raise Output.BillPrintingError ( new Structure ( "Error", error ) );
	endtry;

EndProcedure

&AtClient
Procedure unpost ()
	
	Write ( new Structure ( "WriteMode", DocumentWriteMode.UndoPosting ) );

EndProcedure

&AtServer
Function billData ()
	
	data = new Array ();
	data.Add ();
	for each row in Object.Items do
		if ( ServerCache.Pick ( row.VATCode, "Type" ) = Enums.VAT.Standart ) then 
			tax = 1;
		else
			tax = 2;
		endif;
		s = "S,1,______,_,__;"
		+ Left ( StrReplace ( String ( row.Item ), ";", "," ), 22 )
		+";"+ Format ( row.Price, "ND=15; NFD=2; NDS=.; NG=;" )
		+";"+ Format ( row.QuantityPkg, "ND=10; NFD=3; NDS=.; NG=;" )
		+";1;1;"
		+ tax
		+";0;0;";
		data.Add ( s );
	enddo;
	method = Object.Method;
	if ( method = Enums.PaymentMethods.Cash
		or method = Enums.PaymentMethods.Check ) then
		data.Add ( "T,1,______,_,__;;;;;;" );
	else
		data.Add ( "T,1,______,_,__;3;" + Format ( Object.Amount,"ND=15; NFD=2; NDS=.; NG=;" ) + ";;;;" );
	endif;
	return StrConcat ( data, Chars.LF );

EndFunction

// *****************************************
// *********** Group Form

&AtClient
Procedure WarehouseOnChange ( Item )
	
	applyWarehouse ();
	
EndProcedure

&AtServer
Procedure applyWarehouse ()
	
	prices = DF.Pick ( Object.Warehouse, "Prices", Object.Prices );
	if ( prices = Object.Prices ) then
		return;
	endif;
	Object.Prices = prices;
	applyPrices ();

EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure ReturnOnChange ( Item )
	
	revert ( Object );
	Appearance.Apply ( ThisObject, "Object.Return" );
	
EndProcedure
 
&AtClient
Procedure MethodOnChange ( Item )
	
	applyMethod ();

EndProcedure

&AtClient
Procedure applyMethod ()
	
	cash = ( Object.Method = PredefinedValue ( "Enum.PaymentMethods.Cash" ) );
	if ( not cash ) then
		Object.Taken = 0;
		calcChange ( ThisObject );
	endif;
	Appearance.Apply ( ThisObject, "Object.Method" );
	if ( cash ) then
		CurrentItem = Items.Taken;
	endif;

EndProcedure

&AtClient
Procedure AmountClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure TakenOnChange ( Item )
	
	calcChange ( ThisObject );

EndProcedure

&AtClient
Procedure ChangeOnChange ( Item )
	
	calcTaken ();
	activateTaken ();

EndProcedure

&AtClient
Procedure calcTaken ()
	
	Object.Taken = Object.Amount + Change;

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
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsTableBeforeAddRow ( Item, Cancel, Clone, Parent, IsFolder, Parameter )
	
	Cancel = true;
	PickItems.Open ( ThisObject, pickParams () );
	
EndProcedure

&AtServer
Function pickParams ()
	
	return PickItems.GetParams ( ThisObject );
	
EndFunction 

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
