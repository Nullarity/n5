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
	params.CalcServices = type <> Type ( "DocumentRef.Sale" );
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
		Object.PaymentDate = Periods.GetDocumentDate ( Object ) + option.Due * 86400;
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
		|select top 1 Payments.Option as Value, Payments.Option.Due as Due
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
		|select Payments.Option as Value, Payments.Option.Due as Due
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
