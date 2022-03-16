&AtServer
var Env;
&AtServer
var PurchaseOrderExists;
&AtServer
var ReceiptExists;
&AtServer
var Base;
&AtServer
var BaseType;
&AtServer
var Copy;
&AtClient
var ItemsRow;
&AtClient
var ServicesRow;
&AtClient
var AccountsRow;
&AtClient
var AccountData;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	updateBalanceDue ();
	readItemsPurchase ();
	readServicesPurchase ();
	changeAvailability ();
	initCurrency ();
	setSocial ();
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateBalanceDue ()

	InvoiceForm.SetPaymentsApplied ( ThisObject );
	InvoiceForm.CalcBalanceDue ( ThisObject );
	Appearance.Apply ( ThisObject, "BalanceDue" );

EndProcedure

&AtServer
Procedure readItemsPurchase ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	sqlItemsPurchase ();
	Env.Q.SetParameter ( "Ref", Object.Ref );
	SQL.Perform ( Env );
	fillItemsPurchase ( Env.Fields );
	
EndProcedure

&AtServer 
Procedure sqlItemsPurchase ()
	
	s = "
	|// @Fields
	|select top 1 ItemsPurchases.Ref as Ref, ItemsPurchases.Status as Status
	|from Document.ItemsPurchase as ItemsPurchases
	|where ItemsPurchases.Base = &Ref
	|and not ItemsPurchases.DeletionMark
	|order by ItemsPurchases.Date desc
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure fillItemsPurchase ( Fields )

	if ( Fields = undefined ) then
		ItemsPurchase = undefined;
		ItemsPurchaseStatus = undefined;
	else
		ItemsPurchase = Fields.Ref;
		ItemsPurchaseStatus = Fields.Status;
	endif;

EndProcedure

&AtServer
Procedure readServicesPurchase ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	sqlServicesPurchase ();
	Env.Q.SetParameter ( "Ref", Object.Ref );
	SQL.Perform ( Env );
	fillServicesPurchase ( Env.Fields );
	
EndProcedure

&AtServer 
Procedure sqlServicesPurchase ()
	
	s = "
	|// @Fields
	|select top 1 ServicesPurchases.Ref as Ref, ServicesPurchases.Status as Status
	|from Document.ServicesPurchase as ServicesPurchases
	|where ServicesPurchases.Base = &Ref
	|and not ServicesPurchases.DeletionMark
	|order by ServicesPurchases.Date desc
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure fillServicesPurchase ( Fields )

	if ( Fields = undefined ) then
		ServicesPurchase = undefined;
		ServicesPurchaseStatus = undefined;
	else
		ServicesPurchase = Fields.Ref;
		ServicesPurchaseStatus = Fields.Status;
	endif;

EndProcedure

&AtServer
Procedure changeAvailability ()
	
	ChangesDisallowed = not IsInRole ( Metadata.Roles.ModifyIssuedInvoices )
	and (
	ItemsPurchaseStatus = Enums.FormStatuses.Waiting
	or ItemsPurchaseStatus = Enums.FormStatuses.Unloaded
	or ItemsPurchaseStatus = Enums.FormStatuses.Printed
	or ItemsPurchaseStatus = Enums.FormStatuses.Submitted
	or ItemsPurchaseStatus = Enums.FormStatuses.Returned
	or ServicesPurchaseStatus = Enums.FormStatuses.Waiting
	or ServicesPurchaseStatus = Enums.FormStatuses.Unloaded
	or ServicesPurchaseStatus = Enums.FormStatuses.Printed
	or ServicesPurchaseStatus = Enums.FormStatuses.Submitted
	or ServicesPurchaseStatus = Enums.FormStatuses.Returned
	);

EndProcedure

&AtServer
Procedure initCurrency ()
	
	InvoiceForm.SetLocalCurrency ( ThisObject );
	InvoiceForm.SetContractCurrency ( ThisObject );
	InvoiceForm.SetCurrencyList ( ThisObject );
	
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

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	if ( isNew () ) then
		DocumentForm.Init ( Object );
		Base = Parameters.Basis;
		initCurrency ();
		if ( Base = undefined ) then
			Copy = not Parameters.CopyingValue.IsEmpty ();
			fillNew ();
			fillByVendor ();
		else
			BaseType = TypeOf ( Base );
			if ( BaseType = Type ( "DocumentRef.PurchaseOrder" ) ) then
				fillByPurchaseOrder ();
			elsif ( BaseType = Type ( "DocumentRef.InternalOrder" )
				or BaseType = Type ( "DocumentRef.SalesOrder" ) ) then
				fillByOrder ();
			elsif ( BaseType = Type ( "DocumentRef.ReceiptStockman" ) ) then
				fillByReceiptStockman ();
			endif; 
		endif;
		updateBalanceDue ();
		Constraints.ShowAccess ( ThisObject );
	endif;
	setLinks ();
	setAccuracy ();
	setSocial ();
	Forms.ActivatePage ( ThisObject, "ItemsTable,Services,FixedAssets,IntangibleAssets,Accounts,Discounts" );
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	Mobile = Environment.MobileClient ();
	
EndProcedure 

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ContractAmount show filled ( ContractCurrency ) and ContractCurrency <> Object.Currency;
	|ContractAmount title/Form.ContractCurrency ContractCurrency <> Object.Currency;
	|Rate Factor enable
	|filled ( LocalCurrency )
	|and filled ( ContractCurrency )
	|and ( Object.Currency <> LocalCurrency or ContractCurrency <> LocalCurrency );
	|ItemsApplyPurchaseOrders ItemsTableApplyInternalOrders ItemsTableApplySalesOrders ServicesApplyPurchaseOrders ServicesApplyInternalOrders ServicesApplySalesOrders show empty ( Object.PurchaseOrder );
	|Company Vendor Contract Currency lock filled ( Object.PurchaseOrder );
	|Links show ShowLinks;
	|CreatePayment show BalanceDue <> 0;
	|#s DiscountsPage hide Mobile and Form.Object.Discounts.Count () = 0;
	|VAT ItemsVATAccount ServicesVATAccount FixedAssetsVATAccount IntangibleAssetsVATAccount AccountsVATAccount
	|	ItemsVATCode ItemsVAT ServicesVATCode ServicesVAT  FixedAssetsVATCode FixedAssetsVAT IntangibleAssetsVATCode
	|	IntangibleAssetsVAT AccountsVATCode AccountsVAT show Object.VATUse > 0;
	|ServicesTotal ItemsTotal FixedAssetsTotal IntangibleAssetsTotal AccountsTotal show Object.VATUse = 2;
	|ItemsProducerPrice show UseSocial;
	|FormDocumentItemsPurchaseCreateBasedOn show ItemsPurchaseStatus = Enum.FormStatuses.Canceled or empty ( ItemsPurchaseStatus );
	|FormDocumentServicesPurchaseCreateBasedOn show ServicesPurchaseStatus = Enum.FormStatuses.Canceled or empty ( ServicesPurchaseStatus );
	|FormItemsPurchase show filled ( ItemsPurchase );
	|FormServicesPurchase show filled ( ServicesPurchase );
	|Warning show ChangesDisallowed;
	|Header GroupItems GroupServices GroupFixedAssets GroupIntangibleAssets GroupAccounts GroupDiscounts GroupAdditional Footer lock ChangesDisallowed; 
	|ItemsTableCommandBar ServicesCommandBar FixedAssetsCommandBar IntangibleItemsCommandBar AccountsCommandBar DiscountsCommandBar
	|	disable ChangesDisallowed;
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
	Object.Currency = Application.Currency ();
	setReferenceDate ( Object )
	
EndProcedure

&AtClientAtServerNoContext
Procedure setReferenceDate ( Object ) 

	Object.ReferenceDate = Object.Date;

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
	
	data = AccountsMap.Organization ( Object.Vendor, Object.Company, "VendorAccount" );
	Object.VendorAccount = data.VendorAccount;
	data = DF.Values ( Object.Vendor, "VendorContract, VendorContract.Company as Company, VATUse" );
	if ( data.Company = Object.Company ) then
		Object.Contract = data.VendorContract;
	endif; 
	Object.VATUse = data.VATUse;
	applyContract ();
	applyVATUse ();
	
EndProcedure

&AtServer
Procedure applyContract ()
	
	data = DF.Values ( Object.Contract,
		"VendorPrices, Currency, Import, VendorAdvances, VendorRateType, VendorRate, VendorFactor" );
	ContractCurrency = data.Currency;
	if ( data.VendorRateType = Enums.CurrencyRates.Fixed
		and data.VendorRate <> 0 ) then
		currency = new Structure ( "Rate, Factor", data.VendorRate, data.VendorFactor );
	else
		currency = CurrenciesSrv.Get ( data.Currency, Object.Date );
	endif;
	Object.CloseAdvances = data.VendorAdvances;
	Object.Rate = currency.Rate;
	Object.Factor = currency.Factor;
	Object.Currency = ContractCurrency;
	Object.Prices = data.VendorPrices;
	Object.Import = data.Import;
	InvoiceForm.SetCurrencyList ( ThisObject );
	updateContent ();
	updateTotals ( ThisObject );
	updateBalanceDue ();
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure

&AtServer
Procedure updateContent ()
	
	if ( Object.Receipt.IsEmpty () ) then
		reloadTables ();
		DiscountsTable.Load ( Object );
	endif;
	InvoiceForm.SetPayment ( Object );
	updateChangesPermission ();
	
EndProcedure 

&AtServer
Procedure reloadTables ()
	
	table = FillerSrv.GetData ( fillingParams ( "PurchaseOrderItems", Object.PurchaseOrder ) );
	if ( table.Count () > 0 ) then
		Object.Items.Clear ();
		Object.Services.Clear ();
		loadPurchaseOrders ( table );
	endif; 
	
EndProcedure 

&AtServer
Procedure loadPurchaseOrders ( Table )
	
	company = Object.Company;
	warehouses = Options.WarehousesInTable ( company );
	orders = Options.PurchaseOrdersInTable ( company );
	warehouse = Object.Warehouse;
	purchaseOrder = Object.PurchaseOrder;
	vatUse = Object.VATUse;
	services = Object.Services;
	itemsTable = Object.Items;
	for each row in Table do
		if ( row.ItemService ) then
			docRow = services.Add ();
			FillPropertyValues ( docRow, row );
			item = row.Item;
			if ( docRow.Quantity = 0 ) then
				docRow.Price = docRow.Amount;
			endif; 
			accounts = AccountsMap.Item ( item, company, warehouse, "VAT" );
			docRow.VATAccount = accounts.VAT;
		else
			docRow = itemsTable.Add ();
			FillPropertyValues ( docRow, row );
			if ( warehouses
				and docRow.Warehouse = warehouse ) then
				docRow.Warehouse = undefined;
			endif; 
			accounts = AccountsMap.Item ( docRow.Item, company, warehouse, "Account, VAT" );
			docRow.Account = accounts.Account;
			docRow.VATAccount = accounts.VAT;
		endif; 
		if ( orders
			and docRow.PurchaseOrder = purchaseOrder ) then
			docRow.PurchaseOrder = undefined;
		endif; 
		Computations.Amount ( docRow );
		Computations.Total ( docRow, vatUse );
	enddo; 
	
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
	for each row in Object.FixedAssets do
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.IntangibleAssets do
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.Accounts do
		Computations.Total ( row, vatUse );
	enddo;
	DiscountsTable.RecalcVAT ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
EndProcedure

#region Filling

&AtServer
Procedure fillByPurchaseOrder ()
	
	setEnv ();
	sqlPurchaseOrder ();
	SQL.Perform ( Env );
	headerByPurchaseOrder ();
	table = FillerSrv.GetData ( fillingParams ( "PurchaseOrderItems", Object.PurchaseOrder ) );
	loadPurchaseOrders ( table );
	DiscountsTable.Load ( Object );
	updateTotals ( ThisObject );
	InvoiceForm.SetPayment ( Object );
	
EndProcedure 

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	
EndProcedure

&AtServer
Procedure sqlPurchaseOrder ()
	
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.Contract as Contract,
	|	Documents.Contract.Currency as ContractCurrency, Documents.Contract.VendorRateType as RateType,
	|	Documents.Rate as Rate, Documents.Factor as Factor, Documents.Currency as Currency,
	|	Documents.Vendor as Vendor, Documents.Prices as Prices, Documents.VATUse as VATUse,
	|	Documents.Warehouse as Warehouse, Documents.Department as Department,
	|	Documents.Contract.Import as Import, Documents.Contract.VendorAdvances as CloseAdvances
	|from Document.PurchaseOrder as Documents
	|where Documents.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByPurchaseOrder ()
	
	fields = Env.Fields;
	FillPropertyValues ( Object, fields );
	Object.PurchaseOrder = Base;
	ContractCurrency = fields.ContractCurrency;
	if ( fields.RateType = Enums.CurrencyRates.Current ) then
		currency = CurrenciesSrv.Get ( Object.Currency, Object.Date );
		Object.Rate = currency.Rate;
		Object.Factor = currency.Factor;
	endif;
	data = AccountsMap.Organization ( Object.Vendor, Object.Company, "VendorAccount" );
	Object.VendorAccount = data.VendorAccount;
	InvoiceForm.SetCurrencyList ( ThisObject );
	
EndProcedure 

&AtServer
Function fillingParams ( val Report, val BaseDocument )
	
	p = Filler.GetParams ();
	p.ProposeClearing = Object.PurchaseOrder.IsEmpty ();
	p.Report = Report;
	if ( Report = Metadata.Reports.SalesOrderItems.Name ) then
		p.Variant = "#FillVendorInvoice";
	endif; 
	p.Filters = getFilters ( Report, BaseDocument );
	return p;
	
EndFunction

&AtServer
Function getFilters ( Report, BaseDocument )
	
	meta = Metadata.Reports;
	vendor = Object.Vendor;
	warehouse = Object.Warehouse;
	filters = new Array ();
	if ( Report = meta.PurchaseOrderItems.Name ) then
		if ( BaseDocument.IsEmpty () ) then
			filters.Add ( DC.CreateFilter ( "PurchaseOrder.Vendor", vendor ) );
			filters.Add ( DC.CreateFilter ( "PurchaseOrder.Contract", Object.Contract ) );
			if ( not warehouse.IsEmpty () ) then
				filters.Add ( DC.CreateFilter ( "PurchaseOrder.Warehouse", warehouse ) );
			endif; 
		else
			filters.Add ( DC.CreateFilter ( "PurchaseOrder", BaseDocument ) );
		endif; 
	else
		if ( BaseDocument = undefined ) then
			filters.Add ( DC.CreateParameter ( "Vendor", vendor ) );
			if ( not warehouse.IsEmpty () ) then
				filters.Add ( DC.CreateFilter ( "Warehouse", warehouse ) );
			endif; 
		else
			if ( Report = meta.InternalOrders.Name ) then
				filters.Add ( DC.CreateFilter ( "InternalOrder", BaseDocument ) );
			else
				filters.Add ( DC.CreateFilter ( "SalesOrder", BaseDocument ) );
			endif;
		endif;
	endif; 
	item = DC.CreateParameter ( "ReportDate" );
	item.Value = Catalogs.Calendar.GetDate ( Periods.GetBalanceDate ( Object ) );
	item.Use = not item.Value.IsEmpty ();
	filters.Add ( item );
	return filters;
	
EndFunction

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
	updateTotals ( ThisObject );
	
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
	|select Documents.Company as Company, Documents.Currency as Currency, Documents.Prices as Prices, Documents.Warehouse as Warehouse,
	|	Documents.VATUse as VATUse
	|from Document." + name + " as Documents
	|where Documents.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByOrder ()
	
	FillPropertyValues ( Object, Env.Fields );
	currency = CurrenciesSrv.Get ( Object.Currency, Object.Date );
	Object.Rate = currency.Rate;
	Object.Factor = currency.Factor;
	InvoiceForm.SetCurrencyList ( ThisObject );
	
EndProcedure 

&AtServer
Procedure loadInternalOrders ( Table )
	
	company = Object.Company;
	warehouses = Options.WarehousesInTable ( company );
	warehouse = Object.Warehouse;
	vatUse = Object.VATUse;
	services = Object.Services;
	itemsTable = Object.Items;
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
			docRow = itemsTable.Add ();
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
	itemsTable = Object.Items;
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
			docRow = itemsTable.Add ();
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

&AtClientAtServerNoContext
Procedure updateTotals ( Form, Row = undefined, CalcVAT = true )
	
	object = Form.Object;
	if ( Row <> undefined ) then
		Computations.Total ( Row, object.VATUse, CalcVAT );
	endif;
	InvoiceForm.CalcTotals ( Form );
	InvoiceForm.CalcBalanceDue ( Form );
	Appearance.Apply ( Form, "BalanceDue" );
	
EndProcedure

&AtServer
Procedure fillByReceiptStockman ()
	
	setEnv ();
	sqlReceiptStockman ();
	SQL.Perform ( Env );
	headerByReceiptStockman ();
	loadReceiptStockman ();
	
EndProcedure

&AtServer
Procedure sqlReceiptStockman ()
	
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.Warehouse as Warehouse, Documents.Organization as Vendor,
	|	Documents.Invoiced as Invoiced
	|from Document.ReceiptStockman as Documents
	|where Documents.Ref = &Base
	|;
	|// #Items
	|select Items.Item as Item, Items.Feature as Feature, Items.Series as Series, Items.Package as Package,
	|	Items.Capacity as Capacity, Items.Quantity as Quantity, Items.QuantityPkg as QuantityPkg,
	|	Items.Item.Social as Social, Items.Item.VAT as VATCode, Items.Item.VAT.Rate as VATRate
	|from Document.ReceiptStockman.Items as Items
	|where Items.Ref = &Base
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerByReceiptStockman ()
	
	fields = Env.Fields;
	if ( fields.Invoiced ) then
		raise Output.DocumentAlreadyInvoiced ( new Structure ( "Document", Base ) );
	endif;
	FillPropertyValues ( Object, fields );
	Object.Receipt = Base;
	Object.Vendor = fields.Vendor;
	applyVendor ();
	
EndProcedure 

&AtServer
Procedure loadReceiptStockman ()
	
	cache = new Map ();
	company = Object.Company;
	warehouse = Object.Warehouse;
	vatUse = Object.VATUse;
	date = Object.Date;
	prices = Object.Prices;
	vendor = Object.Vendor;
	contract = Object.Contract;
	currency = Object.Currency;
	itemsTable = Object.Items;
	for each row in Env.Items do
		docRow = itemsTable.Add ();
		FillPropertyValues ( docRow, row );
		item = docRow.Item;
		accounts = AccountsMap.Item ( item, company, warehouse, "Account, VAT" );
		docRow.Account = accounts.Account;
		docRow.VATAccount = accounts.VAT;
		docRow.Price = Goods.Price ( cache, date, prices, item, docRow.Package, docRow.Feature,
			vendor, contract, true, warehouse, currency );
		Computations.Amount ( docRow );
		Computations.Total ( docRow, vatUse );
	enddo; 

EndProcedure

#endregion

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Ref", Object.Ref );
		q.SetParameter ( "PurchaseOrder", Object.PurchaseOrder );
		q.SetParameter ( "Receipt", Object.Receipt );
		q.SetParameter ( "Contract", Object.Contract );
		SQL.Perform ( env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	PurchaseOrderExists = not Object.PurchaseOrder.IsEmpty ();
	ReceiptExists = not Object.Receipt.IsEmpty ();
	selection = Env.Selection;
	if ( PurchaseOrderExists ) then
		s = "
		|// #PurchaseOrders
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.PurchaseOrder as Documents
		|where Documents.Ref = &PurchaseOrder
		|";
		selection.Add ( s );
	endif;
	if ( ReceiptExists ) then
		s = "
		|// #Receipts
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.ReceiptStockman as Documents
		|where Documents.Ref = &Receipt
		|";
		selection.Add ( s );
	endif;
	if ( isNew () ) then
		return;
	endif; 
	s = "
	|// #Commissionings
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.Commissioning as Documents
	|where Documents.Base = &Ref
	|and not Documents.DeletionMark
	|;
	|// #IntangibleAssetsCommissionings
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.IntangibleAssetsCommissioning as Documents
	|where Documents.Base = &Ref
	|and not Documents.DeletionMark
	|;
	|// #Payments
	|select Documents.Ref as Document,
	|	case when Documents.ReferenceDate = datetime ( 1, 1, 1 ) then Documents.Date else Documents.ReferenceDate end as Date,
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
	|;
	|// #CustomsDeclarations
	|select distinct Documents.Ref as Document, Documents.Ref.Date as Date, Documents.Ref.Number as Number
	|from Document.CustomsDeclaration.Items as Documents
	|where Documents.Invoice = &Ref
	|;
	|// #ItemsPurchases
	|select Documents.Ref as Document, Documents.Ref.Date as Date, Documents.Ref.Number as Number
	|from Document.ItemsPurchase as Documents
	|where Documents.Base = &Ref
	|and not Documents.DeletionMark
	|;
	|// #ServicesPurchases
	|select Documents.Ref as Document, Documents.Ref.Date as Date, Documents.Ref.Number as Number
	|from Document.ServicesPurchase as Documents
	|where Documents.Base = &Ref
	|and not Documents.DeletionMark
	|;
	|// #VendorReturns
	|select distinct Documents.Document as Document, Documents.Date as Date, Documents.Number as Number
	|from (
	|	select Items.Ref as Document, Items.Ref.Date as Date, Items.Ref.Number as Number
	|	from Document.VendorReturn.Items as Items
	|	where Items.VendorInvoice = &Ref
	|	and not Items.Ref.DeletionMark
	|	union all
	|	select Items.Ref, Items.Ref.Date, Items.Ref.Number
	|	from Document.VendorReturn.FixedAssets as Items
	|	where Items.VendorInvoice = &Ref
	|	and not Items.Ref.DeletionMark
	|	union all
	|	select Items.Ref, Items.Ref.Date, Items.Ref.Number
	|	from Document.VendorReturn.IntangibleAssets as Items
	|	where Items.VendorInvoice = &Ref
	|	and not Items.Ref.DeletionMark
	|	union all
	|	select Items.Ref, Items.Ref.Date, Items.Ref.Number
	|	from Document.VendorReturn.Accounts as Items
	|	where Items.VendorInvoice = &Ref
	|	and not Items.Ref.DeletionMark
	|	) as Documents
	|;
	|// #Services
	|select distinct Services.Ref as Document, Services.Ref.Date as Date, Services.Ref.Number as Number
	|from Document.VendorInvoice.Services as Services
	|where Services.IntoDocument = &Ref
	|and not Services.Ref.DeletionMark
	|";
	selection.Add ( s );
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( PurchaseOrderExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.PurchaseOrders, meta.PurchaseOrder ) );
	endif;
	if ( ReceiptExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Receipts, meta.ReceiptStockman ) );
	endif;
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Commissionings, meta.Commissioning ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.IntangibleAssetsCommissionings, meta.IntangibleAssetsCommissioning ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.Payments, meta.VendorPayment ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.CustomsDeclarations, meta.CustomsDeclaration ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.ItemsPurchases, meta.ItemsPurchase ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.ServicesPurchases, meta.ServicesPurchase ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.VendorReturns, meta.VendorReturn ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.Services, meta.VendorInvoice ) );
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
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, ServicesQuantity, AccountsQuantity" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
	
EndProcedure 

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	type = TypeOf ( NewObject );
	alreadyProcessed = type = Type ( "DocumentRef.VendorPayment" );
	if ( alreadyProcessed ) then
		return;
	elsif ( type = Type ( "DocumentRef.ItemsPurchase" ) ) then
		applyItemsPurchase ();
	elsif ( type = Type ( "DocumentRef.ServicesPurchase" ) ) then
		applyServicesPurchase ();
	endif;
	updateLinks ();
	
EndProcedure

&AtServer
Procedure applyItemsPurchase ()

	readItemsPurchase ();
	changeAvailability ();
	Appearance.Apply ( ThisObject, "ItemsPurchase, ItemsPurchaseStatus, ChangesDisallowed" );

EndProcedure

&AtServer
Procedure applyServicesPurchase ()

	readServicesPurchase ();	
	changeAvailability ();
	Appearance.Apply ( ThisObject, "ServicesPurchase, ServicesPurchaseStatus, ChangesDisallowed" );
	
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
	Forms.DeleteLastRow ( Object.FixedAssets, "Item" );
	Forms.DeleteLastRow ( Object.IntangibleAssets, "Item" );
	Forms.DeleteLastRow ( Object.Accounts, "Account" );
	updateTotals ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )

	Documents.ReceiptStockman.Complete ( Object.Receipt );

EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
		applySocial ();
	elsif ( EventName = Enum.MessageServicesPurchaseIsSaved () ) then
		applyServicesPurchase ();
	elsif ( EventName = Enum.MessageItemsPurchaseIsSaved () ) then
		applyItemsPurchase ();
	elsif ( EventName = Enum.MessageVendorPaymentIsSaved ()
		and Parameter.Contract = Object.Contract ) then
		updateLinks ();
		NotifyChanged ( Object.Ref );
	elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
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
		row.Price = Goods.Price ( , Object.Date, Object.Prices, item, package, feature, Object.Vendor, Object.Contract, true, warehouse, Object.Currency );
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
	updateTotals ( ThisObject, Row );
	
EndProcedure 

&AtClient
Procedure applySocial () 
	
	UseSocial = findSocial ( Object.Items );
	Appearance.Apply ( ThisObject, "UseSocial" );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

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
		updateTotals ( ThisObject );
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
		updateTotals ( ThisObject );
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
Procedure addSelectedServices ( Params )
	
	services = Object.Services;
	for each selectedRow in Params.Services do
		row = services.Add ();
		FillPropertyValues ( row, selectedRow );
	enddo; 
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	updateBalanceDue ();	
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageVendorInvoiceIsSaved (), Object.Ref );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )
	
	updateContent ();
	setReferenceDate ( Object );
	
EndProcedure

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure VendorOnChange ( Item )
	
	applyVendor ();

EndProcedure

&AtClient
Procedure ContractOnChange ( Item )
	
	applyContract ();

EndProcedure

&AtClient
Procedure ReferenceOnChange ( Item )
	
	applyReference ();

EndProcedure

&AtClient
Procedure applyReference ()
	
	notExactlySeriesAndNumber = Object.Import;
	if ( notExactlySeriesAndNumber ) then
		return;
	endif;
	adjustReference ();
	extractSeries ();

EndProcedure

&AtClient
Procedure adjustReference ()
	
	Object.Reference = StrConcat ( StrSplit ( Object.Reference, " /:-#" ) );

EndProcedure

&AtClient
Procedure extractSeries ()
	
	series = new Array ();
	fullNumber = Object.Reference;
	for i = 1 to StrLen ( fullNumber ) do
		letter = Mid ( fullNumber, i, 1 );
		if ( StrFind ( "0123456789", letter ) = 0 ) then
			series.Add ( letter );
		else
			break;
		endif;
	enddo;
	Object.Series = StrConcat ( series );

EndProcedure

&AtClient
Procedure VATUseOnChange ( Item )
	
	applyVATUse ();
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure PricesOnChange ( Item )
	
	applyPrices ();
	updateTotals ( ThisObject );
	
EndProcedure

&AtServer
Procedure applyPrices ()
	
	vatUse = Object.VATUse;
	cache = new Map ();
	date = Object.Date;
	prices = Object.Prices;
	vendor = Object.Vendor;
	contract = Object.Contract;
	warehouse = Object.Warehouse;
	currency = Object.Currency;
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
Procedure ExpensesPeriodOnChange ( Item )
	
	adjustExpensesPeriod ();
	
EndProcedure

&AtClient
Procedure adjustExpensesPeriod ()
	
	if ( Object.ExpensesPeriod = Date ( 1, 1, 1 ) ) then
		return;
	endif;
	Object.ExpensesPeriod = EndOfMonth ( Object.ExpensesPeriod );
	
EndProcedure 

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure ApplyPurchaseOrders ( Command )
	
	Filler.Open ( fillingParams ( "PurchaseOrderItems", Object.PurchaseOrder ), ThisObject );
	
EndProcedure

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( not fillTables ( Result, Params.Report ) ) then
		Output.FillingDataNotFound ();
	endif;
	updateTotals ( ThisObject );
	
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
	if ( Report = meta.PurchaseOrderItems.Name ) then
		loadPurchaseOrders ( table );
		DiscountsTable.Load ( Object );
	elsif ( Report = meta.InternalOrders.Name ) then
		loadInternalOrders ( table );
	elsif ( Report = meta.SalesOrderItems.Name ) then
		loadSalesOrders ( table );
	endif; 
	InvoiceForm.SetPayment ( Object );
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
Procedure enableSocial () 

	if ( ItemsRow = undefined ) then
		return;
	endif;
	Items.ItemsProducerPrice.ReadOnly = not ItemsRow.Social;

EndProcedure

&AtClient
Procedure ItemsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( purchaseOrderColumn ( Item )
		and not ItemsRow.PurchaseOrder.IsEmpty () ) then
		StandardProcessing = false;
		ShowValue ( , ItemsRow.PurchaseOrder );
	endif; 
	
EndProcedure

&AtClient
Function purchaseOrderColumn ( Item )
	
	return Find ( Item.CurrentItem.Name, "PurchaseOrder" ) > 0;
	
EndFunction 

&AtClient
Procedure ItemsBeforeRowChange ( Item, Cancel )
	
	enableSocial ();
	
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

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	updateTotals ( ThisObject );
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
	ItemsRow.Account = data.Account;
	ItemsRow.VATCode = data.VAT;
	ItemsRow.VATRate = data.Rate;
	ItemsRow.VATAccount = data.VATAccount;
	ItemsRow.Social = data.Social;
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	warehouse = Params.Warehouse;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate, Social" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, data.Package, , Params.Organization, Params.Contract, true, warehouse, Params.Currency );
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
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	applyQuantity ();
	
EndProcedure

&AtClient
Procedure applyQuantity ()
	
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
Procedure ItemsRangeStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	chooseRange ( Item );
	
EndProcedure

&AtClient
Procedure chooseRange ( Item )
	
	filter = new Structure ();
	date = Periods.GetBalanceDate ( Object );
	if ( date <> undefined
		and Object.Posted ) then
		date = date - 1;
	endif;
	filter.Insert ( "Date", date );
	filter.Insert ( "Item", ItemsRow.Item );
	filter.Insert ( "Feature", ItemsRow.Feature );
	filter.Insert ( "Series", ItemsRow.Series );
	filter.Insert ( "Package", ItemsRow.Package );
	filter.Insert ( "Capacity", ItemsRow.Capacity );
	filter.Insert ( "Account", ItemsRow.Account );
	filter.Insert ( "Company", Object.Company );
	p = new Structure ( "Received, Filter", Object.Date, filter );
	OpenForm ( "Catalog.Ranges.Form.New", p, Item );
	
EndProcedure

&AtClient
Procedure ItemsRangeCreating ( Item, StandardProcessing )
	
	StandardProcessing = false;
	createRange ( Item );
	
EndProcedure

&AtClient
Procedure createRange ( Item )
	
	p = new Structure ();
	p.Insert ( "Received", Object.Date );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Feature", ItemsRow.Feature );
	p.Insert ( "Series", ItemsRow.Series );
	p.Insert ( "Package", ItemsRow.Package );
	p.Insert ( "Capacity", ItemsRow.Capacity );
	p.Insert ( "Account", ItemsRow.Account );
	p.Insert ( "Company", Object.Company );
	OpenForm ( "Catalog.Ranges.ObjectForm", new Structure ( "FillingValues, ChoiceMode", p, true ), Item );
	
EndProcedure

&AtClient
Procedure ItemsRangeOnChange ( Item )
	
	applyRange ();
	
EndProcedure

&AtClient
Procedure applyRange ()
	
	range = ItemsRow.Range;
	if ( range.IsEmpty () ) then
		return;
	endif;
	data = DF.Values ( range, "Start, Finish" );
	qty = 1 + data.Finish - data.Start;
	if ( ItemsRow.Quantity = qty ) then
		return;
	endif;
	ItemsRow.Quantity = qty;
	applyQuantity ();
	
EndProcedure

// *****************************************
// *********** Table Services

&AtClient
Procedure ServicesOnActivateRow ( Item )
	
	ServicesRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ServicesSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( purchaseOrderColumn ( Item )
		and not ServicesRow.PurchaseOrder.IsEmpty () ) then
		StandardProcessing = false;
		ShowValue ( , ServicesRow.PurchaseOrder );
	endif; 
	
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
	p.Insert ( "Company", Object.Company );
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
	ServicesRow.VATAccount = data.VATAccount;
	ServicesRow.Account = data.Account;
	ServicesRow.Expense = data.Expense;
	ServicesRow.Department = data.Department;
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure 

&AtServerNoContext
Function getServiceData ( val Params )
	
	item = Params.Item;
	warehouse = Params.Warehouse;
	data = DF.Values ( item, "FullDescription, VAT, VAT.Rate as Rate" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, , , Params.Organization, Params.Contract, true, warehouse, Params.Currency );
	accounts = AccountsMap.Item ( item, Params.Company, warehouse, "VAT, Account, Department, Expense" );
	data.Insert ( "Price", price );
	data.Insert ( "VATAccount", accounts.VAT );
	data.Insert ( "Account", accounts.Account );
	data.Insert ( "Expense", accounts.Expense );
	data.Insert ( "Department", accounts.Department );
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
	
	Computations.Discount ( ServicesRow );
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
Procedure ServicesVATCodeOnChange ( Item )
	
	ServicesRow.VATRate = DF.Pick ( ServicesRow.VATCode, "Rate" );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesVATOnChange ( Item )
	
	updateTotals ( ThisObject, ServicesRow, false );
	
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
Procedure ServicesDistributionOnChange ( Item )
	
	setFlags ();
	
EndProcedure

&AtClient
Procedure setFlags ()
	
	if ( ServicesRow.Distribution.IsEmpty () ) then
		ServicesRow.IntoItems = false;
		ServicesRow.IntoFixedAssets = false;
		ServicesRow.IntoIntangibleAssets = false;
		ServicesRow.IntoDocument = undefined;
	else
		if ( not ( ServicesRow.IntoItems
				or ServicesRow.IntoFixedAssets
				or ServicesRow.IntoIntangibleAssets ) ) then
			ServicesRow.IntoItems = true;
			ServicesRow.IntoFixedAssets = true;
			ServicesRow.IntoIntangibleAssets = true;
		endif; 
	endif; 
	
EndProcedure 

&AtClient
Procedure ServicesIntoItemsOnChange ( Item )
	
	setDistribution ();
	
EndProcedure

&AtClient
Procedure setDistribution ()
	
	if ( ServicesRow.IntoItems
		or ServicesRow.IntoIntangibleAssets
		or ServicesRow.IntoFixedAssets
		or not ServicesRow.IntoDocument.IsEmpty () ) then
		if ( ServicesRow.Distribution.IsEmpty () ) then
			ServicesRow.Distribution = PredefinedValue ( "Enum.Distribution.Quantity" );
		endif; 
	else
		ServicesRow.Distribution = undefined;
	endif; 
	
EndProcedure 

&AtClient
Procedure ServicesIntoFixedAssetsOnChange ( Item )
	
	setDistribution ();
	
EndProcedure

&AtClient
Procedure ServicesIntoIntangibleAssetsOnChange ( Item )
	
	setDistribution ();
	
EndProcedure

&AtClient
Procedure ServicesIntoDocumentOnChange ( Item )
	
	setDistribution ();
	setFlags ();
	
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
	
	updateTotals ( ThisObject );
	
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
	
	updateTotals ( ThisObject );
	
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
	updateTotals ( ThisObject );
	
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
	
	updateTotals ( ThisObject );
	
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
	
	applyAccount ();
	adjustDims ();
	enableDims ();
	updateTotals ( ThisObject, AccountsRow );
	
EndProcedure

&AtClient
Procedure applyAccount ()
	
	data = accountData ( AccountsRow.Account, Object.Company, Object.Warehouse );
	AccountData = data.Data;
	AccountsRow.VATAccount = data.VAT;
	
EndProcedure

&AtServerNoContext
Function accountData ( val Account, val Company, val Warehouse )
	
	result = new Structure ( "Data, VAT" );
	result.Data = GeneralAccounts.GetData ( Account );
	result.VAT = AccountsMap.Item ( Catalogs.Items.EmptyRef (), Company, Warehouse, "VAT" ).VAT;;
	return result;
	
EndFunction

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
Procedure AccountsAmountOnChange ( Item )

	updateTotals ( ThisObject, AccountsRow );

EndProcedure

&AtClient
Procedure AccountsCurrencyOnChange ( Item )
	
	setCurrency ();
	calcAmount ();
	updateTotals ( ThisObject, AccountsRow );
	
EndProcedure

&AtClient
Procedure setCurrency ()
	
	info = CurrenciesSrv.Get ( AccountsRow.Currency, Object.Date );
	AccountsRow.Rate = info.Rate;
	AccountsRow.Factor = info.Factor;
	
EndProcedure 

&AtClient
Procedure calcAmount ()
	
	AccountsRow.Amount = AccountsRow.CurrencyAmount * AccountsRow.Rate / AccountsRow.Factor;
	
EndProcedure 

&AtClient
Procedure AccountsRateOnChange ( Item )
	
	calcAmount ();
	updateTotals ( ThisObject, AccountsRow );
	
EndProcedure

&AtClient
Procedure AccountsFactorOnChange ( Item )
	
	calcAmount ();
	updateTotals ( ThisObject, AccountsRow );

EndProcedure

&AtClient
Procedure AccountsCurrencyAmountOnChange ( Item )
	
	calcAmount ();
	updateTotals ( ThisObject, AccountsRow );
	
EndProcedure

&AtClient
Procedure AccountsVATCodeOnChange ( Item )
	
	AccountsRow.VATRate = DF.Pick ( AccountsRow.VATCode, "Rate" );
	updateTotals ( ThisObject, AccountsRow );
	
EndProcedure

&AtClient
Procedure AccountsVATOnChange ( Item )
	
	updateTotals ( ThisObject, AccountsRow, false );
	
EndProcedure

// *****************************************
// *********** Table Discounts

&AtClient
Procedure RefreshDiscounts ( Command )
	
	updateDiscounts ();
	
EndProcedure

&AtServer
Procedure updateDiscounts ()
	
	DiscountsTable.Load ( Object );
	applyPaymentDiscount ();
	
EndProcedure

&AtServer
Procedure applyPaymentDiscount ()
	
	InvoiceForm.SetPaymentsApplied ( ThisObject );
	updateTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure DiscountsOnEditEnd ( Item, NewRow, CancelEdit )

	applyPaymentDiscount ();
	
EndProcedure

&AtClient
Procedure DiscountsAfterDeleteRow ( Item )
	
	applyPaymentDiscount ();
	
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

// *****************************************
// *********** Group More

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	InvoiceForm.SetRate ( ThisObject );
	updateTotals ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure

&AtClient
Procedure ImportOnChange  (Item )
	
	applyReference ();

EndProcedure
