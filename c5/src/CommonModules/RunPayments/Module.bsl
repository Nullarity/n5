Function Post ( Env ) export
	
	setContext ( Env );
	getData ( Env );
	makePayments ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure setContext ( Env )
	
	type = Env.Type;
	if ( type = Type ( "DocumentRef.Payment" ) ) then
		Env.Insert ( "Refund", false );
		Env.Insert ( "Customer", true );
		Env.Insert ( "Register", "Debts" );
		Env.Insert ( "Discounts", "Discounts" );
		Env.Insert ( "DiscountDebts", "DiscountDebts" );
		Env.Insert ( "Money", "Dr" );
		Env.Insert ( "Organizations", "Cr" );
	elsif ( type = Type ( "DocumentRef.Refund" ) ) then
		Env.Insert ( "Refund", true );
		Env.Insert ( "Customer", true );
		Env.Insert ( "Register", "Debts" );
		Env.Insert ( "Discounts", "Discounts" );
		Env.Insert ( "DiscountDebts", "DiscountDebts" );
		Env.Insert ( "Money", "Cr" );
		Env.Insert ( "Organizations", "Dr" );
	elsif ( type = Type ( "DocumentRef.VendorRefund" ) ) then
		Env.Insert ( "Refund", true );
		Env.Insert ( "Customer", false );
		Env.Insert ( "Register", "VendorDebts" );
		Env.Insert ( "Discounts", "VendorDiscounts" );
		Env.Insert ( "DiscountDebts", "VendorDiscountDebts" );
		Env.Insert ( "Money", "Dr" );
		Env.Insert ( "Organizations", "Cr" );
	else
		Env.Insert ( "Refund", false );
		Env.Insert ( "Customer", false );
		Env.Insert ( "Register", "VendorDebts" );
		Env.Insert ( "Discounts", "VendorDiscounts" );
		Env.Insert ( "DiscountDebts", "VendorDiscountDebts" );
		Env.Insert ( "Money", "Cr" );
		Env.Insert ( "Organizations", "Dr" );
	endif;
	
EndProcedure

Procedure getData ( Env )

	sqlFields ( Env );
	sqlPayments ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	customer = Env.Customer;
	refund = Env.Refund;
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company, Documents.BankAccount as BankAccount,
	|	Documents.Method as Method, Documents.Location as Location, Documents.Account as Account,
	|	Documents.ContractCurrency as ContractCurrency, Documents.Currency as Currency, Documents.CashFlow as CashFlow
	|";
	if ( customer ) then
		s = s + ",
		|Documents.Contract.CustomerAdvancesMonthly as AdvancesMonthly,
		|Documents.CustomerAccount as OrganizationAccount";
		if ( not refund ) then
			s = s + ",
			|Documents.ReceivablesVATAccount as ReceivablesVATAccount,
			|Documents.VATAccount as VATAccount, Documents.VATAdvance.Rate as VAT";
		endif;
	else
		s = s + ",
		|Documents.Contract.VendorAdvancesMonthly as AdvancesMonthly";
		if ( refund ) then
			s = s + ",
			|Documents.VendorAccount as OrganizationAccount";
		else
			s = s + ",
			|Documents.VendorAccount as OrganizationAccount, Documents.ExpenseReport.Employee as Employee,
			|Documents.IncomeTaxAccount as IncomeTaxAccount, Documents.IncomeTax as IncomeTax";
		endif;
	endif;
	if ( customer or not refund ) then
		s = s + ",
		|Documents.AdvanceAccount as AdvanceAccount";
	endif;
	s = s + "
	|from Document." + Env.Document + " as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlPayments ( Env )
	
	table = "Document." + Env.Document;
	organization = ? ( Env.Customer, "Customer", "Vendor" );
	incomeTax = not ( Env.Customer or Env.Refund );
	s = "
	|// Split user's input into amount and advance
	|select Payments.Row as Row,
	|		case when Payments.Payment > 0 then
	|			case when Payments.Payment > Payments.Amount then Payments.Amount else Payments.Payment end
	|		else
	|			case when Payments.Payment > Payments.Amount then Payments.Payment else Payments.Amount end
	|	end as Amount
	|into Payments
	|from (
	|	select Payments.LineNumber as Row, Payments.Amount as Amount,
	|		case when Payments.Advance <> 0 then Payments.Advance
	|			else Payments.Payment - Payments.Discount
	|		end as Payment
	|	from " + table + ".Payments as Payments
	|	where Payments.Ref = &Ref
	|) as Payments
	|;
	|// The whole document as a table
	|select Records.LineNumber as Row, Records.Contract.Owner as Organization, Records.Contract as Contract,
	|	Records.Document as Document, Records.Detail as Detail, Records.PaymentKey as PaymentKey,
	|	Records.Discount as Discount, Records.Advance <> 0 as ReturningAdvance,	Records.Debt <> 0 as Debt,
	|	Records.Payment <> 0 as Payment, Payments.Amount as Amount
	|";
	if ( incomeTax ) then
		s = s + ", cast ( Payments.Amount / 100 * Records.Ref.IncomeTaxRate as Number ( 15, 2 ) ) as IncomeTax";
	endif;
	s = s + "
	|into Records
	|from " + table + ".Payments as Records
	|	//
	|	// Payments
	|	//
	|	join Payments as Payments
	|	on Payments.Row = Records.LineNumber
	|where Records.Ref = &Ref
	|union all
	|select isnull ( Table.Row, 1 ), Documents." + organization + ", Documents.Contract, &Ref, undefined, null,
	|	0, false, false, false, false, Documents.ContractAmount - isnull ( Table.Amount, 0 )
	|";
	if ( incomeTax ) then
		s = s + ",
		|cast ( ( Documents.ContractAmount - isnull ( Table.Amount, 0 ) ) / 100 * Documents.IncomeTaxRate
		|	as Number ( 15, 2 ) )";
	endif;
	s = s + "
	|from " + table + " as Documents
	|	//
	|	// Table
	|	//
	|	left join (
	|		select 1 + max ( Payments.Row ) as Row, sum ( Payments.Amount ) as Amount
	|		from Payments as Payments
	|	) as Table
	|	on true
	|where Documents.Ref = &Ref
	|and Documents.ContractAmount > isnull ( Table.Amount, 0 )
	|;
	|// Payments table
	|select Records.Row as Row, Records.Amount as Amount,
	|	cast (
	|		Records.Amount * Rates.ContractRate / Rates.ContractFactor
	|	as Number ( 15, 2 ) ) as AmountAccounting,
	|	cast (
	|		( Records.Amount * Rates.ContractRate / Rates.ContractFactor ) / Rates.Rate * Rates.Factor
	|	as Number ( 15, 2 ) ) as AmountDocument
	|";
	if ( incomeTax ) then
		s = s + ",
		|	Records.IncomeTax as IncomeTax,
		|	cast ( Records.IncomeTax * Rates.ContractRate / Rates.ContractFactor
		|		as Number ( 15, 2 ) ) as IncomeTaxAccounting,
		|	cast (
		|		( Records.IncomeTax * Rates.ContractRate / Rates.ContractFactor ) / Rates.Rate * Rates.Factor
		|	as Number ( 15, 2 ) ) as IncomeTaxDocument
		|";
	endif;
	s = s + "
	|into Input
	|from Records as Records
	|	//
	|	// Rates
	|	//
	|	join " + table + " as Rates
	|	on Rates.Ref = &Ref
	|;
	|// Totals
	|select sum ( Totals.MaxAmount ) as MaxAmount,
	|	sum ( Totals.Amount ) as TotalAmountDocument,
	|	cast (
	|		sum ( Totals.Amount ) * min ( Rates.Rate ) / min ( Rates.Factor )
	|	as Number ( 15, 2 ) ) as TotalAmountAccounting,
	|	sum ( Totals.AmountAccounting ) as AmountAccounting,
	|	sum ( Totals.AmountDocument ) as AmountDocument
	|";
	if ( incomeTax ) then
		s = s + ",
		|	cast (
		|		( sum ( Totals.TotalIncomeTaxAmount )
		|			* min ( Rates.Rate ) / min ( Rates.Factor ) ) / min ( Rates.ContractRate ) * min ( Rates.ContractFactor )
		|	as Number ( 15, 2 ) ) as TotalIncomeTax,
		|	sum ( Totals.TotalIncomeTaxAmount ) as TotalIncomeTaxDocument,
		|	cast (
		|		sum ( Totals.TotalIncomeTaxAmount ) * min ( Rates.Rate ) / min ( Rates.Factor )
		|	as Number ( 15, 2 ) ) as TotalIncomeTaxAccounting,
		|	sum ( Totals.IncomeTaxContract ) as IncomeTax,
		|	sum ( Totals.IncomeTaxDocument ) as IncomeTaxDocument,
		|	sum ( Totals.IncomeTaxAccounting ) as IncomeTaxAccounting
		|";
	endif;
	s = s + "
	|into Total
	|from (
	|	select
	|		0 as MaxAmount,
	|		Documents.Amount as Amount,
	|		0 as AmountAccounting,
	|		0 as AmountDocument
	|";
	if ( incomeTax ) then
		s = s + ",
		|	Documents.IncomeTaxAmount as TotalIncomeTaxAmount,
		|	0 as IncomeTaxDocument,
		|	0 as IncomeTaxContract,
		|	0 as IncomeTaxAccounting
		|";
	endif;
	s = s + "
	|	from " + table + " as Documents
	|	where Documents.Ref = &Ref
	|	union all
	|	select
	|		max ( Input.Amount ),
	|		0,
	|		sum ( Input.AmountAccounting ),
	|		sum ( Input.AmountDocument )
	|";
	if ( incomeTax ) then
		s = s + ",
		|	0,
		|	sum ( Input.IncomeTaxDocument ),
		|	sum ( Input.IncomeTax ),
		|	sum ( Input.IncomeTaxAccounting )
		|";
	endif;
	s = s + "
	|	from Input as Input
	|) as Totals
	|	//
	|	// Rates
	|	//
	|	join " + table + " as Rates
	|	on Rates.Ref = &Ref
	|;
	|// Fixed Amounts
	|select
	|	Input.Row as Row,
	|	Input.AmountAccounting + isnull ( ( Total.TotalAmountAccounting - Total.AmountAccounting ), 0 ) as AmountAccounting,
	|	Input.AmountDocument + isnull ( ( Total.TotalAmountDocument - Total.AmountDocument ), 0 ) as AmountDocument
	|";
	if ( incomeTax ) then
		s = s + ",
		|	Input.IncomeTax + isnull ( ( Total.TotalIncomeTax - Total.IncomeTax ), 0 )
		|		as IncomeTax,
		|	Input.IncomeTaxAccounting + isnull ( ( Total.TotalIncomeTaxAccounting - Total.IncomeTaxAccounting ), 0 )
		|		as IncomeTaxAccounting,
		|	Input.IncomeTaxDocument + isnull ( ( Total.TotalIncomeTaxDocument - Total.IncomeTaxDocument ), 0 )
		|		as IncomeTaxDocument
		|";
	endif;
	s = s + "
	|into Amounts
	|from Input as Input
	|	//
	|	// Totals
	|	//
	|	left join Total as Total
	|	on Total.MaxAmount = Input.Amount
	|	and Input.Row in (
	|		select max ( Input.Row ) as Row
	|		from Input as Input
	|			//
	|			// Total
	|			//
	|			join Total as Total
	|			on Total.MaxAmount = Input.Amount
	|	)
	|;
	|// #Payments
	|select
	|	Records.Organization as Organization, Records.Contract as Contract, Records.Document as Document,
	|	Records.Discount as Discount, Records.PaymentKey as PaymentKey, Records.Payment as Payment,
	|	case when Records.Payment and not ( Records.Debt or Records.ReturningAdvance ) then &Ref else Records.Detail end as Detail,
	|	Records.Debt as Debt, Records.ReturningAdvance as ReturningAdvance,
	|	Input.Amount as Amount, Amounts.AmountAccounting as AmountAccounting, Amounts.AmountDocument as AmountDocument
	|";
	if ( incomeTax ) then
		s = s + ",
		|	Amounts.IncomeTax as IncomeTax, Amounts.IncomeTaxAccounting as IncomeTaxAccounting,
		|	Amounts.IncomeTaxDocument as IncomeTaxDocument
		|";
	endif;
	s = s + "
	|from Records as Records
	|	//
	|	// Input
	|	//
	|	join Input as Input
	|	on Input.Row = Records.Row
	|	//
	|	// Amounts
	|	//
	|	join Amounts as Amounts
	|	on Amounts.Row = Input.Row
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure makePayments ( Env )
	
	Env.Insert ( "Buffer", GeneralRecords.Frame () );
	for each row in Env.Payments do
		proceedDiscount ( Env, row );
		proceedPayment ( Env, row );
	enddo;
	
EndProcedure

Procedure proceedDiscount ( Env, Row )

	discount = Row.Discount;
	if ( discount = 0 ) then
		return;
	endif;
	fields = Env.Fields;
	if ( providedAfterDelivery ( Row ) ) then
		movement = Env.Registers [ Env.DiscountDebts ].Add ();
		movement.Period = fields.Date;
		FillPropertyValues ( movement, Row, "Contract, Document, Detail" );
		movement.Amount = discount;
	else	
		movement = Env.Registers [ Env.Register ].Add ();
		movement.Period = fields.Date;
		FillPropertyValues ( movement, Row, "Contract, Document, Detail, PaymentKey" );
		movement.Payment = - discount;
		makeDiscount ( Env, Row );
	endif;

EndProcedure

Function providedAfterDelivery ( Row )
	
	orders = new Array ();
	orders.Add ( TypeOf ( undefined ) );
	orders.Add ( Type ( "DocumentRef.SalesOrder" ) );
	orders.Add ( Type ( "DocumentRef.PurchaseOrder" ) );
	return orders.Find ( TypeOf ( Row.Document ) ) = undefined
		or Row.Detail <> undefined;
	
EndFunction

Procedure makeDiscount ( Env, Row )
	
	register = Env.Registers [ Env.Discounts ];
	movement = register.Add ();
	date = Env.Fields.Date;
	movement.Period = date;
	document = Row.Document;
	movement.Document = document;
	amount = Row.Discount;
	movement.Amount = amount;
	detail = Row.Detail;
	if ( detail <> undefined ) then
		movement.Detail = detail;
		movement = register.Add ();
		movement.Period = date;
		movement.Document = detail;
		movement.Detail = document;
		movement.Amount = amount;
	endif;
	
EndProcedure

Procedure proceedPayment ( Env, Row )
	
	fields = Env.Fields;
	refund = Env.Refund;
	amount = Row.Amount; 
	amountAccounting = Row.AmountAccounting;
	returningAdvance = Row.ReturningAdvance;
	hasDebt = Row.Debt;
	register = Env.Registers [ Env.Register ];
	if ( not refund and ( hasDebt or returningAdvance ) ) then
		movement = register.AddExpense ();
	else
		movement = register.AddReceipt ();
	endif;
	movement.Period = fields.date;
	FillPropertyValues ( movement, Row, "Contract, Document, Detail, PaymentKey" );
	if ( hasDebt ) then
		movement.Amount = amount;
		movement.Accounting = amountAccounting;
		movement.Payment = amount;
	elsif ( returningAdvance ) then
		movement.Overpayment = - amount;
		movement.Advance = - amountAccounting;
		restorePayment ( Env, Row );
		if ( Env.Customer and not refund ) then
			acceptAdvance ( Env, Row, not fields.AdvancesMonthly );
		else
			returnAdvance ( Env, Row, not fields.AdvancesMonthly );
		endif;
	else
		if ( refund ) then
			movement.Amount = amount;
			movement.Accounting = amountAccounting;
			movement.Payment = amount;
		else
			movement.Overpayment = amount;
			movement.Advance = amountAccounting;
			if ( Row.Payment ) then
				movement = register.AddExpense ();
				movement.Period = fields.date;
				FillPropertyValues ( movement, Row, "Contract, Document, PaymentKey" );
				movement.Payment = amount;
			endif;
		endif;
	endif;
	if ( not returningAdvance ) then
		commitDebt ( Env, Row );
	endif;

EndProcedure

Procedure acceptAdvance ( Env, Row, Advance )
	
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.PaymentReturn;
	advanceData = givenAdvanceData ( Env, Row );
	if ( Advance ) then
		p.AccountCr = advanceData.AdvanceAccount;
	else
		p.AccountCr = fields.OrganizationAccount;
	endif;
	p.CurrencyCr = fields.ContractCurrency;
	amount = - Row.Amount;
	amountAccounting = - Row.AmountAccounting;
	amountDocument = - Row.AmountDocument;
	incomeTaxRate = advanceData.IncomeTaxRate;
	reverseIncomeTax = incomeTaxRate <> 0;
	if ( reverseIncomeTax ) then
		precision = Metadata.AccountingRegisters.General.Resources.Amount.Type.NumberQualifiers.FractionDigits;
		incomeTax = Round ( amount / 100 * incomeTaxRate, precision );
		incomeTaxAccounting = Round ( amountAccounting / 100 * incomeTaxRate, precision );
		incomeTaxDocument = Round ( amountDocument / 100 * incomeTaxRate, precision );
		amount = amount - incomeTax;			
		amountAccounting = amountAccounting - incomeTaxAccounting;			
		amountDocument = amountDocument - incomeTaxDocument;
	endif;
	p.CurrencyAmountCr = amount;
	p.DimCr1 = Row.Organization;
	p.DimCr2 = Row.Contract;
	p.AccountDr = fields.Account;
	p.CurrencyDr = fields.Currency;
	methods = Enums.PaymentMethods;
	if ( fields.Method = methods.Cash ) then
		location = fields.Location;
	elsif ( fields.Method = methods.ExpenseReport ) then
		location = fields.Employee;
	else
		location = fields.BankAccount;
	endif; 
	p.DimDr1 = location;
	p.DimDr2 = fields.CashFlow;
	p.CurrencyAmountDr = amountDocument;
	p.Amount = amountAccounting;
	p.Recordset = Env.Buffer;
	GeneralRecords.Add ( p );
	if ( reverseIncomeTax ) then
		p.Operation = Enums.Operations.IncomeTaxWithheld;
		p.AccountDr = advanceData.IncomeTaxAccount;
		p.DimDr1 = advanceData.IncomeTax;
		p.CurrencyAmountDr = incomeTaxDocument;
		p.Amount = incomeTaxAccounting;
		p.Recordset = Env.Buffer;
		GeneralRecords.Add ( p );
	endif;

EndProcedure

Function givenAdvanceData ( Env, Row )
	
	recorders = new Array ();
	recorders.Add ( Row.Document );
	recorders.Add ( Row.Detail );
	vendorPayment = Type ( "DocumentRef.VendorPayment" );
	customerRefund = Type ( "DocumentRef.Refund" );
	result = new Structure ( "AdvanceAccount, IncomeTax, IncomeTaxRate, IncomeTaxAccount",
		Env.Fields.OrganizationAccount, , 0 );
	for each recorder in recorders do
		recorderType = TypeOf ( recorder );
		if ( recorderType = vendorPayment ) then
			data = DF.Values ( recorder, "AdvanceAccount, IncomeTax, IncomeTaxRate, IncomeTaxAccount" );
			FillPropertyValues ( result, data );
			break;
		elsif ( recorderType = customerRefund ) then
			result.AdvanceAccount = DF.Pick ( recorder, "AdvanceAccount" );
			break;
		endif;
	enddo;
	return result;
	
EndFunction

Procedure returnAdvance ( Env, Row, Advance )
	
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.PaymentReturn;
	money = Env.Money;
	organizations = Env.Organizations;
	if ( Advance ) then
		advanceData = takenAdvanceData ( Env, Row );
		account = advanceData.AdvanceAccount;
	else
		account = fields.OrganizationAccount;
	endif;
	p [ "Account" + organizations ] = account;
	p [ "Currency" + organizations ] = fields.ContractCurrency;
	p [ "CurrencyAmount" + organizations ] = Row.Amount;
	dim = "Dim" + organizations;
	p [ dim + 1 ] = Row.Organization;
	p [ dim + 2 ] = Row.Contract;
	p [ "Account" + money ] = fields.Account;
	p [ "Currency" + money ] = fields.Currency;
	methods = Enums.PaymentMethods;
	if ( fields.Method = methods.Cash ) then 
	elsif ( fields.Method = methods.ExpenseReport ) then
		location = fields.Employee;
	else
		location = fields.BankAccount;
	endif; 
	dim = "Dim" + money;
	p [ dim + 1 ] = location;
	p [ dim + 2 ] = fields.CashFlow;
	p [ "CurrencyAmount" + money ] = Row.AmountDocument;
	amountAccounting = Row.AmountAccounting;
	p.Amount = amountAccounting;
	p.Recordset = Env.Buffer;
	reverseVAT = Advance and advanceData.VAT <> 0;
	if ( reverseVAT ) then
		payment = advanceData.Payment;
		p.Dependency = payment;
	endif;
	GeneralRecords.Add ( p );
	if ( reverseVAT ) then
		p [ "Account" + organizations ] = advanceData.ReceivablesVATAccount;
		p [ "Account" + money ] = advanceData.VATAccount;
		vatAmount = amountAccounting - amountAccounting * ( 100 / ( 100 + advanceData.VAT ) );
		p.Amount = - vatAmount;
		p.Operation = Enums.Operations.VATAdvancesReverse;
		p.Content = String ( Enums.Operations.VATAdvancesReverse ) + ": " + payment; 
		GeneralRecords.Add ( p );
	endif;
	
EndProcedure

Function takenAdvanceData ( Env, Row )
	
	result = new Structure ( "Payment, VAT, VATAccount, AdvanceAccount, ReceivablesVATAccount", , 0 );
	customerPayment = Type ( "DocumentRef.Payment" );
	debts = Type ( "DocumentRef.Debts" );
	vendorRefund = Type ( "DocumentRef.VendorRefund" );
	vendorPayment = Type ( "DocumentRef.VendorPayment" );
	vendorDebts = Type ( "DocumentRef.VendorDebts" );
	recorders = new Array ();
	recorders.Add ( Row.Document );
	recorders.Add ( Row.Detail );
	recorders.Add ( Env.Ref );
	for each recorder in recorders do
		type = TypeOf ( recorder );
		if ( type = customerPayment ) then
			set = "AdvanceAccount, ReceivablesVATAccount, VATAdvance.Rate as VAT, VATAccount";
			break;
		elsif ( type = debts ) then
			set = "Account as AdvanceAccount, ReceivablesVATAccount, VATAdvance.Rate as VAT, VATAccount";
			break;
		elsif ( type = vendorPayment ) then
			set = "AdvanceAccount";
			break;
		elsif ( type = vendorDebts
			or type = vendorRefund ) then
			set = "Account as AdvanceAccount";
			break;
		endif;
	enddo;
	data = DF.Values ( recorder, set );
	FillPropertyValues ( result, data );
	return result;
	
EndFunction

Procedure commitDebt ( Env, Row )
	
	fields = Env.Fields;
	advance = not ( Row.Debt or Row.ReturningAdvance or fields.AdvancesMonthly );
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	refund = Env.Refund;
	contractors = Env.Organizations;
	money = Env.Money;
	amount = Row.Amount;
	amountAccounting = Row.AmountAccounting;
	amountDocument = Row.AmountDocument;
	customer =  Env.Customer;
	incomeTax = not ( Env.Customer or Refund );
	if ( customer ) then
		if ( refund ) then
			p.Operation = Enums.Operations.CustomerRefund;
		else
			p.Operation = ? ( advance, Enums.Operations.AdvanceTaken, Enums.Operations.CustomerPayment );
		endif;
	else
		if ( refund ) then
			p.Operation = Enums.Operations.VendorRefund;
		else
			p.Operation = ? ( advance, Enums.Operations.AdvanceGiven, Enums.Operations.VendorPayment );
			if ( incomeTax ) then
				amount = amount - Row.IncomeTax;			
				amountAccounting = amountAccounting - Row.IncomeTaxAccounting;			
				amountDocument = amountDocument - Row.IncomeTaxDocument;
			endif;
		endif;
	endif; 
	p [ "Account" + contractors ] = ? ( advance and not refund, fields.AdvanceAccount, fields.OrganizationAccount );
	p [ "Currency" + contractors ] = fields.ContractCurrency;
	p [ "CurrencyAmount" + contractors ] = amount;
	p [ "Dim" + contractors + "1" ] = Row.Organization;
	p [ "Dim" + contractors + "2" ] = Row.Contract;
	p [ "Account" + money ] = fields.Account;
	p [ "Currency" + money ] = fields.Currency;
	if ( fields.Method = Enums.PaymentMethods.Cash ) then
		location = fields.Location;
	elsif ( fields.Method = Enums.PaymentMethods.ExpenseReport ) then
		location = fields.Employee;
	else
		location = fields.BankAccount;
	endif; 
	p [ "Dim" + money + "1" ] = location;
	p [ "Dim" + money + "2" ] = fields.CashFlow;
	p [ "CurrencyAmount" + money ] = amountDocument;
	p.Amount = amountAccounting;
	p.Recordset = Env.Buffer;
	GeneralRecords.Add ( p );
	if ( incomeTax ) then
		commitIncomeTax ( Env, Row, Advance );
	endif;
	if ( customer and advance and not refund and fields.VAT <> 0 ) then
		commitAdvanceVAT ( Env, Row );
	endif;
	
EndProcedure

Procedure commitIncomeTax ( Env, Row, Advance )
	
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.IncomeTaxWithheld;
	p.AccountDr = ? ( Advance, fields.AdvanceAccount, fields.OrganizationAccount );
	p.CurrencyDr = fields.ContractCurrency;
	p.CurrencyAmountDr = Row.IncomeTax;
	p.DimDr1 = Row.Organization;
	p.DimDr2 = Row.Contract;
	p.AccountCr = fields.IncomeTaxAccount;
	p.CurrencyCr = fields.Currency;
	p.DimCr1 = fields.IncomeTax;
	p.CurrencyAmountCr = Row.IncomeTaxDocument;
	p.Amount = Row.IncomeTaxAccounting;
	p.Recordset = Env.Buffer;
	GeneralRecords.Add ( p );
	
EndProcedure

Procedure commitAdvanceVAT ( Env, Row )
	
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.VATAdvances;
	p.AccountDr = fields.ReceivablesVATAccount;
	p.DimDr1 = Row.Organization;
	p.DimDr2 = Row.Contract;
	p.AccountCr = fields.VATAccount;
	amount = Row.Amount;
	p.Amount = amount - amount * ( 100 / ( 100 + fields.VAT ) );
	p.Recordset = Env.Buffer;
	GeneralRecords.Add ( p );
	
EndProcedure

Procedure restorePayment ( Env, Row )
	
	document = Row.Document;
	type = TypeOf ( Row.Document );
	customer = Env.Customer;
	if ( ( customer and type = Type ( "DocumentRef.SalesOrder" ) )
		or ( not customer and type = Type ( "DocumentRef.PurchaseOrder" ) ) ) then
		register = Env.Registers [ Env.Register ];
		movement = ? ( Env.Refund, register.AddExpense (), register.AddReceipt () );
		movement.Period = Env.Fields.Date;
		movement.Contract = Row.Contract;
		movement.PaymentKey = Row.PaymentKey;
		movement.Document = document;
		movement.Detail = undefined;
		movement.Payment = Row.Amount;
	endif;
	
EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	GeneralRecords.Flush ( registers.General, Env.Buffer );
	registers.General.Write = true;
	registers [ Env.Register ].Write = true;
	registers [ Env.Discounts ] .Write = true;
	registers [ Env.DiscountDebts ] .Write = true;
	
EndProcedure
