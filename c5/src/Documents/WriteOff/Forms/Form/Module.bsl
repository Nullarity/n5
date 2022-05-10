&AtServer
var Env;
&AtServer
var Base;
&AtServer
var BaseExists;
&AtServer
var BaseMetadata;
&AtClient
var ItemsRow;
&AtServer
var AccountData;
&AtClient
var AccountData;
&AtServer
var VATAccountData;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	InvoiceForm.SetLocalCurrency ( ThisObject );
	InvoiceRecords.Read ( ThisObject );
	readAccount ();
	labelDims ( AccountData );
	if ( Object.VATUse > 0 ) then
		readVATAccount ();
		labelDims ( VATAccountData, "VAT" );
	endif;
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure readAccount ()
	
	AccountData = GeneralAccounts.GetData ( Object.ExpenseAccount );
	ExpensesLevel = AccountData.Fields.Level;
	
EndProcedure 

&AtServer
Procedure labelDims ( Data, Prefix = "" )
	
	i = 1;
	for each dim in Data.Dims do
		Items [ Prefix + "Dim" + i ].Title = dim.Presentation;
		i = i + 1;
	enddo; 
	
EndProcedure 

&AtServer
Procedure readVATAccount ()
	
	VATAccountData = GeneralAccounts.GetData ( Object.VATAccount );
	VATExpensesLevel = VATAccountData.Fields.Level;
	
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
			if ( baseType = Type ( "DocumentRef.Inventory" ) ) then
				fillByInventory ();
			elsif ( baseType = Type ( "DocumentRef.Waybill" ) ) then
				fillByWaybill ();
			elsif ( baseType = Type ( "DocumentRef.ShipmentStockman" ) ) then
				fillByShipmentStockman ();
			endif;
			setCurrency ();
		endif;
		updateChangesPermission ();
	endif; 
	setAccuracy ();
	setLinks ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Rate Factor enable Object.Currency <> LocalCurrency;
	|Links show ShowLinks;
	|FormInvoice show filled ( InvoiceRecord );
	|NewInvoiceRecord show Object.VATUse > 0 and ( FormStatus = Enum.FormStatuses.Canceled or empty ( FormStatus ) );
	|Warning show ChangesDisallowed;
	|Dim1 show ExpensesLevel > 0;
	|Dim2 show ExpensesLevel > 1;
	|Dim3 show ExpensesLevel > 2;
	|VATDim1 show VATExpensesLevel > 0;
	|VATDim2 show VATExpensesLevel > 1;
	|VATDim3 show VATExpensesLevel > 2;
	|ItemsShowDetails press Object.Detail;
	|Prices GrossAmount Amount VATUse show Object.ShowPrices;
	|ItemsExpenseAccount ItemsDim1 ItemsDim2 ItemsDim3 ItemsProduct ItemsProductFeature hide not Object.Detail;
	|ItemsPrice ItemsAmount ItemsPrices show Object.ShowPrices;
	|VAT VATAccount ItemsVATCode ItemsVAT ItemsVATAccount Customer Contract show Object.VATUse > 0;
	|ItemsTotal show Object.VATUse = 2;
	|GroupHeader GroupItems GroupStakeholders GroupFooter GroupMore lock ChangesDisallowed;
	|ItemsTableCommandBar disable ChangesDisallowed;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

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
	Object.Prices = DF.Pick ( Object.Company, "CostPrices" );
	setCurrency ();
	fillStakeholders ();
	
EndProcedure 

&AtServer
Procedure setCurrency ()
	
	Object.Currency = Application.Currency ();
	applyCurrency ();
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	rates = CurrenciesSrv.Get ( object.Currency );
	object.Rate = rates.Rate;
	object.Factor = rates.Factor;
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure 

&AtServer
Procedure fillStakeholders ()
	
	getStakeholders ();
	header = Env.Header;
	if ( header <> undefined ) then
		FillPropertyValues ( Object, header );
	endif; 
	Object.Members.Load ( Env.Members );
	
EndProcedure 

&AtServer
Procedure getStakeholders ()
	
	s = "
	|select allowed top 1 Documents.Ref as Ref
	|into References
	|from Document.WriteOff as Documents
	|where not Documents.DeletionMark
	|and Documents.Date <= &Date
	|and Documents.Ref <> &Ref
	|and Documents.Company = &Company";
	warehouse = Object.Warehouse;
	if ( not warehouse.IsEmpty () ) then
		s = s + "
		|and Documents.Warehouse = &Warehouse";
	endif; 
	s = s + "
	|order by Documents.Date desc
	|;
	|// @Header
	|select Documents.Head as Head, Documents.HeadPosition as HeadPosition,
	|	Documents.Approved as Approved, Documents.ApprovedPosition as ApprovedPosition
	|from Document.WriteOff as Documents
	|where Documents.Ref in ( select Ref from References )
	|;
	|// #Members
	|select Members.Member as Member, Members.Position as Position
	|from Document.WriteOff.Members as Members
	|where Members.Ref in ( select Ref from References )
	|order by Members.LineNumber
	|";
	Env = SQL.Create ( s );
	q = Env.Q;
	q.SetParameter ( "Date", Periods.GetDocumentDate ( Object ) );
	q.SetParameter ( "Ref", Object.Ref );
	q.SetParameter ( "Company", Object.Company );
	q.SetParameter ( "Warehouse", warehouse );
	SQL.Perform ( Env );

EndProcedure

&AtServer
Procedure fillByInventory ()
	
	setEnv ();
	sqlInventory ();
	SQL.Perform ( Env );
	headerByInventory ();
	itemsByInventory ();
	
EndProcedure

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	
EndProcedure

&AtServer
Procedure sqlInventory ()
	
	s = "
	|// @Fields
	|select Document.Company as Company, Document.Warehouse as Warehouse
	|from Document.Inventory as Document
	|where Document.Ref = &Base
	|;
	|// #Items
	|select Items.Item as Item, Items.Feature as Feature, Items.Capacity as Capacity, Items.Series as Series,
	|	 Items.Package as Package, Items.Account as Account, ( - Items.QuantityDifference ) as Quantity, 
	|	( - Items.QuantityPkgDifference ) as QuantityPkg 
	|from Document.Inventory.Items as Items
	|where Items.Ref = &Base and Items.QuantityDifference < 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByInventory ()
	
	FillPropertyValues ( Object, Env.Fields );
	Object.Base = Base;
	
EndProcedure 

&AtServer
Procedure itemsByInventory ()
	
	if ( Env.Items.Count () = 0 ) then
		raise Output.FillingDataNotFoundError ();
	endif;
	Object.Items.Load ( Env.Items );
	
EndProcedure

&AtServer
Procedure fillByWaybill ()
	
	setEnv ();
	sqlFields ();
	getFields ();
	sqlWaybill ();
	getTables ();
	headerByWaybill ();
	itemsByWaybill ();
	
EndProcedure

&AtServer
Procedure sqlFields ()
	
	s = "
	|// @Fields
	|select Document.Company as Company, Document.Car as Car,
	|	Document.Car.Warehouse as Warehouse, dateadd ( Document.Date, second, 1 ) as InventoryDate
	|from Document.Waybill as Document
	|where Document.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure getFields ()
	
	SQL.Perform ( Env );
	
EndProcedure

&AtServer
Procedure sqlWaybill ()
	
	s = "
	|// #Items
	|select Items.Fuel as Item, Items.QuantityBalance as Quantity, 
	|	Items.Fuel.Package as Package, isnull ( Items.Fuel.Package.Capacity, 1 ) as Capacity
	|from AccumulationRegister.FuelToExpense.Balance(&InventoryDate, Car = &Car) as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure getTables ()
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "InventoryDate", fields.InventoryDate );
	q.SetParameter ( "Car", fields.Car );
	SQL.Perform ( Env );	
	
EndProcedure

&AtServer
Procedure headerByWaybill ()
	
	FillPropertyValues ( Object, Env.Fields );
	Object.Base = Base;
	Object.Currency = Application.Currency ();
	
EndProcedure 

&AtServer
Procedure itemsByWaybill ()
	
	if ( Env.Items.Count () = 0 ) then
		raise Output.FillingDataNotFoundError ();
	endif;
	company = Object.Company;
	warehouse = Object.Warehouse;
	table = Object.Items;
	for each row in Env.Items do
		newRow = table.Add ();
		FillPropertyValues ( newRow, row );
		accounts = AccountsMap.Item ( newRow.Item, company, warehouse, "Account, VAT" );
		newRow.Account = accounts.Account;
		newRow.VATAccount = accounts.VAT;
		Computations.Packages ( newRow );
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
	|select Documents.Company as Company, Documents.Warehouse as Warehouse, Documents.Invoiced as Invoiced
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
	Object.Base = Base;
	Object.Currency = Application.Currency ();
	
EndProcedure 

&AtServer
Procedure loadShipmentStockman ()
	
	company = Object.Company;
	warehouse = Object.Warehouse;
	itemsTable = Object.Items;
	for each row in Env.Items do
		newRow = itemsTable.Add ();
		FillPropertyValues ( newRow, row );
		accounts = AccountsMap.Item ( row.Item, company, warehouse, "Account, VAT" );
		newRow.Account = accounts.Account;
		newRow.VATAccount = accounts.VAT;
	enddo; 

EndProcedure

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
		q.SetParameter ( "Ref", Object.Ref );
		q.SetParameter ( "Base", Object.Base );
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
	s = "
	|// #InvoiceRecords
	|select Documents.Ref as Document, Documents.DeliveryDate as Date, Documents.Number as Number
	|from Document.InvoiceRecord as Documents
	|where Documents.Base = &Ref
	|and not Documents.DeletionMark
	|";
	selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	if ( BaseExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Base, BaseMetadata ) );
	endif;
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.InvoiceRecords, Metadata.Documents.InvoiceRecord ) );
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

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	if ( SelectedValue.Operation = Enum.ChoiceOperationsPickItems () ) then
		addSelectedItems ( SelectedValue );
		calcTotals ( Object );
	endif; 
	
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
	elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	elsif ( EventName = Enum.InvoiceRecordsWrite ()
		and Source.Ref = InvoiceRecord ) then
		readPrinted ();
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
		row.Series = Fields.Series;
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
	if ( isNew () ) then
		return;
	endif;
	readPrinted ();
	Appearance.Apply ( ThisObject, "InvoiceRecord" );
	
EndProcedure

&AtServer
Procedure completeShipment ()
	
	shipment = Object.Base;
	if ( TypeOf ( shipment ) = Type ( "DocumentRef.ShipmentStockman" ) ) then
		Documents.ShipmentStockman.Complete ( shipment );
	endif;

EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageWriteOffIsSaved (), Object.Ref );
	
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

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure CustomerOnChange ( Item )
	
	applyCustomer ();

EndProcedure

&AtClient
Procedure applyCustomer ()
	
	customer = Object.Customer;
	if ( customer.IsEmpty () ) then
		return;
	endif;
	Object.Contract = DF.Pick ( customer, "CustomerContract" );

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
	
	return ? ( TableRow.Warehouse.IsEmpty (), Object.Warehouse, TableRow.Warehouse );
	
EndFunction 

&AtClient
Procedure ExpenseAccountOnChange ( Item )
	
	applyExpenseAccount ();
	
EndProcedure

&AtServer
Procedure applyExpenseAccount ()
	
	readAccount ();
	adjustDims ( AccountData, Object );
	labelDims ( AccountData );
	Appearance.Apply ( ThisObject, "ExpensesLevel" );
	      	
EndProcedure 

&AtClientAtServerNoContext
Procedure adjustDims ( Data, Target, Prefix = "" )
	
	dims = Data.Dims;
	top = Data.Fields.Level;
	dimName = Prefix + "Dim";
	for i = 1 to 3 do
		name = dimName + i;
		Target [ name ] = ? ( i > top, null, dims [ i - 1 ].ValueType.AdjustValue ( Target [ name ] ) );
	enddo;

EndProcedure 

&AtClient
Procedure VATAccountOnChange ( Item )
	
	applyVATAccount ();

EndProcedure

&AtServer
Procedure applyVATAccount ()
	
	readVATAccount ();
	adjustDims ( VATAccountData, Object, "VAT" );
	labelDims ( VATAccountData, "VAT" );
	Appearance.Apply ( ThisObject, "VATExpensesLevel" );
	      	
EndProcedure 

&AtClient
Procedure ShowPricesOnChange ( Item )
	
	applyShowPrices ();
	
EndProcedure

&AtServer
Procedure applyShowPrices ()
	
	if ( Object.ShowPrices ) then
		Object.VATUse = Metadata.Documents.WriteOff.Attributes.ShowPrices.FillValue;
	else
		Object.VATUse = 0;
		resetVATUse ();
	endif;
	Appearance.Apply ( ThisObject, "Object.ShowPrices, Object.VATUse" );

EndProcedure

&AtServer
Procedure resetVATUse ()
	
	Object.Customer = undefined;
	Object.Contract = undefined;
	Object.VATAccount = undefined;
	applyVATAccount ();

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
	if ( vatUse = 0 ) then
		resetVATUse ();
	endif;
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
Procedure ShowDetails ( Command )
	
	if ( Object.Detail
		and detailsExist () ) then
		Output.RemoveDetails ( ThisObject );
	else
		switchDetail ();
	endif; 
	
EndProcedure

&AtClient
Procedure switchDetail ()
	
	Object.Detail = not Object.Detail;
	Appearance.Apply ( ThisObject, "Object.Detail" );
	
EndProcedure 

&AtClient
Function detailsExist ()
	
	for each row in Object.Items do
		if ( not row.ExpenseAccount.IsEmpty () ) then
			return true;
		endif; 
	enddo; 
	return false;
	
EndFunction 

&AtClient
Procedure RemoveDetails ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	clearDetails ();
	switchDetail ();
	
EndProcedure 

&AtClient
Procedure clearDetails ()
	
	for each row in Object.Items do
		row.ExpenseAccount = undefined;
		row.Dim1 = undefined;
		row.Dim2 = undefined;
		row.Dim3 = undefined;
		row.Product = undefined;
		row.ProductFeature = undefined;
	enddo; 
	
EndProcedure 

&AtClient
Procedure ItemsBeforeRowChange ( Item, Cancel )
	
	readTableAccount ();
	enableDims ();
	
EndProcedure

&AtClient
Procedure readTableAccount ()
	
	AccountData = GeneralAccounts.GetData ( ItemsRow.ExpenseAccount );
	
EndProcedure 

&AtClient
Procedure enableDims ()
	
	fields = AccountData.Fields;
	level = fields.Level;
	for i = 1 to 3 do
		disable = ( level < i );
		Items [ "ItemsDim" + i ].ReadOnly = disable;
	enddo; 
	
EndProcedure 

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	resetAnalytics ();
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure resetAnalytics ()
	
	Items.ItemsDim1.ReadOnly = false;
	Items.ItemsDim2.ReadOnly = false;
	Items.ItemsDim3.ReadOnly = false;
	
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
	ItemsRow.VATAccount = data.VATAccount;
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
Procedure ItemsExpenseAccountOnChange ( Item )
	
	readTableAccount ();
	adjustDims ( AccountData, ItemsRow );
	enableDims ();
	
EndProcedure

&AtClient
Procedure ItemsDim1StartChoice ( Item, ChoiceData, StandardProcessing )
	
	chooseDim ( Item, 1, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ItemsDim2StartChoice ( Item, ChoiceData, StandardProcessing )
	
	chooseDim ( Item, 2, StandardProcessing );
	
EndProcedure

&AtClient
Procedure ItemsDim3StartChoice ( Item, ChoiceData, StandardProcessing )
	
	chooseDim ( Item, 3, StandardProcessing );
	
EndProcedure

&AtClient
Procedure chooseDim ( Item, Level, StandardProcessing )
	
	p = Dimensions.GetParams ();
	p.Company = Object.Company;
	p.Level = Level;
	p.Dim1 = ItemsRow.Dim1;
	p.Dim2 = ItemsRow.Dim2;
	p.Dim3 = ItemsRow.Dim3;
	Dimensions.Choose ( p, Item, StandardProcessing );
	
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

// *****************************************
// *********** Group Stakeholders

&AtClient
Procedure ApprovedOnChange ( Item )
	
	MembersForm.SetPosition ( Object.Approved, Object.ApprovedPosition, Object.Date );
	
EndProcedure

&AtClient
Procedure HeadOnChange ( Item )
	
	MembersForm.SetPosition ( Object.Head, Object.HeadPosition, Object.Date );
	
EndProcedure

&AtClient
Procedure MembersMemberOnChange ( Item )
	
	MembersForm.FillPosition ( Items.Members.CurrentData, Object.Date );
	
EndProcedure
