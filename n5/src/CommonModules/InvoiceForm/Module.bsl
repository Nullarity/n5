&AtServer
Procedure SetContractCurrency ( Form ) export
	
	object = Form.Object;
	Form.ContractCurrency = DF.Pick ( object.Contract, "Currency", undefined );
	
EndProcedure 

&AtServer
Procedure SetLocalCurrency ( Form ) export
	
	Form.LocalCurrency = Application.Currency ();
	
EndProcedure 

&AtServer
Procedure SetCurrencyList ( Form ) export

	local = Form.LocalCurrency;
	contract = Form.ContractCurrency;
	list = Form.Items.Currency.ChoiceList;
	list.Clear ();
	list.Add ( local );
	if ( contract <> local
		and not contract.IsEmpty () ) then
		list.Add ( contract );
	endif;
	
EndProcedure

&AtServer
Procedure SetDelivery ( Form, Contract ) export
	
	object = Form.Object;
	days = Contract.Delivery;
	if ( days = 0 ) then
		object.DeliveryDate = undefined;
	else
		object.DeliveryDate = object.Date + days * 86400;
	endif;
	
EndProcedure

&AtServer
Procedure SetRate ( Form ) export
	
	object = Form.Object;
	if ( object.Contract.IsEmpty () ) then
		return;
	endif;
	currencyRate = contractCurrencyRate ( object );
	if ( currencyRate = undefined ) then
		if ( Form.ContractCurrency = Form.LocalCurrency ) then
			currency = object.Currency;
		else
			currency = Form.ContractCurrency;
		endif; 
		currencyRate = CurrenciesSrv.Get ( currency, object.Date );
	endif;
	object.Rate = currencyRate.Rate;
	object.Factor = currencyRate.Factor;
	
EndProcedure 

&AtServer
Function contractCurrencyRate ( Object )
	
	contract = Object.Contract;
	type = TypeOf ( object.Ref );
	isQuote = type = Type ( "DocumentRef.Quote" );
	isSO = type = Type ( "DocumentRef.SalesOrder" );
	isInvoice = type = Type ( "DocumentRef.Invoice" );
	isPO = type = Type ( "DocumentRef.PurchaseOrder" );
	isVendorInvoice = type = Type ( "DocumentRef.VendorInvoice" );
	isReturn = type = Type ( "DocumentRef.Return" );
	isVendorReturn = type = Type ( "DocumentRef.VendorReturn" );
	if ( isQuote or isReturn ) then
		data = DF.Values ( contract, "CustomerRateType, CustomerRate, CustomerFactor" );
		if ( data.CustomerRateType = Enums.CurrencyRates.Fixed
			and data.CustomerRate <> 0 ) then
			return contractRate ( data.CustomerRate, data.CustomerFactor );
		endif;
	elsif ( isSO or isInvoice ) then
		data = DF.Values ( contract, "CustomerRateType, CustomerRate, CustomerFactor" );
		base = ? ( isSO, object.Quote, object.SalesOrder );
		if ( data.CustomerRateType = Enums.CurrencyRates.Fixed ) then
			if ( not base.IsEmpty () ) then
				return DF.Values ( base, "Rate, Factor" );
			elsif ( data.CustomerRate <> 0 ) then
				return contractRate ( data.CustomerRate, data.CustomerFactor );
			endif;
		endif;
	elsif ( isPO or isVendorReturn ) then
		data = DF.Values ( contract, "VendorRateType, VendorRate, VendorFactor" );
		if ( data.VendorRateType = Enums.CurrencyRates.Fixed
			and data.VendorRate <> 0 ) then
			return contractRate ( data.VendorRate, data.VendorFactor );
		endif;
	elsif ( isVendorInvoice ) then
		data = DF.Values ( contract, "VendorRateType, VendorRate, VendorFactor" );
		base = object.PurchaseOrder;
		if ( data.VendorRateType = Enums.CurrencyRates.Fixed ) then
			if ( not base.IsEmpty () ) then
				return DF.Values ( base, "Rate, Factor" );
			elsif ( data.VendorRate <> 0 ) then
				return contractRate ( data.VendorRate, data.VendorFactor );
			endif;
		endif;
	endif;
	return undefined;
	
EndFunction

&AtServer
Function contractRate ( Rate, Factor )
	
	return new Structure ( "Rate, Factor", Rate, Factor );
	
EndFunction

Procedure CalcTotals ( Source ) export
	
	p = getTotalParams ( Source );
	object = p.Object;
	items = object.Items;
	calcServices = p.CalcServices;
	if ( calcServices ) then
		services = object.Services;
	endif;
	vendorInvoice = p.VendorInvoice;
	paymentDiscounts = p.PaymentDiscounts;
	if ( vendorInvoice ) then
		accounts = object.Accounts;
		fixedAssets = object.FixedAssets;
		intangibleAssets = object.IntangibleAssets;
	endif;
	if ( paymentDiscounts ) then
		discounts = object.Discounts;
		discountVAT = discounts.Total ( "VAT" );
		discountAmount = discounts.Total ( "Amount" );
	else
		discountVAT = 0;
		discountAmount = 0;
	endif;
	if ( p.CalcContractAmount ) then
		inContractCurrency = object.Currency = p.ContractCurrency;
		rate = object.Rate;
		factor = object.Factor;
		if ( paymentDiscounts
			and not inContractCurrency ) then
			discountVAT = discountVAT * rate / factor;
			discountAmount = discountAmount * rate / factor;
		endif;
	endif;
	vat = items.Total ( "VAT" )
	+ ? ( calcServices, services.Total ( "VAT" ), 0 )
	- discountVAT;
	amount = items.Total ( "Total" )
	+ ? ( calcServices, services.Total ( "Total" ), 0 )
	- discountAmount;
	if ( vendorInvoice ) then
		vat = vat 
		+ accounts.Total ( "VAT" )
		+ fixedAssets.Total ( "VAT" )
		+ intangibleAssets.Total ( "VAT" );
		amount = amount
		+ accounts.Total ( "Total" )
		+ fixedAssets.Total ( "Total" )
		+ intangibleAssets.Total ( "Total" );
	endif;
	discountTotal = items.Total ( "Discount" )
	+ ? ( calcServices, services.Total ( "Discount" ), 0 )
	+ discountAmount;
	object.VAT = vat;
	object.Amount = amount;
	object.Discount = discountTotal;
	object.GrossAmount = amount - ? ( object.VATUse = 2, vat, 0 ) + discountTotal;
	if ( not p.CalcContractAmount ) then
		return;
	endif;
	if ( inContractCurrency ) then
		object.ContractAmount = amount;
	else
		if ( object.Currency = p.LocalCurrency) then
			object.ContractAmount = amount / rate * factor;
		else
			object.ContractAmount = amount * rate / factor;
		endif; 
	endif; 

EndProcedure 

Function getTotalParams ( Source )
	
	params = new Structure ( "
	|Object,
	|CalcContractAmount,
	|LocalCurrency,
	|ContractCurrency,
	|PaymentDiscounts,
	|VendorInvoice,
	|CalcServices" );
	clientForm = TypeOf ( Source ) = Type ( "ClientApplicationForm" );
	object = ? ( clientForm, Source.Object, Source );
	type = TypeOf ( object.Ref );
	params.VendorInvoice = type = Type ( "DocumentRef.VendorInvoice" );
	params.PaymentDiscounts = params.VendorInvoice or ( type = Type ( "DocumentRef.Invoice" ) );
	params.CalcServices = not (
		type = Type ( "DocumentRef.Sale" )
		or type = Type ( "DocumentRef.Return" )
		or type = Type ( "DocumentRef.VendorReturn" )
	);
	if ( type = Type ( "DocumentRef.ExpenseReport" )
		or type = Type ( "DocumentRef.Shipment" )
		or type = Type ( "DocumentRef.Sale" )
		or type = Type ( "CatalogRef.Leads" ) ) then
		params.CalcContractAmount = false;
	else
		params.CalcContractAmount = true;
		if ( clientForm ) then
			params.LocalCurrency = Source.LocalCurrency;
			params.ContractCurrency = Source.ContractCurrency;
		else
			params.LocalCurrency = Application.Currency ();
			if ( type = Type ( "DocumentRef.Invoice" ) ) then
				params.ContractCurrency = DF.Pick ( object.Contract, "Currency" );
			else
				params.ContractCurrency = object.ContractCurrency;
			endif;
		endif;
	endif;
	params.Object = object;
	return params;
	
EndFunction

&AtServer
Procedure SetPayment ( Object ) export
	
	vendor = TypeOf ( Object.Ref ) = Type ( "DocumentRef.VendorInvoice" );
	option = getPaymentOption ( Object, vendor );
	if ( option = undefined ) then
		Object.PaymentOption = undefined;
		Object.PaymentDate = undefined;
	else
		Object.PaymentOption = option.Value;
		documentDate = Periods.GetDocumentDate ( Object );
		due = option.Due * 86400;
		if ( option.Before ) then
			date = DF.Pick ( Object.Contract, "DateEnd" ) - due;
			if ( date >= documentDate ) then
				Object.PaymentDate = date;
			else
				Object.PaymentDate = undefined;
			endif;
		else
			Object.PaymentDate = documentDate + due;
		endif;
	endif; 
	
EndProcedure 

&AtServer
Function getPaymentOption ( Object, Vendor )
	
	if ( Vendor ) then
		terms = "VendorTerms";
		register = "VendorDebts";
	else
		terms = "CustomerTerms";
		register = "Debts";
	endif; 
	list = InvoiceForm.GetOrders ( Object, Vendor );
	if ( list.Count () = 0 ) then
		s = "
		|select top 1 Payments.Option as Value, Payments.Option.Due as Due,
		|	Payments.Option.Before as Before
		|from Catalog.Terms.Payments as Payments
		|where Payments.Ref in ( select " + terms + " from Catalog.Contracts where Ref = &Contract )
		|and Payments.Variant = value ( Enum.PaymentVariants.OnDelivery )
		|";
	else
		s = "
		|select distinct Payments.Option as Option
		|into Options
		|from Catalog.Terms.Payments as Payments
		|where Payments.Ref in ( select " + terms + " from Catalog.Contracts where Ref = &Contract )
		|and Payments.Variant = value ( Enum.PaymentVariants.OnDelivery )
		|index by Option
		|;
		|select Payments.PaymentKey as Key, Payments.Date
		|into Keys
		|from InformationRegister.PaymentDetails as Payments
		|where Payments.Option in ( select Option from Options )
		|and Payments.Date = datetime ( 3999, 12, 31 )
		|index by Key
		|;
		|select Payments.Option as Value, Payments.Option.Due as Due,
		|	Payments.Option.Before as Before
		|from AccumulationRegister." + register + ".Balance ( &Date,
		|	Contract = &Contract
		|	and PaymentKey in ( select Key from Keys )
		|	and Document in ( &Orders ) ) as Balances
		|	//
		|	// Payment Keys
		|	//
		|	join InformationRegister.PaymentDetails as Payments
		|	on Payments.PaymentKey = Balances.PaymentKey
		|	and Payments.Date = datetime ( 3999, 12, 31 )
		|where ( Balances.PaymentBalance - Balances.AmountBalance ) > 0
		|or Balances.OverpaymentBalance > 0
		|order by Balances.Document.Date
		|";
	endif;
	q = new Query ( s );
	q.SetParameter ( "Contract", Object.Contract );
	q.SetParameter ( "Orders", list );
	q.SetParameter ( "Date", Periods.GetBalanceDate ( Object ) );
	SetPrivilegedMode ( true );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction 

&AtServer
Function GetOrders ( Object, Vendor ) export
	
	map = new Map ();
	document = ? ( Vendor, Object.PurchaseOrder, Object.SalesOrder );
	if ( not document.IsEmpty () ) then
		map.Insert ( document );
	endif; 
	tables = new Array ();
	tables.Add ( Object.Items );
	tables.Add ( Object.Services );
	for each table in tables do
		for each row in table do
			document = ? ( Vendor, row.PurchaseOrder, row.SalesOrder );
			if ( not document.IsEmpty () ) then
				map.Insert ( document );
			endif; 
		enddo; 
	enddo; 
	result = new Array ();
	for each item in map do
		result.Add ( item.Key );
	enddo; 
	return result;
	
EndFunction 

&AtServer
Procedure SetPaymentsApplied ( Form ) export
	
	object = Form.Object;
	isOrder = iOrder ( object.Ref );
	if ( not documentReady ( Form ) ) then
		Form.PaymentsApplied = 0;
		if ( isOrder ) then
			Form.Benefit = 0;
		endif;
		return;
	endif;
	if ( object.Posted or isOrder ) then
		data = getDebt ( Object );
		if ( isOrder ) then
			benefit = data.Benefit;
			Form.PaymentsApplied = object.ContractAmount - benefit - data.Debt;
			Form.Benefit = benefit;
		else
			Form.PaymentsApplied = object.ContractAmount - data.Debt;
		endif;
	else
		data = getAdvance ( Object );
		Form.PaymentsApplied = Min ( data.Advance, object.ContractAmount );
	endif;

EndProcedure

Function iOrder ( Ref )
	
	type = TypeOf ( Ref );
	return type = Type ( "DocumentRef.SalesOrder" )
		or type = Type ( "DocumentRef.PurchaseOrder" );
	
EndFunction

&AtServer
Function documentReady ( Form )
	
	object = Form.Object;
	if ( object.Contract.IsEmpty () ) then
		return false;
	endif;
	ref = object.Ref;
	if ( TypeOf ( ref ) = Type ( "DocumentRef.SalesOrder" ) ) then
		return salesOrderReady ( ref );
	endif;
	return true;
	
EndFunction

&AtServer
Function salesOrderReady ( Ref )
	
	s = "
	|select top 1 1
	|from AccumulationRegister.SalesOrderDebts as Debts
	|where Debts.Recorder = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return not q.Execute ().IsEmpty ();
	
EndFunction

&AtServer
Function getDebt ( Object )
	
	ref = Object.Ref;
	type = TypeOf ( ref );
	q = new Query ();
	if ( iOrder ( ref ) ) then
		if ( type = Type ( "DocumentRef.SalesOrder" ) ) then
			register = "SalesOrderDebts";
			discount = "Discounts";
		elsif ( type = Type ( "DocumentRef.PurchaseOrder" ) ) then
			register = "PurchaseOrderDebts";
			discount = "VendorDiscounts";
		endif;
		s = "select PaymentBalance as Debt, isnull ( Discounts.Amount, 0 ) as Benefit from AccumulationRegister."
		+ register + ".Balance ( , Document = &Document )
		|left join (
		|	select sum ( Discounts.Amount ) as Amount
		|	from (
		|		select Discounts.Amount as Amount
		|		from AccumulationRegister." + discount + " as Discounts
		|		where Discounts.Document = &Document
		|	) as Discounts
		|) as Discounts
		|on true
		|";
	else
		if ( type = Type ( "DocumentRef.Invoice" ) ) then
			register = "InvoiceDebts";
			factor = 1;
		elsif ( type = Type ( "DocumentRef.Return" ) ) then
			register = "InvoiceDebts";
			factor = -1;
		elsif ( type = Type ( "DocumentRef.VendorInvoice" ) ) then
			register = "VendorInvoiceDebts";
			factor = 1;
		elsif ( type = Type ( "DocumentRef.VendorReturn" ) ) then
			register = "VendorInvoiceDebts";
			factor = -1;
		endif;
		s = "select AmountBalance * &Factor as Debt from AccumulationRegister."
		+ register + ".Balance ( , Document = &Document )";
		q.SetParameter ( "Factor", factor );
	endif;
	q.Text = s;
	q.SetParameter ( "Document", ref );
	return Conversion.RowToStructure ( q.Execute ().Unload () );
	
EndFunction

&AtServer
Function getAdvance ( Object )
	
	ref = Object.Ref;
	type = TypeOf ( ref ); 
	if ( type = Type ( "DocumentRef.Invoice" ) ) then
		register = "Debts";
	elsif ( type = Type ( "DocumentRef.VendorInvoice" ) ) then
		register = "VendorDebts";
	elsif ( type = Type ( "DocumentRef.Return" ) ) then
		register = "Debts";
	elsif ( type = Type ( "DocumentRef.VendorReturn" ) ) then
		register = "VendorDebts";
	endif;
	s = "select OverpaymentBalance as Advance from AccumulationRegister."
	+ register + ".Balance ( , Contract = &Contract )";
	q = new Query ( s );
	q.SetParameter ( "Contract", Object.Contract );
	return Conversion.RowToStructure ( q.Execute ().Unload () );
	
EndFunction

Procedure CalcBalanceDue ( Form ) export

	Form.BalanceDue = Form.Object.ContractAmount - Form.PaymentsApplied - appliedDiscount ( Form );
	
EndProcedure

Function appliedDiscount ( Form )
	
	return ? ( iOrder ( Form.Object.Ref ), Form.Benefit, 0 );
	
EndFunction

&AtServer
Procedure SetPaidPercent ( Form ) export
	
	composer = Form.List.SettingsComposer;
	fields = composer.Settings.UserFields.Items;
	percent = fields.Add ( Type ( "DataCompositionUserFieldExpression" ) );
	percent.SetDetailRecordExpression ( "case PaidPercent when 0 then """" else String ( PaidPercent ) + ""%"" end");
	inProgress = fields.Add ( Type ( "DataCompositionUserFieldExpression" ) );
	inProgress.SetDetailRecordExpression ( "not Paid");
	item = composer.FixedSettings.ConditionalAppearance.Items.Add ();
	item.Fields.Items.Add ().Field = new DataCompositionField ( "PaidPercent" );
	set = item.Appearance;
	set.SetParameterValue ( "Text", new DataCompositionField ( percent.DataPath ) );
	set.SetParameterValue ( "Show", new DataCompositionField ( inProgress.DataPath ) );
	
EndProcedure

&AtServer
Procedure SetShippedPercent ( Form ) export
	
	composer = Form.List.SettingsComposer;
	fields = composer.Settings.UserFields.Items;
	percent = composer.Settings.UserFields.Items.Add ( Type ( "DataCompositionUserFieldExpression" ) );
	percent.SetDetailRecordExpression ( "case ShippedPercent when 0 then """" else String ( ShippedPercent ) + ""%"" end");
	inProgress = fields.Add ( Type ( "DataCompositionUserFieldExpression" ) );
	inProgress.SetDetailRecordExpression ( "not Shipped");
	item = composer.FixedSettings.ConditionalAppearance.Items.Add ();
	item.Fields.Items.Add ().Field = new DataCompositionField ( "ShippedPercent" );
	set = item.Appearance;
	set.SetParameterValue ( "Text", new DataCompositionField ( percent.DataPath ) );
	set.SetParameterValue ( "Show", new DataCompositionField ( inProgress.DataPath ) );
	
EndProcedure

&AtClient
Procedure AdjustReference ( Object ) export
	
	Object.Reference = StrConcat ( StrSplit ( Object.Reference, " /:-#" ) );

EndProcedure

&AtClient
Procedure ExtractSeries ( Object ) export
	
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

&AtServer
Procedure CheckQuote ( Fields ) export
	
	documentDate = BegOfDay ( CurrentSessionDate () );
	if ( Fields.DueDate < documentDate ) then
		raise Output.QuoteDueDateLessCurrentDate ( new Structure ( "DueDate", Conversion.DateToString ( Fields.DueDate ) ) );
	endif; 
	if ( Fields.RejectionCause <> null ) then
		raise Output.QuoteRejected ( new Structure ( "Cause", Fields.RejectionCause ) );
	endif; 
	
EndProcedure 

&AtServer
Procedure ApplyCustomer ( Object, Form = undefined ) export
	
	customer = Object.Customer;
	company = Object.Company;
	data = AccountsMap.Organization ( customer, company, "CustomerAccount" );
	Object.CustomerAccount = data.CustomerAccount;
	data = DF.Values ( customer, "CustomerContract, CustomerContract.Company as Company, VATUse" );
	if ( data.Company = company ) then
		Object.Contract = data.CustomerContract;
	endif; 
	Object.VATUse = data.VATUse;
	InvoiceForm.ApplyContract ( Object, Form );
	InvoiceForm.ApplyVATUse ( Object, Form );
	
EndProcedure

&AtServer
Procedure ApplyContract ( Object, Form ) export
	
	data = DF.Values ( Object.Contract,
		"CustomerPrices, Currency, CustomerAdvances, CustomerRateType, CustomerRate, CustomerFactor" );
	Object.CloseAdvances = data.CustomerAdvances;
	Object.Currency = data.Currency;
	if ( data.CustomerRateType = Enums.CurrencyRates.Fixed
		and data.CustomerRate <> 0 ) then
		rates = new Structure ( "Rate, Factor", data.CustomerRate, data.CustomerFactor );
	else
		rates = CurrenciesSrv.Get ( data.Currency, Object.Date );
	endif;
	Object.Rate = rates.Rate;
	Object.Factor = rates.Factor;
	Object.Prices = data.CustomerPrices;
	updateContent ( Object );
	if ( Form = undefined ) then
		InvoiceForm.UpdateTotals ( Object );
	else
		Form.ContractCurrency = Object.Currency;
		InvoiceForm.SetCurrencyList ( Form );
		InvoiceForm.UpdateTotals ( Form );
		InvoiceForm.UpdateBalanceDue ( Form );
		Constraints.ShowSales ( Form );
		Appearance.Apply ( Form, "Object.Currency" );
	endif;

EndProcedure

&AtServer
Procedure updateContent ( Object ) export
	
	if ( Object.Shipment = undefined ) then
		reloadTables ( Object );
		DiscountsTable.Load ( Object );
	endif;
	InvoiceForm.SetPayment ( Object );
	
EndProcedure 

&AtServer
Procedure reloadTables ( Object )
	
	table = FillerSrv.GetData ( InvoiceForm.FillingParams ( Object ) );
	if ( table.Count () > 0 ) then
		loadSalesOrders ( Object, table, true );
	endif; 
	
EndProcedure 

&AtServer
Function FillingParams ( Object ) export
	
	p = Filler.GetParams ();
	p.Report = "SalesOrderItems";
	p.Filters = getFilters ( Object );
	p.ProposeClearing = Object.SalesOrder.IsEmpty ();
	return p;
	
EndFunction

&AtServer
Function getFilters ( Object )
	
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
Procedure LoadSalesOrders ( Object, Table, Clean ) export
	
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

Procedure UpdateTotals ( Source, Row = undefined, CalcVAT = true ) export

	clientForm = TypeOf ( Source ) = Type ( "ClientApplicationForm" );
	object = ? ( clientForm, Source.Object, Source );
	if ( Row <> undefined ) then
		Computations.Total ( Row, object.VATUse, CalcVAT );
	endif;
	InvoiceForm.CalcTotals ( Source );
	if ( clientForm ) then
		InvoiceForm.CalcBalanceDue ( Source );
		Appearance.Apply ( Source, "BalanceDue" );
	endif;

EndProcedure 

&AtServer
Procedure ApplyVATUse ( Object, Form ) export

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
	DiscountsTable.RecalcVAT ( Object );
	if ( Form <> undefined ) then
		Appearance.Apply ( Form, "Object.VATUse" );
	endif;

EndProcedure

&AtServer
Procedure UpdateBalanceDue ( Form ) export

	InvoiceForm.SetPaymentsApplied ( Form );
	InvoiceForm.CalcBalanceDue ( Form );
	Appearance.Apply ( Form, "BalanceDue" );

EndProcedure

Procedure ApplyItem ( Row, Source ) export
	
	clientForm = TypeOf ( Source ) = Type ( "ClientApplicationForm" );
	object = ? ( clientForm, Source.Object, Source );
	p = new Structure ();
	p.Insert ( "Date", object.Date );
	p.Insert ( "Company", object.Company );
	p.Insert ( "Organization", object.Customer );
	p.Insert ( "Contract", object.Contract );
	p.Insert ( "Warehouse", InvoiceForm.GetWarehouse ( Row, object ) );
	p.Insert ( "Currency", object.Currency );
	p.Insert ( "Item", Row.Item );
	p.Insert ( "Prices", object.Prices );
	data = InvoiceFormSrv.GetItemData ( p );
	Row.Package = data.Package;
	Row.Capacity = data.Capacity;
	Row.Price = data.Price;
	Row.VATCode = data.VAT;
	Row.VATRate = data.Rate;
	Row.VATAccount = data.VATAccount;
	Row.Account = data.Account;
	Row.SalesCost = data.SalesCost;
	Row.Income = data.Income;
	Row.ProducerPrice = data.ProducerPrice;
	Row.Social = data.Social;
	Computations.Units ( Row );
	Computations.Discount ( Row );
	Computations.Amount ( Row );
	Computations.ExtraCharge ( Row );
	InvoiceForm.UpdateTotals ( Source, Row );
	
EndProcedure

Function GetWarehouse ( Row, Object ) export
	
	return ? ( Row.Warehouse.IsEmpty (), Object.Warehouse, Row.Warehouse );
	
EndFunction 

Function ItemParams ( val Item, val Package, val Feature = undefined ) export

	p = new Structure ();
	p.Insert ( "Item", Item );
	p.Insert ( "Package", Package );
	p.Insert ( "Feature", Feature );
	return p;

EndFunction

Procedure ApplyItemsQuantityPkg ( Row, Source ) export
	
	Computations.Units ( Row );
	Computations.Discount ( Row );
	Computations.Amount ( Row );
	Computations.ExtraCharge ( Row );
	InvoiceForm.UpdateTotals ( Source, Row );

EndProcedure

Procedure ApplyService ( Row, Source ) export
	
	clientForm = TypeOf ( Source ) = Type ( "ClientApplicationForm" );
	object = ? ( clientForm, Source.Object, Source );
	p = new Structure ();
	p.Insert ( "Date", object.Date );
	p.Insert ( "Company", object.Company );
	p.Insert ( "Organization", object.Customer );
	p.Insert ( "Contract", object.Contract );
	p.Insert ( "Warehouse", object.Warehouse );
	p.Insert ( "Currency", object.Currency );
	p.Insert ( "Item", Row.Item );
	p.Insert ( "Prices", object.Prices );
	data = InvoiceFormSrv.GetServiceData ( p );
	Row.Price = data.Price;
	Row.Description = data.FullDescription;
	Row.VATCode = data.VAT;
	Row.VATRate = data.Rate;
	Row.VATAccount = data.VATAccount;
	Row.Income = data.Income;
	Computations.Discount ( Row );
	Computations.Amount ( Row );
	InvoiceForm.UpdateTotals ( Source, Row );
	
EndProcedure 

Procedure ApplyServicesQuantity ( Row, Source ) export
	
	Computations.Discount ( Row );
	Computations.Amount ( Row );
	InvoiceForm.UpdateTotals ( Source, Row );
	
EndProcedure
