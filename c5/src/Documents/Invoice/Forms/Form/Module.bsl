&AtServer
var Env;
&AtServer
var Base;
&AtClient
var ItemsRow;
&AtClient
var ServicesRow;
&AtServer
var SalesOrderExists;
&AtServer
var ShipmentExists;
&AtServer
var TimeEntryExists;
&AtServer
var Copy;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	updateBalanceDue ();
	InvoiceRecords.Read ( ThisObject );
	initCurrency ();
	setSocial ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateBalanceDue ()

	InvoiceForm.SetPaymentsApplied ( ThisObject );
	InvoiceForm.CalcBalanceDue ( ThisObject );
	Appearance.Apply ( ThisObject, "BalanceDue" );

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
			fillByCustomer ();
		else
			baseType = TypeOf ( Base );
			if ( baseType = Type ( "DocumentRef.SalesOrder" ) ) then
				fillBySaleOrder ();
			elsif ( baseType = Type ( "DocumentRef.TimeEntry" ) ) then
				fillByTimeEntry ();
			endif; 
		endif;
		updateBalanceDue ();
	endif; 
	setAccuracy ();
	setLinks ();
	setSocial ();
	Forms.ActivatePage ( ThisObject, "ItemsTable,Services,Discounts" );
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
	|Links show ShowLinks;
	|ContractAmount show filled ( ContractCurrency ) and ContractCurrency <> Object.Currency;
	|ContractAmount title/Form.ContractCurrency ContractCurrency <> Object.Currency;
	|Rate Factor enable
	|filled ( LocalCurrency )
	|and filled ( ContractCurrency )
	|and ( Object.Currency <> LocalCurrency or ContractCurrency <> LocalCurrency );
	|Company Customer Contract Currency lock filled ( Object.SalesOrder )
	|	or filled ( Object.TimeEntry );
	|CreatePayment show BalanceDue <> 0;
	|#c ServicesSalesOrder show Items.Services.CurrentData <> undefined
	|	and filled ( Items.Services.CurrentData.SalesOrder );
	|VAT ItemsVATAccount ServicesVATAccount DiscountsVATAccount show Object.VATUse > 0;
	|FormInvoice show filled ( InvoiceRecord );
	|NewInvoiceRecord show FormStatus = Enum.FormStatuses.Canceled or empty ( FormStatus );
	|Header GroupItems GroupServices Footer Discounts GroupMore lock inlist ( FormStatus, Enum.FormStatuses.Waiting, Enum.FormStatuses.Unloaded, Enum.FormStatuses.Printed, Enum.FormStatuses.Submitted );
	|Warning show inlist ( FormStatus, Enum.FormStatuses.Waiting, Enum.FormStatuses.Unloaded, Enum.FormStatuses.Printed, Enum.FormStatuses.Submitted );
	|ItemsSelectItems ServicesSelectItems ItemsScan ItemsApplySalesOrders ServicesApplySalesOrders DiscountsRefreshDiscounts disable inlist ( FormStatus, Enum.FormStatuses.Waiting, Enum.FormStatuses.Unloaded, Enum.FormStatuses.Printed, Enum.FormStatuses.Submitted );
	|ItemsVATCode ItemsVAT ItemsTotal ServicesVATCode ServicesVAT ServicesTotal
	|	DiscountsVATCode DiscountsVAT show Object.VATUse > 0;
	|ItemsProducerPrice ItemsExtraCharge show UseSocial;
	|#s DiscountsPage hide Mobile and Form.Object.Discounts.Count () = 0;
	|#s ItemsApplySalesOrders hide filled ( Object.TimeEntry );
	|#s ItemsApplyTimeEntries hide filled ( Object.SalesOrder );
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
Procedure fillByCustomer ()
	
	apply = Parameters.FillingValues.Property ( "Customer" )
	and not Copy 
	and not Object.Customer.IsEmpty ();
	if ( apply ) then
		applyCustomer ();
	endif;

EndProcedure 

&AtServer
Procedure applyCustomer ()
	
	customer = Object.Customer;
	company = Object.Company;
	data = AccountsMap.Organization ( customer, company, "CustomerAccount, DiscountGiven" );
	Object.CustomerAccount = data.CustomerAccount;
	Object.DiscountAccount = data.DiscountGiven;
	data = DF.Values ( customer, "CustomerContract, CustomerContract.Company as Company, VATUse" );
	if ( data.Company = company ) then
		Object.Contract = data.CustomerContract;
	endif; 
	Object.VATUse = data.VATUse;
	applyContract ();
	applyVATUse ();
	
EndProcedure

&AtServer
Procedure applyContract ()
	
	data = DF.Values ( Object.Contract,
		"CustomerPrices, Currency, CustomerAdvances, CustomerRateType, CustomerRate, CustomerFactor" );
	ContractCurrency = data.Currency;
	if ( data.CustomerRateType = Enums.CurrencyRates.Fixed
		and data.CustomerRate <> 0 ) then
		currency = new Structure ( "Rate, Factor", data.CustomerRate, data.CustomerFactor );
	else
		currency = CurrenciesSrv.Get ( data.Currency, Object.Date );
	endif;
	Object.CloseAdvances = data.CustomerAdvances;
	Object.Rate = currency.Rate;
	Object.Factor = currency.Factor;
	Object.Currency = ContractCurrency;
	Object.Prices = data.CustomerPrices;
	InvoiceForm.SetCurrencyList ( ThisObject );
	updateContent ();
	updateTotals ( ThisObject );
	updateBalanceDue ();
	Appearance.Apply ( ThisObject, "Object.Currency" );

EndProcedure

&AtServer
Procedure updateContent ()
	
	reloadTables ();
	DiscountsTable.Load ( Object );
	InvoiceForm.SetPayment ( Object );
	
EndProcedure 

&AtServer
Procedure reloadTables ()
	
	table = FillerSrv.GetData ( fillingParams () );
	if ( table.Count () > 0 ) then
		loadSalesOrders ( table, true );
	endif; 
	
EndProcedure 

#region Filling

&AtServer
Procedure fillBySaleOrder ()
	
	setEnv ();
	sqlSalesOrder ();
	SQL.Perform ( Env );
	headerBySalesOrder ();
	table = FillerSrv.GetData ( fillingParams () );
	loadSalesOrders ( table, true );
	DiscountsTable.Load ( Object );
	updateTotals ( ThisObject );
	InvoiceForm.SetPayment ( Object );
	
EndProcedure 

&AtServer
Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	Env.Q.SetParameter ( "Me", SessionParameters.User );
	
EndProcedure

&AtServer
Procedure sqlSalesOrder ()
	
	s = "
	|// @Fields
	|select Documents.Company as Company, Documents.Contract as Contract, Documents.Currency as Currency,
	|	Documents.Contract.Currency as ContractCurrency, Documents.Contract.CustomerRateType as RateType,
	|	Documents.Rate as Rate, Documents.Factor as Factor, Documents.Customer as Customer,
	|	Documents.Prices as Prices, Documents.VATUse as VATUse,
	|	Documents.Warehouse as Warehouse, Documents.Department as Department,
	|	Documents.Contract.CustomerAdvances as CloseAdvances
	|from Document.SalesOrder as Documents
	|where Documents.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure headerBySalesOrder ()
	
	fields = Env.Fields;
	FillPropertyValues ( Object, fields );
	Object.SalesOrder = Base;
	ContractCurrency = fields.ContractCurrency;
	if ( fields.RateType = Enums.CurrencyRates.Current ) then
		currency = CurrenciesSrv.Get ( Object.Currency, Object.Date );
		Object.Rate = currency.Rate;
		Object.Factor = currency.Factor;
	endif;
	data = AccountsMap.Organization ( Object.Customer, Object.Company, "CustomerAccount, DiscountGiven" );
	Object.CustomerAccount = data.CustomerAccount;
	Object.DiscountAccount = data.DiscountGiven;
	InvoiceForm.SetCurrencyList ( ThisObject );
	
EndProcedure 

&AtServer
Function fillingParams ()
	
	p = Filler.GetParams ();
	p.Report = "SalesOrderItems";
	p.Filters = getFilters ();
	p.ProposeClearing = Object.SalesOrder.IsEmpty ();
	return p;
	
EndFunction

&AtServer
Function getFilters ()
	
	filters = new Array ();
	if ( Object.SalesOrder.IsEmpty () ) then
		filters.Add ( DC.CreateFilter ( "SalesOrder.Customer", Object.Customer ) );
		filters.Add ( DC.CreateFilter ( "SalesOrder.Contract", Object.Contract ) );
	else
		filters.Add ( DC.CreateFilter ( "SalesOrder", Object.SalesOrder ) );
	endif; 
	item = DC.CreateParameter ( "Asof" );
	item.Value = Periods.GetBalanceDate ( Object );
	item.Use = ( item.Value <> undefined );
	filters.Add ( item );
	return filters;
	
EndFunction

&AtServer
Procedure loadSalesOrders ( Table, Clean )
	
	company = Object.Company;
	oneWarehouse = not Options.WarehousesInTable ( company );
	oneOrder = not Options.SalesOrdersInTable ( company );
	warehouse = Object.Warehouse;
	salesOrder = Object.SalesOrder;
	vatUse = Object.VATUse;
	tableItems = Object.Items;
	services = Object.Services;
	if ( Clean ) then
		tableItems.Clear ();
		services.Clear ();
	endif;
	for each row in Table do
		if ( row.ItemService ) then
			docRow = services.Add ();
			FillPropertyValues ( docRow, row );
			item = row.Item;
			docRow.Description = DF.Pick ( item, "FullDescription" );
			accounts = AccountsMap.Item ( item, company, warehouse, "Income, VAT" );
			docRow.Income = accounts.Income;
			docRow.VATAccount = accounts.VAT;
		else
			docRow = tableItems.Add ();
			FillPropertyValues ( docRow, row );
			if ( oneWarehouse
				or docRow.Warehouse = warehouse ) then
				docRow.Warehouse = undefined;
			endif; 
			accounts = AccountsMap.Item ( docRow.Item, company, warehouse, "Account, SalesCost, Income, VAT" );
			docRow.Account = accounts.Account;
			docRow.SalesCost = accounts.SalesCost;
			docRow.Income = accounts.Income;
			docRow.VATAccount = accounts.VAT;
		endif;
		Computations.Discount ( docRow );
		Computations.Amount ( docRow );
		Computations.Total ( docRow, vatUse );
		if ( oneOrder
			or docRow.SalesOrder = salesOrder ) then
			docRow.SalesOrder = undefined;
		endif; 
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
Procedure fillByTimeEntry ()
	
	setEnv ();
	sqlTimeEntry ();
	SQL.Perform ( Env );
	headerByTimeEntry ();
	SetPrivilegedMode ( true );
	table = FillerSrv.GetData ( timeEntryFillingParams () );
	loadTimeEntries ( table, true );
	updateTotals ( ThisObject );
	
EndProcedure

&AtServer
Procedure sqlTimeEntry ()
	
	s = "
	|// @Fields
	|select Documents.Customer as Customer, Documents.Warehouse as Warehouse, Documents.Company as Company,
	|	Settings.Department as Department
	|from Document.TimeEntry as Documents
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
Function timeEntryFillingParams ()
	
	p = Filler.GetParams ();
	p.Report = "TimeEntriesInvoicing";
	p.Filters = getTimeEntryFilters ();
	p.ProposeClearing = Object.TimeEntry.IsEmpty ();
	return p;
	
EndFunction

&AtServer
Function getTimeEntryFilters ()
	
	filters = new Array ();
	if ( Object.TimeEntry.IsEmpty () ) then
		filters.Add ( DC.CreateFilter ( "Customer", Object.Customer ) );
	else
		filters.Add ( DC.CreateFilter ( "TimeEntry", Object.TimeEntry ) );
	endif; 
	item = DC.CreateParameter ( "DateEnd" );
	item.Value = Periods.GetBalanceDate ( Object );
	item.Use = ( item.Value <> undefined );
	filters.Add ( item );
	return filters;
	
EndFunction

&AtServer
Procedure loadTimeEntries ( Table, Clean )
	
	company = Object.Company;
	warehouse = Object.Warehouse;
	timeEntry = Object.TimeEntry;
	vatUse = Object.VATUse;
	warehouseInTable = Options.WarehousesInTable ( Object.Company );
	itemsTable = Object.Items;
	if ( Clean ) then
		itemsTable.Clear ();
	endif;
	for each row in table do
		item = row.Item;
		qty = row.QuantityClosingBalance;
		if ( row.ItemType = Enums.Tables.Items ) then
			newRow = itemsTable.Add ();
			FillPropertyValues ( newRow, row );
			newRow.QuantityPkg = qty / row.Capacity;
			if ( warehouseInTable ) then
				newRow.Warehouse = ? ( warehouse = row.Warehouse, undefined, row.Warehouse );
			else
				newRow.Warehouse = warehouse;
			endif;
			accounts = AccountsMap.Item ( item, company, warehouse, "Account, SalesCost, Income, VAT" );
			newRow.Account = accounts.Account;
			newRow.SalesCost = accounts.SalesCost;
			newRow.Income = accounts.Income;
			newRow.VATAccount = accounts.VAT;
		else
			newRow = Object.Services.Add ();
			newRow.Description = row.TaskDescription;
			newRow.Price = row.HourlyRate;
			newRow.Amount = row.AmountClosingBalance;
			accounts = AccountsMap.Item ( item, company, warehouse, "Income, VAT" );
			newRow.Income = accounts.Income;
			newRow.VATAccount = accounts.VAT;
		endif;
		newRow.Quantity = qty;
		newRow.Item = item;
		newRow.TimeEntryRow = row.RowKey;
		newRow.TimeEntry = ? ( timeEntry = row.TimeEntry, undefined, row.TimeEntry );
		newRow.VATCode = row.ItemVAT;
		newRow.VATRate = row.ItemVATRate;
		Computations.Amount ( newRow );
		Computations.Total ( newRow, vatUse );
	enddo; 
	
EndProcedure 

&AtServer
Procedure headerByTimeEntry ()
	
	fields = Env.Fields;
	Object.TimeEntry = Base;
	Object.Company = fields.Company;
	Object.Warehouse = fields.Warehouse;
	Object.Department = fields.Department;
	Object.Customer = fields.Customer;
	applyCustomer (); 
	
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
		q.SetParameter ( "TimeEntry", Object.TimeEntry );
		q.SetParameter ( "SalesOrder", Object.SalesOrder );
		q.SetParameter ( "Shipment", Object.Shipment );
		q.SetParameter ( "Contract", Object.Contract );
		q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( Env, false );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	selection = Env.Selection;
	TimeEntryExists = not Object.TimeEntry.IsEmpty ();
	SalesOrderExists = not Object.SalesOrder.IsEmpty ();
	ShipmentExists = not Object.Shipment.IsEmpty ();
	if ( TimeEntryExists ) then
		s = "
		|// #TimeEntries
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.TimeEntry as Documents
		|where Documents.Ref = &TimeEntry
		|";
		selection.Add ( s );
	endif;
	if ( SalesOrderExists ) then
		s = "
		|// #SalesOrders
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.SalesOrder as Documents
		|where Documents.Ref = &SalesOrder
		|";
		selection.Add ( s );
	endif;
	if ( ShipmentExists ) then
		s = "
		|// #Shipments
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.Shipment as Documents
		|where Documents.Ref = &Shipment
		|";
		selection.Add ( s );
	endif;
	if ( isNew () ) then
		return;
	endif; 
	s = "
	|// #Payments
	|select Documents.Ref as Document,
	|	case when Documents.ReferenceDate = datetime ( 1, 1, 1 ) then Documents.Date else Documents.ReferenceDate end as Date,
	|	case when Documents.Reference = """" then Documents.Number else Documents.Reference end as Number
	|from Document.Payment as Documents
	|where Documents.Ref in (
	|	select Documents.Ref as Ref
	|	from Document.Payment as Documents
	|	where Documents.Contract = &Contract
	|	and Documents.Base = &Ref
	|	union
	|	select Documents.Ref as Ref
	|	from Document.Payment.Payments as Documents
	|	where Documents.Contract = &Contract
	|	and &Ref in ( Documents.Detail, Documents.Document )
	|)
	|and not Documents.DeletionMark
	|;
	|// #Returns
	|select distinct Items.Ref as Document,
	|	case when Items.Ref.Reference = """" then Items.Ref.Number else Items.Ref.Reference end as Number,
	|	case when Items.Ref.ReferenceDate = datetime ( 1, 1, 1 ) then Items.Ref.Date else Items.Ref.ReferenceDate end as Date
	|from Document.Return.Items as Items
	|where Items.Invoice = &Ref
	|and not Items.Ref.DeletionMark
	|order by Date
	|;
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
	meta = Metadata.Documents;
	if ( SalesOrderExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.SalesOrders, meta.SalesOrder ) );
	endif; 
	if ( ShipmentExists ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Shipments, meta.Shipment ) );
	endif; 
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Payments, meta.Payment ) );
		parts.Add ( URLPanel.DocumentsToURL ( Env.Returns, meta.Return ) );
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
		addSelectedServices ( SelectedValue );
		updateTotals ( ThisObject );
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

&AtClient
Procedure applySocial () 

	UseSocial = findSocial ( Object.Items );
	Appearance.Apply ( ThisObject, "UseSocial" );

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
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	alreadyProcessed = TypeOf ( NewObject ) = Type ( "DocumentRef.Payment" );
	if ( alreadyProcessed ) then
		return;
	else
		readNewInvoices ( NewObject );
		updateLinks ();
	endif;
	
EndProcedure

&AtServer
Procedure readNewInvoices ( NewObject ) 

	type = TypeOf ( NewObject );
	if ( type = Type ( "DocumentRef.InvoiceRecord" ) ) then
		InvoiceRecords.Read ( ThisObject );
		Appearance.Apply ( ThisObject, "InvoiceRecord, FormStatus" );
	endif;

EndProcedure

&AtServer
Procedure updateLinks ()
	
	setLinks ();
	updateBalanceDue ();

EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
		applySocial ();
	elsif ( EventName = Enum.InvoiceRecordsWrite ()
		and Source.Ref = InvoiceRecord ) then
		readPrinted ();
	elsif ( EventName = Enum.MessagePaymentIsSaved ()
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
		warehouse = Object.Warehouse;
		row.Price = Goods.Price ( , Object.Date, Object.Prices, item, package, feature, Object.Customer, Object.Contract, , warehouse, Object.Currency );
		data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
		row.VATCode = data.VAT;
		row.VATRate = data.Rate;
		accounts = AccountsMap.Item ( item, Object.Company, warehouse, "Account, SalesCost, Income, VAT" );
		row.Account = accounts.Account;
		row.SalesCost = accounts.SalesCost;
		row.Income = accounts.Income;
		row.VATAccount = accounts.VAT;
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
	Forms.DeleteLastRow ( Object.Services, "Item" );
	
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
Procedure readPrinted ()
	
	InvoiceRecords.Read ( ThisObject );
	Appearance.Apply ( ThisObject, "FormStatus" );
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	updateBalanceDue ();	
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageInvoiceIsSaved (), Object.Ref );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure CustomerOnChange ( Item )
	
	applyCustomer ();

EndProcedure

&AtClient
Procedure ContractOnChange ( Item )
	
	applyContract ();
	
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
	customer = Object.Customer;
	contract = Object.Contract;
	currency = Object.Currency;
	for each row in Object.Items do
		row.Prices = undefined;
		warehouse = getWarehouse ( row, Object );
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, customer, contract, , warehouse, currency );
		Computations.Discount ( row );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	cache = new Map ();
	warehouse = Object.Warehouse;
	for each row in Object.Services do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, , row.Feature, customer, contract, , warehouse, currency );
		Computations.Discount ( row );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	
EndProcedure 

&AtClientAtServerNoContext
Function getWarehouse ( TableRow, Object )
	
	return ? ( TableRow.Warehouse.IsEmpty (), Object.Warehouse, TableRow.Warehouse );
	
EndFunction 

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
Procedure DateOnChange ( Item )
	
	updateContent ();
	
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
		Computations.ExtraCharge ( row );
	enddo; 
	for each row in Object.Services do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	DiscountsTable.RecalcVAT ( ThisObject );
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
	
	OpenForm ( "CommonForm.Scan", , ThisObject );
	
EndProcedure

&AtClient
Procedure ApplySalesOrders ( Command )
	
	Filler.Open ( fillingParams (), ThisObject );
	
EndProcedure

&AtClient
Procedure Filling ( Result, Params ) export
	
	if ( not fillTables ( Result, Params.Report ) ) then
		Output.FillingDataNotFound ();
	endif;
	
EndProcedure 

&AtServer
Function fillTables ( val Result, val Source )
	
	table = Filler.Fetch ( Result );
	if ( table = undefined ) then
		return false;
	endif;
	if ( Source = "TimeEntriesInvoicing" ) then
		loadTimeEntries ( table, Result.ClearTable );
	else
		loadSalesOrders ( table, Result.ClearTable );
	endif;
	DiscountsTable.Load ( Object );
	updateTotals ( ThisObject );
	InvoiceForm.SetPayment ( Object );
	return true;
	
EndFunction

&AtClient
Procedure ApplyTimeEntries ( Command )
	
	Filler.Open ( timeEntryFillingParams (), ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	enableSocial ();
	
EndProcedure

&AtClient
Procedure ItemsBeforeRowChange ( Item, Cancel )
	
	enableSocial ();
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	applySocial ();
	updateTotals ( ThisObject );
	
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
	p.Insert ( "Organization", Object.Customer );
	p.Insert ( "Contract", Object.Contract );
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
	ItemsRow.VATAccount = data.VATAccount;
	ItemsRow.Account = data.Account;
	ItemsRow.SalesCost = data.SalesCost;
	ItemsRow.Income = data.Income;
	ItemsRow.ProducerPrice = data.ProducerPrice;
	ItemsRow.Social = data.Social;
	Computations.Units ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.ExtraCharge ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow )
	
EndProcedure

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate, Social" );
	warehouse = Params.Warehouse;
	package = data.Package;
	date = Params.Date;
	price = Goods.Price ( , Params.Date, Params.Prices, item, package, , Params.Organization, Params.Contract, , warehouse, Params.Currency );
	accounts = AccountsMap.Item ( item, Params.Company, warehouse, "Account, SalesCost, Income, VAT" );
	data.Insert ( "Price", price );
	data.Insert ( "Account", accounts.Account );
	data.Insert ( "SalesCost", accounts.SalesCost );
	data.Insert ( "Income", accounts.Income );
	data.Insert ( "VATAccount", accounts.VAT );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif;
	p = itemParams ( item, package );
	data.Insert ( "ProducerPrice", ? ( data.Social, Goods.ProducerPrice ( p, date ), 0 ) );
	return data;
	
EndFunction

&AtClient
Procedure ItemsFeatureOnChange ( Item )
	
	priceItem ();
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	setProducerPrice ();
	Computations.ExtraCharge ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	warehouse = getWarehouse ( ItemsRow, Object );
	ItemsRow.Price = Goods.Price ( , Object.Date, prices, ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature, Object.Customer, Object.Contract, , warehouse, Object.Currency );
	
EndProcedure 

&AtClient
Procedure setProducerPrice () 

	if ( not ItemsRow.Social ) then
		return;
	endif;
	p = itemParams ( ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature );
	ItemsRow.ProducerPrice = Goods.ProducerPrice ( p, Object.Date );

EndProcedure

&AtClientAtServerNoContext
Function itemParams ( val Item, val Package, val Feature = undefined ) 

	p = new Structure ();
	p.Insert ( "Item", Item );
	p.Insert ( "Package", Package );
	p.Insert ( "Feature", Feature );
	return p;

EndFunction

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Organization", Object.Customer );
	p.Insert ( "Contract", Object.Contract );
	p.Insert ( "Warehouse", getWarehouse ( ItemsRow, Object ) );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Feature", ItemsRow.Feature );
	p.Insert ( "Package", ItemsRow.Package );
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	p.Insert ( "Prices", prices );
	p.Insert ( "Social", ItemsRow.Social );
	data = getPackageData ( p );
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	ItemsRow.ProducerPrice = data.ProducerPrice;
	Computations.Units ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.ExtraCharge ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	date = Params.Date;
	price = Goods.Price ( , date, Params.Prices, Params.Item, package, Params.Feature, Params.Organization, Params.Contract, , Params.Warehouse, Params.Currency );
	data = new Structure ();
	data.Insert ( "Capacity", capacity );
	data.Insert ( "Price", price );
	data.Insert ( "ProducerPrice", ? ( Params.Social, Goods.ProducerPrice ( Params, date ), 0 ) );
	return data;
	
EndFunction 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.ExtraCharge ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.ExtraCharge ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPriceOnChange ( Item )

	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.ExtraCharge ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );

EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	Computations.Price ( ItemsRow );
	Computations.Discount ( ItemsRow );
	Computations.ExtraCharge ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsPricesOnChange ( Item )
	
	priceItem ();
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.ExtraCharge ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsDiscountRateOnChange ( Item )
	
	Computations.Discount ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.ExtraCharge ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsDiscountOnChange ( Item )
	
	Computations.DiscountRate ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.ExtraCharge ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsVATCodeOnChange ( Item )
	
	ItemsRow.VATRate = DF.Pick ( ItemsRow.VATCode, "Rate" );
	Computations.ExtraCharge ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsVATOnChange ( Item )
	
	Computations.ExtraCharge ( ItemsRow );
	updateTotals ( ThisObject, ItemsRow, false );
	
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
	Appearance.Update ( ThisObject, "ServicesSalesOrder" );
	
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
	p.Insert ( "Organization", Object.Customer );
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
	ServicesRow.Income = data.Income;
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure 

&AtServerNoContext
Function getServiceData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "FullDescription, VAT, VAT.Rate as Rate" );
	warehouse = Params.Warehouse;
	price = Goods.Price ( , Params.Date, Params.Prices, item, , , Params.Organization, Params.Contract, , warehouse, Params.Currency );
	accounts = AccountsMap.Item ( item, Params.Company, warehouse, "Income, VAT" );
	data.Insert ( "Price", price );
	data.Insert ( "Income", accounts.Income );
	data.Insert ( "VATAccount", accounts.VAT );
	return data;
	
EndFunction 

&AtClient
Procedure ServicesFeatureOnChange ( Item )
	
	priceService ();
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	updateTotals ( ThisObject, ServicesRow );
	
EndProcedure

&AtClient
Procedure priceService ()
	
	prices = ? ( ServicesRow.Prices.IsEmpty (), Object.Prices, ServicesRow.Prices );
	ServicesRow.Price = Goods.Price ( , Object.Date, prices, ServicesRow.Item, , ServicesRow.Feature, Object.Customer, Object.Contract, , Object.Warehouse, Object.Currency );
	
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
	Computations.Discount ( ServicesRow );
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
