Function FromInvoice ( Env ) export

	setContext ( Env );
	initVars ( Env );
	if ( Env.Fields.ContractAmount = 0 ) then
		clearRecords ( Env );
		return true;
	endif; 
	PaymentDetails.Init ( Env );
	lockPayments ( Env );
	getPayments ( Env );
	if ( Env.Return ) then
		closeDebts ( Env );
	endif;
	if ( Env.Fields.CloseAdvances ) then
		closeOverpayments ( Env );
	endif;
	if ( not Env.Return
		and Env.OrderExists ) then
		if ( not detailPayments ( Env ) ) then
			return false;
		endif; 
	endif;
	addDebt ( Env );
	PaymentDetails.Save ( Env );
	return true;
	
EndFunction

Procedure setContext ( Env )
	
	type = Env.Type; 
	if ( type = Type ( "DocumentRef.Invoice" ) ) then
		Env.Insert ( "PaymentsRegister", "Debts" );
		Env.Insert ( "OrderExists", Env.SalesOrderExists );
		Env.Insert ( "OrderName", "SalesOrder" );
		Env.Insert ( "ReverseVAT", not Env.Fields.AdvancesMonthly );
		Env.Insert ( "Return", false );
	elsif ( type = Type ( "DocumentRef.VendorInvoice" ) ) then
		Env.Insert ( "PaymentsRegister", "VendorDebts" );
		Env.Insert ( "OrderExists", Env.PurchaseOrderExists );
		Env.Insert ( "OrderName", "PurchaseOrder" );	
		Env.Insert ( "ReverseVAT", false );
		Env.Insert ( "Return", false );
	elsif ( type = Type ( "DocumentRef.Return" ) ) then
		Env.Insert ( "PaymentsRegister", "Debts" );
		Env.Insert ( "OrderExists", Env.SalesOrderExists );
		Env.Insert ( "OrderName", "SalesOrder" );	
		Env.Insert ( "ReverseVAT", false );
		Env.Insert ( "Return", true );
	elsif ( type = Type ( "DocumentRef.VendorReturn" ) ) then
		Env.Insert ( "PaymentsRegister", "VendorDebts" );
		Env.Insert ( "OrderExists", Env.PurchaseOrderExists );
		Env.Insert ( "OrderName", "PurchaseOrder" );
		Env.Insert ( "ReverseVAT", not Env.Fields.AdvancesMonthly );
		Env.Insert ( "Return", true );
	elsif ( type = Type ( "DocumentRef.CustomsDeclaration" ) ) then
		Env.Insert ( "PaymentsRegister", "VendorDebts" );
		Env.Insert ( "OrderExists", false );
		Env.Insert ( "ReverseVAT", false );
		Env.Insert ( "Return", false );
	endif;
	Env.Insert ( "NewPaymentDate", Env.Fields.PaymentDate <> Date ( 3999, 12, 31 ) );
	
EndProcedure

Procedure initVars ( Env )
	
	if ( Env.PaymentsRegister = "Debts" ) then
		Env.Insert ( "OrderName", "SalesOrder" );
	else
		Env.Insert ( "OrderName", "PurchaseOrder" );	
	endif;
	
EndProcedure

Procedure clearRecords ( Env )
	
	Env.Registers [ Env.PaymentsRegister ].Clear ();
	
EndProcedure 

Procedure lockPayments ( Env )
	
	lock = new DataLock ();
	item = lock.Add ( "AccumulationRegister." + Env.PaymentsRegister );
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Contract", Env.Fields.Contract );
	lock.Lock ();
	
EndProcedure

Procedure closeOverpayments ( Env )
	
	table = closeResource ( Env, Env.Overpayments );
	if ( table.Count () = 0 ) then
		return;
	endif;
	fields = Env.Fields;
	commitAdvances = not fields.AdvancesMonthly;
	if ( commitAdvances ) then
		payments = paymentsTable ();
	endif;
	date = fields.Date;
	contract = fields.Contract;
	recordset = Env.Registers [ Env.PaymentsRegister ];
	isReturn = Env.Return;
	for each row in table do
		if ( isReturn ) then
			movement = recordset.AddReceipt ();
		else
			movement = recordset.AddExpense ();
		endif;
		movement.Period = date;
		movement.Contract = contract;
		movement.Document = row.Document;
		movement.PaymentKey = row.PaymentKey;
		movement.Detail = row.Detail;
		movement.Overpayment = row.Amount;
		if ( commitAdvances ) then
			registerOverpayment ( payments, movement );
		endif;
	enddo; 
	if ( commitAdvances ) then
		commitOverpayment ( Env, payments );
	endif;
	
EndProcedure

Function closeResource ( Env, Table )
	
	p = new Structure ();
	if ( not Env.Return ) then
		p.Insert ( "OptionalFilterColumns", "Document" );
	endif;
	p.Insert ( "KeyColumn", "Amount" );
	p.Insert ( "DecreasingColumns2", "Amount" );
	result = CollectionsSrv.Decrease ( Table, Env.Documents, p );
	return result;
	
EndFunction

Function paymentsTable ()
	
	table = new ValueTable ();
	columns = table.Columns;
	columns.Add ( "Payment" );
	columns.Add ( "Amount", new TypeDescription ( "Number" ) );
	return table;

EndFunction

Procedure closeDebts ( Env )
	
	table = closeResource ( Env, Env.Debts );
	if ( table.Count () = 0 ) then
		return;
	endif;
	fields = Env.Fields;
	date = fields.Date;
	contract = fields.Contract;
	recordset = Env.Registers [ Env.PaymentsRegister ];
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		movement.Contract = contract;
		movement.PaymentKey = row.PaymentKey;
		movement.Document = row.Document;
		movement.Detail = row.Detail;
		amount = - row.Amount;
		movement.Amount = amount;
		movement.Payment = amount;
	enddo; 
	
EndProcedure

Function detailPayments ( Env )
	
	recordset = Env.Registers [ Env.PaymentsRegister ];
	date = Env.Fields.Date;
	contract = Env.Fields.Contract;
	ref = Env.Ref;
	table = closeResource ( Env, Env.Payments );
	if ( unexpectedPayments ( Env ) ) then
		return false;
	endif;
	for each row in table do
		amount = row.Amount;
		if ( row.PaymentDate <= date ) then
			Output.PaymentExpired ( new Structure ( "Option, Amount", row.Option, Conversion.NumberToMoney ( amount, Env.Fields.Currency ) ), , ref );
			return false;
		endif; 
		bill = Min ( amount, row.Bill );
		document = row.Document;
		paymentKey = row.PaymentKey;
		movement = recordset.Add ();
		movement.Period = date;
		movement.Contract = contract;
		movement.Document = document;
		movement.PaymentKey = paymentKey;
		movement.Payment = - amount;
		movement.Bill = - bill;
		movement = recordset.Add ();
		movement.Period = date;
		movement.Contract = contract;
		movement.Document = document;
		if ( Env.NewPaymentDate ) then
			movement.PaymentKey = getPaymentKey ( Env );
		else
			movement.PaymentKey = paymentKey;
		endif; 
		movement.Detail = ref;
		movement.Amount = amount;
		movement.Payment = amount;
		movement.Bill = bill;
	enddo; 
	return true;
	
EndFunction

Function unexpectedPayments ( Env )
	
	unexpected = false;
	ref = Env.Ref;
	currency = Env.Fields.ContractCurrency;
	for each row in Env.Documents do
		if ( row.Document = undefined ) then
			continue;
		endif;
		Output.UnexpectedPayments ( new Structure ( "Document, Amount",
			row.Document, Conversion.NumberToMoney ( row.Amount, currency ) ), , ref );
		unexpected = true;
	enddo;
	return unexpected;
	
EndFunction

Function getPaymentKey ( Env )
	
	fields = Env.Fields;
	if ( fields.PaymentKey = null ) then
		Env.PaymentDetails.Option = fields.PaymentOption;
		Env.PaymentDetails.Date = fields.PaymentDate;
		paymentKey = PaymentDetails.GetKey ( Env );
	else
		paymentKey = fields.PaymentKey;
	endif; 
	return paymentKey;
		
EndFunction 

Procedure addDebt ( Env )
	
	recordset = Env.Registers [ Env.PaymentsRegister ];
	date = Env.Fields.Date;
	ref = Env.Ref;
	reverse = ? ( Env.Return, -1, 1 );
	for each row in Env.Documents do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Contract = Env.Fields.Contract;
		amount = reverse * row.Amount;
		movement.Amount = amount;
		movement.Payment = amount;
		document = row.Document;
		details = ValueIsFilled ( document );
		if ( details ) then
			movement.Document = document;
			movement.Detail = ref;
		else
			movement.Document = ref;
		endif; 
		movement.PaymentKey = getPaymentKey ( Env );
	enddo; 

EndProcedure

Procedure registerOverpayment ( Payments, Record )
	
	list = new Array ();
	list.Add ( Record.Document );
	list.Add ( Record.Detail );
	types = new Array ();
	types.Add ( Type ( "DocumentRef.Payment" ) );
	types.Add ( Type ( "DocumentRef.VendorPayment" ) );
	types.Add ( Type ( "DocumentRef.Refund" ) );
	types.Add ( Type ( "DocumentRef.VendorRefund" ) );
	for each document in list do
		if ( types.Find ( TypeOf ( document ) ) <> undefined ) then
			row = Payments.Add ();
			row.Payment = document;
			row.Amount = Record.Overpayment;
			break;
		endif;
	enddo;
	
EndPRocedure

Procedure commitOverpayment ( Env, Payments )
	
	p = GeneralRecords.GetParams ();
	p.Recordset = Env.Registers.General;
	fields = Env.Fields;
	type = Env.Type;
	if ( type = Type ( "DocumentRef.Invoice" ) ) then
		debtor = true;
		p.AccountCr = fields.CustomerAccount;
		organization = fields.Customer;
	elsif ( type = Type ( "DocumentRef.Return" ) ) then
		debtor = false;
		p.AccountDr = fields.CustomerAccount;
		organization = fields.Customer;
	elsif ( type = Type ( "DocumentRef.VendorReturn" ) ) then
		debtor = true;
		p.AccountCr = fields.VendorAccount;
		organization = fields.Vendor;
	elsif ( type = Type ( "DocumentRef.VendorInvoice" )
		or type = Type ( "DocumentRef.CustomsDeclaration" ) ) then
		debtor = false;
		p.AccountDr = fields.VendorAccount;
		organization = fields.Vendor;
	endif;
	p.DimDr1 = organization;
	p.DimCr1 = organization;
	contract = fields.Contract;
	p.DimDr2 = contract;
	p.DimCr2 = contract;
	date = fields.Date;
	p.Date = date;
	p.Company = fields.Company;
	currency = fields.ContractCurrency;
	p.CurrencyDr = currency;
	p.CurrencyCr = currency;
	operationAdvance = String ( Enums.Operations.AdvanceApplied ) + ": ";
	operationVAT = String ( Enums.Operations.VATAdvancesReverse ) + ": ";
	localCurrency = fields.LocalCurrency;
	rate = fields.Rate;
	factor = fields.factor;
	Payments.GroupBy ( "Payment", "Amount" );
	reverseVAT = Env.ReverseVAT;
	paymentFields = "AdvanceAccount";
	if ( reverseVAT ) then
		paymentFields = paymentFields + ", VATAccount, VATAdvance.Rate as VAT, ReceivablesVATAccount";
	endif;
	for each row in Payments do
		payment = row.Payment;
		data = DF.Values ( payment, paymentFields );
		if ( debtor ) then
			p.AccountDr = data.AdvanceAccount;
		else
			p.AccountCr = data.AdvanceAccount;
		endif;
		overpayment = row.Amount;
		p.CurrencyAmountDr = overpayment;
		p.CurrencyAmountCr = overpayment;
		p.Amount = Currencies.Convert ( overpayment, currency, localCurrency, date, rate, factor );
		p.Operation = Enums.Operations.AdvanceApplied;
		p.Content = operationAdvance + payment;
		reverse = reverseVAT and data.VAT <> 0;
		if ( reverse ) then
			p.Dependency = payment;
		endif;
		GeneralRecords.Add ( p );
		if ( reverse ) then
			p.AccountDr = data.ReceivablesVATAccount;
			p.AccountCr = data.VATAccount;
			vatAmount = - overpayment + overpayment * ( 100 / ( 100 + data.VAT ) );
			p.Amount = Currencies.Convert ( vatAmount, currency, localCurrency, fields.Date, rate, factor );
			p.Operation = Enums.Operations.VATAdvancesReverse;
			p.Content = operationVAT + payment; 
			GeneralRecords.Add ( p );
		endif;
	enddo;
	
EndProcedure

Procedure FromOrder ( Env ) export

	if ( Env.Type = Type ( "DocumentRef.SalesOrder" ) ) then
		recordset = Env.Registers.Debts;
	else
		recordset = Env.Registers.VendorDebts;
	endif; 
	PaymentDetails.Init ( Env );
	table = SQL.Fetch ( Env, "$Payments" );
	fields = Env.Fields;
	date = fields.Date;
	ref = Env.Ref;
	contract = fields.Contract;
	details = Env.PaymentDetails;
	fixAmount ( fields.ContractAmount, table );
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		movement.Contract = contract;
		movement.Document = ref;
		paymentKey = row.PaymentKey;
		if ( paymentKey = null ) then
			details.Option = row.Option;
			details.Date = row.PaymentDate;
			paymentKey = PaymentDetails.GetKey ( Env );
		endif; 
		movement.PaymentKey = paymentKey;
		movement.Payment = row.Amount;
	enddo; 
	PaymentDetails.Save ( Env );
	
EndProcedure

Procedure fixAmount ( ContractAmount, Payments )
	
	row = Payments [ Payments.Count () - 1 ];
	row.Amount = row.Amount + ( ContractAmount - row.Amount );
	
EndProcedure

Procedure getPayments ( Env )
	
	sqlDocuments ( Env );
	sqlPayments ( Env );
	if ( Env.Return ) then
		sqlDebts ( Env );
	endif;
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Option", fields.PaymentOption );
	q.SetParameter ( "Contract", fields.Contract );
	q.SetParameter ( "Return", ? ( Env.Return, -1, 1 ) );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlDocuments ( Env )
	
	type = Env.Type;
	if ( type = Type ( "DocumentRef.Invoice" ) ) then
		s = "
		|select Documents.Document as Document, sum ( Documents.Amount ) as Amount
		|into Documents
		|from (
		|	select case Items.SalesOrder when value ( Document.SalesOrder.EmptyRef ) then undefined else Items.SalesOrder end as Document,
		|		Items.ContractAmount + Items.ContractVAT as Amount
		|	from Items as Items
		|	union all
		|	select case Services.SalesOrder when value ( Document.SalesOrder.EmptyRef ) then undefined else Services.SalesOrder end,
		|		Services.ContractAmount + Services.ContractVAT
		|	from Services as Services
		|) as Documents
		|group by Documents.Document
		|index by Document
		|;
		|// #Documents
		|select Documents.Amount as Amount, Documents.Document as Document
		|from Documents as Documents
		|";
	elsif ( type = Type ( "DocumentRef.VendorInvoice" ) ) then
		s = "
		|select Documents.Document as Document, sum ( Documents.Amount ) as Amount
		|into Documents
		|from (
		|	select case Items.PurchaseOrder when value ( Document.PurchaseOrder.EmptyRef ) then undefined else Items.PurchaseOrder end as Document,
		|		Items.ContractAmount + Items.ContractVAT as Amount
		|	from Items as Items
		|	union all
		|	select case Services.PurchaseOrder when value ( Document.PurchaseOrder.EmptyRef ) then undefined else Services.PurchaseOrder end,
		|		Services.ContractAmount + Services.ContractVAT
		|	from Services as Services
		|	union all
		|	select undefined, FixedAssets.ContractAmount + FixedAssets.ContractVAT
		|	from FixedAssets as FixedAssets
		|	union all
		|	select undefined, IntangibleAssets.ContractAmount + IntangibleAssets.ContractVAT
		|	from IntangibleAssets as IntangibleAssets
		|	union all
		|	select undefined, Accounts.ContractAmount + Accounts.ContractVAT
		|	from Accounts as Accounts
		|) as Documents
		|group by Documents.Document
		|index by Document
		|;
		|// #Documents
		|select Documents.Amount as Amount, Documents.Document as Document
		|from Documents as Documents
		|";
	elsif ( type = Type ( "DocumentRef.Return" ) ) then
		s = "
		|select Documents.Document as Document, Documents.Detail as Detail, sum ( Documents.Amount ) as Amount
		|into Documents
		|from (
		|	select Items.SalesOrder as Document, Items.Invoice as Detail, Items.ContractAmount + Items.ContractVAT as Amount
		|	from Items as Items
		|	where Items.SalesOrder <> value ( Document.SalesOrder.EmptyRef )
		|	union all
		|	select Items.Invoice, undefined, Items.ContractAmount + Items.ContractVAT as Amount
		|	from Items as Items
		|	where Items.SalesOrder = value ( Document.SalesOrder.EmptyRef )
		|) as Documents
		|group by Documents.Document, Documents.Detail
		|index by Document, Detail
		|;
		|// #Documents
		|select Documents.Amount as Amount, Documents.Document as Document, Documents.Detail as Detail
		|from Documents as Documents
		|";
	elsif ( type = Type ( "DocumentRef.VendorReturn" ) ) then
		s = "// #Documents
		|select Documents.Document as Document, Documents.Detail as Detail, sum ( Documents.Amount ) as Amount
		|into Documents
		|from (
		|	select Items.PurchaseOrder as Document, Items.VendorInvoice as Detail, Items.ContractAmount + Items.ContractVAT as Amount
		|	from Items as Items
		|	where Items.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
		|	union all
		|	select Items.VendorInvoice, undefined, Items.ContractAmount + Items.ContractVAT
		|	from Items as Items
		|	where Items.PurchaseOrder = value ( Document.PurchaseOrder.EmptyRef )
		|	union all
		|	select FixedAssets.VendorInvoice, undefined, FixedAssets.ContractAmount + FixedAssets.ContractVAT
		|	from FixedAssets as FixedAssets
		|	union all
		|	select IntangibleAssets.VendorInvoice, undefined, IntangibleAssets.ContractAmount + IntangibleAssets.ContractVAT
		|	from IntangibleAssets as IntangibleAssets
		|	union all
		|	select Accounts.VendorInvoice, undefined, Accounts.ContractAmount + Accounts.ContractVAT
		|	from Accounts as Accounts
		|) as Documents
		|group by Documents.Document, Documents.Detail
		|;
		|// #Documents
		|select Documents.Amount as Amount, Documents.Document as Document, Documents.Detail as Detail
		|from Documents as Documents
		|";
	elsif ( type = Type ( "DocumentRef.CustomsDeclaration" ) ) then
		s = "// #Documents
		|select sum ( Documents.Amount ) as Amount, undefined as Document
		|from ( select Charges.Amount as Amount
		|		from Charges as Charges ) as Documents
		|";
	endif;
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlPayments ( Env )
	
	orderExists = Env.OrderExists;
	advances = Env.Fields.CloseAdvances;
	orderName = Env.OrderName;
	s = "
	|select Debts.Document as Document, Debts.Detail as Detail, Debts.PaymentKey as PaymentKey,
	|	&Return * Debts.PaymentBalance as Payment, &Return * Debts.OverpaymentBalance as Overpayment,
	|	&Return * Debts.BillBalance as Bill, Debts.Document.Date as Date, Details.Date as PaymentDate,
	|	Details.Option as Option
	|into Debts
	|from AccumulationRegister." + Env.PaymentsRegister + ".Balance ( &Timestamp, Contract = &Contract
	|	and ( not Document refs Document." + orderName;
	if ( orderExists ) then
		s = s + " or Document in ( select Document from Documents where Document <> value ( Document."
			+ orderName + ".EmptyRef ) )";
	endif; 
	s = s + " ) ) as Debts
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.PaymentDetails as Details
	|	on Details.PaymentKey = Debts.PaymentKey
	|where &Return * Debts.PaymentBalance > 0
	|";
	if ( advances ) then
		s = s + "
		|or &Return * Debts.OverpaymentBalance > 0
		|";
	endif;
	if ( orderExists ) then
		s = s + "
		|;
		|// #Payments
		|select Debts.Document as Document, Debts.PaymentKey as PaymentKey, Debts.Payment as Amount, Debts.Bill as Bill,
		|	Debts.PaymentDate as PaymentDate, Debts.Option as Option
		|from Debts
		|where Debts.Detail = undefined
		|and Debts.Payment > 0
		|and Debts.Document refs Document." + orderName + "
		|order by Debts.Date desc, Debts.PaymentDate desc
		|";
	endif;
	if ( advances ) then
		s = s + "
		|;
		|// #Overpayments
		|select Debts.Document as Document, Debts.Detail as Detail, Debts.PaymentKey as PaymentKey,
		|	Debts.Overpayment as Amount
		|from Debts as Debts
		|where Debts.Overpayment > 0
		|order by Debts.Date desc, Debts.PaymentDate desc
		|";
	endif;
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlDebts ( Env )
	
	s = "
	|// #Debts
	|select Debts.Document as Document, Debts.Detail as Detail, Debts.PaymentKey as PaymentKey,
	|	Debts.AmountBalance as Amount
	|from AccumulationRegister." + Env.PaymentsRegister + ".Balance ( &Timestamp,
	|	Contract = &Contract
	|	and ( Document, Detail ) in ( select Document, Detail from Documents ) ) as Debts
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure SyncRecords ( Debts ) export
	
	invoices = new Array ();
	if ( TypeOf ( Debts ) = Type ( "AccumulationRegisterRecordSet.Debts" ) ) then
		invoicesRegister = AccumulationRegisters.InvoiceDebts.CreateRecordSet ();
		ordersRegister = AccumulationRegisters.SalesOrderDebts.CreateRecordSet ();
		order = Type ( "DocumentRef.SalesOrder" );
		invoices.Add ( Type ( "DocumentRef.Invoice" ) );
		invoices.Add ( Type ( "DocumentRef.Return" ) );
	else
		invoicesRegister = AccumulationRegisters.VendorInvoiceDebts.CreateRecordSet ();
		ordersRegister = AccumulationRegisters.PurchaseOrderDebts.CreateRecordSet ();
		order = Type ( "DocumentRef.PurchaseOrder" );
		invoices.Add ( Type ( "DocumentRef.VendorInvoice" ) );
		invoices.Add ( Type ( "DocumentRef.VendorReturn" ) );
		invoices.Add ( Type ( "DocumentRef.CustomsDeclaration" ) );
	endif;
	recorder = Debts.Filter.Recorder.Value;
	invoicesRegister.Filter.Recorder.Set ( recorder );
	ordersRegister.Filter.Recorder.Set ( recorder );
	if ( Debts.Count () > 0 ) then
		for each row in groupRecordset ( Debts ) do
			document = row.Document;
			type = TypeOf ( document ); 
			if ( type = order ) then
				syncRecord ( ordersRegister, row, document );
			elsif ( invoices.Find ( type ) <> undefined ) then
				syncRecord ( invoicesRegister, row, document );
			endif;
			detail = row.Detail;
			if ( invoices.Find ( TypeOf ( detail ) ) <> undefined ) then
				syncRecord ( invoicesRegister, row, detail );
			endif;
		enddo;
	endif;
	invoicesRegister.Write ();
	ordersRegister.Write ();
	
EndProcedure

Function groupRecordset ( Recordset )

	table = Recordset.Unload ( , "Period, RecordType, Document, Detail, Amount, Payment, Overpayment, Bill" );
	table.GroupBy ( "Period, RecordType, Document, Detail", "Amount, Payment, Overpayment, Bill" );
	return table;

EndFunction

Procedure syncRecord ( Recordset, Row, Document )
	
	record = Recordset.Add ();
	FillPropertyValues ( record, row, , "Document" );
	record.Document = document;
	
EndProcedure 
