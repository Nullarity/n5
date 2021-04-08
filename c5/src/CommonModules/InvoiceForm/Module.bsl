&AtServer
Procedure SetContractCurrency ( Form ) export
	
	object = Form.Object;
	Form.ContractCurrency = DF.Pick ( object.Contract, "Currency" );
	
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
	if ( Form.ContractCurrency = Form.LocalCurrency ) then
		currency = object.Currency;
	else
		currency = Form.ContractCurrency;
	endif; 
	rates = CurrenciesSrv.Get ( currency );
	object.Rate = rates.Rate;
	object.Factor = rates.Factor;
	
EndProcedure 

Procedure CalcTotals ( Object ) export
	
	items = Object.Items;
	services = Object.Services;
	amount = items.Total ( "Total" ) + services.Total ( "Total" );
	Object.VAT = items.Total ( "VAT" ) + services.Total ( "VAT" );
	Object.Amount = amount;
	Object.Discount = items.Total ( "Discount" ) + services.Total ( "Discount" );
	Object.GrossAmount = amount - ? ( Object.VATUse = 2, Object.VAT, 0 ) + Object.Discount;
	
EndProcedure 

&AtServer
Procedure SetPayment ( Object ) export
	
	vendor = isPurchase ( Object );
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
Function isPurchase ( Object )
	
	return TypeOf ( Object.Ref ) = Type ( "DocumentRef.VendorInvoice" );
	
EndFunction 

&AtServer
Function getPaymentOption ( Object, Vendor )
	
	if ( Vendor ) then
		terms = "VendorTerms";
		register = "VendorDebts";
	else
		terms = "CustomerTerms";
		register = "Debts";
	endif; 
	list = getOrders ( Object, Vendor );
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
Function getOrders ( Object, Vendor )
	
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
Procedure SetDiscounts ( Object ) export
		
	vendor = isPurchase ( Object );
	table = getDiscounts ( Object, vendor );
	Object.Discounts.Load ( table );
	
EndProcedure

&AtServer
Function getDiscounts ( Object, Vendor )
	
	if ( Vendor ) then
		document = "PurchaseOrder";
		invoice = "VendorInvoice";
		payment = "VendorPayment";
		register = "VendorDebts";
	else
		document = "SalesOrder";
		invoice = "Invoice";
		payment = "Payment";
		register = "Debts";
	endif; 
	s = "
	|select Discounts.Document as " + document + ", sum ( Discounts.Discount ) as Discount
	|from (
	|	select Debts.Document as Document, - Debts.Payment as Discount
	|	from AccumulationRegister." + register + " as Debts
	|	where Debts.Document in ( &Orders )
	|	and Debts.Recorder refs Document." + payment + "
	|	and Debts.Payment < 0
	|	and Debts.Period < &Date
	|	union all
	|	select Discounts." + document + ", - Discounts.Discount
	|	from Document." + invoice + ".Discounts as Discounts
	|	where Discounts.Ref <> &Ref
	|	and Discounts.Ref.Contract = &Contract
	|	and Discounts." + document + " in ( &Orders )
	|	and Discounts.Ref.Posted
	|	) as Discounts
	|group by Discounts.Document
	|having sum ( Discounts.Discount ) > 0
	|order by Discounts.Document.Date
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	q.SetParameter ( "Contract", Object.Contract );
	q.SetParameter ( "Date", Periods.GetDocumentDate ( Object ) );
	q.SetParameter ( "Orders", getOrders ( Object, Vendor ) );
	SetPrivilegedMode ( true );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Procedure SetPaymentsApplied ( Form ) export
	
	if ( not documentReady ( Form ) ) then
		Form.PaymentsApplied = 0;
		Form.Benefit = 0;
		return;
	endif;
	object = Form.Object;
	type = TypeOf ( object.Ref );
	if ( object.Posted
		or type = Type ( "DocumentRef.SalesOrder" )
		or type = Type ( "DocumentRef.PurchaseOrder" ) ) then
		data = getDebt ( Object );
		benefit = data.Benefit;
		Form.PaymentsApplied = object.Amount - benefit - data.Debt;
		Form.Benefit = benefit;
	else
		data = getAdvance ( Object );
		Form.PaymentsApplied = Min ( data.Advance, object.Amount );
		Form.Benefit = data.Benefit;
	endif;

EndProcedure

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
	if ( type = Type ( "DocumentRef.SalesOrder" ) ) then
		register = "SalesOrderDebts";
		discount = "Discounts";
		resource = "Payment";
		factor = 1;
	elsif ( type = Type ( "DocumentRef.PurchaseOrder" ) ) then
		register = "PurchaseOrderDebts";
		discount = "VendorDiscounts";
		resource = "Payment";
		factor = 1;
	elsif ( type = Type ( "DocumentRef.Invoice" ) ) then
		register = "InvoiceDebts";
		discount = "Discounts";
		resource = "Amount";
		factor = 1;
	elsif ( type = Type ( "DocumentRef.Return" ) ) then
		register = "InvoiceDebts";
		discount = "Discounts";
		resource = "Amount";
		factor = -1;
	elsif ( type = Type ( "DocumentRef.VendorInvoice" ) ) then
		register = "VendorInvoiceDebts";
		discount = "VendorDiscounts";
		resource = "Amount";
		factor = 1;
	elsif ( type = Type ( "DocumentRef.VendorReturn" ) ) then
		register = "VendorInvoiceDebts";
		discount = "VendorDiscounts";
		resource = "Amount";
		factor = -1;
	endif;
	s = "select " + resource + "Balance as Amount, isnull ( Discounts.AmountTurnover, 0 ) as Benefit from AccumulationRegister."
		+ register + ".Balance ( , Document = &Document )
		|left join AccumulationRegister." + discount + ".Turnovers ( , , , Document = &Document ) as Discounts
		|on true";
	q = new Query ( s );
	q.SetParameter ( "Document", ref );
	table = q.Execute ().Unload ();
	result = new Structure ( "Debt, Benefit", 0, 0 );
	if ( table.Count () > 0 ) then
		row = table [ 0 ];
		result.Debt = row.Amount * factor;
		result.Benefit = row.Benefit;
	endif;
	return result;
	
EndFunction

&AtServer
Function getAdvance ( Object )
	
	ref = Object.Ref;
	type = TypeOf ( ref ); 
	if ( type = Type ( "DocumentRef.Invoice" )
		or type = Type ( "DocumentRef.Return" ) ) then
		register = "Debts";
		orderRegister = "SalesOrderDebts";
		discount = "Discounts";
		order = ? ( type = Type ( "DocumentRef.Invoice" ), Object.SalesOrder, undefined );
	elsif ( type = Type ( "DocumentRef.VendorInvoice" )
	 	or type = Type ( "DocumentRef.VendorReturn" ) ) then
		register = "VendorDebts";
		orderRegister = "PurchaseOrderDebts";
		discount = "VendorDiscounts";
		order = ? ( type = Type ( "DocumentRef.VendorInvoice" ), Object.PurchaseOrder, undefined );
	endif;
	if ( order = undefined
		or order.IsEmpty () ) then
		s = "select OverpaymentBalance as Amount, 0 as Benefit from AccumulationRegister."
			+ register + ".Balance ( , Contract = &Contract )";
	else
		s = "select OverpaymentBalance as Amount, isnull ( Discounts.AmountTurnover, 0 ) as Benefit from AccumulationRegister."
			+ orderRegister + ".Balance ( , Document = &Order )
			|left join AccumulationRegister." + discount + ".Turnovers ( , , , Document = &Order ) as Discounts
			|on true";
	endif;
	q = new Query ( s );
	q.SetParameter ( "Contract", Object.Contract );
	q.SetParameter ( "Order", order );
	table = q.Execute ().Unload ();
	result = new Structure ( "Advance, Benefit", 0, 0 );
	if ( table.Count () > 0 ) then
		row = table [ 0 ];
		result.Advance = row.Amount;
		result.Benefit = row.Benefit;
	endif;
	return result;
	
EndFunction

Procedure CalcBalanceDue ( Form ) export

	object = Form.Object;
	Form.BalanceDue = object.Amount - Form.PaymentsApplied - Form.Benefit;
	
EndProcedure

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