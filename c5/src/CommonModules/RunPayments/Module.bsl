Function Post ( Env ) export
	
	setContext ( Env );
	initVars ( Env );
	getData ( Env );
	makePayments ( Env );
	commitAdvanceVAT ( Env );
	fixCurrency ( Env );
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

Procedure initVars ( Env )
	
	if ( Env.Refund ) then
		return;
	elsif ( Env.Customer ) then
		Env.Insert ( "Advance", 0 );
	else
		Env.Insert ( "IncomeTaxWithheld", 0 );
	endif;

EndProcedure

Procedure getData ( Env )

	sqlFields ( Env );
	sqlPayments ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	Env.Insert ( "Discount", 0 );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company, Documents.Contract as Contract,
	|	Documents.Amount as Amount, Documents.ContractAmount as PaymentAmount, Documents.Rate as Rate,
	|	Documents.Factor as Factor, Documents.BankAccount as BankAccount, Documents.Method as Method,
	|	Documents.Location as Location, Documents.Account as Account, Documents.ContractCurrency as ContractCurrency,
	|	Documents.Currency as Currency, Constants.Currency as LocalCurrency,
	|	Documents.ContractRate as ContractRate, Documents.ContractFactor as ContractFactor,
	|	Documents.CashFlow as CashFlow
	|";
	if ( Env.Customer ) then
		s = s + ", Documents.Customer as Organization, Documents.CustomerAccount as OrganizationAccount";
		if ( not Env.Refund ) then
			s = s + ", Documents.Contract.CustomerAdvancesMonthly as AdvancesMonthly,
			|Documents.ReceivablesVATAccount as ReceivablesVATAccount,
			|Documents.VATAccount as VATAccount, Documents.VATAdvance.Rate as VAT";
		endif;
	else
		if ( Env.Refund ) then
			s = s + ", Documents.Vendor as Organization, Documents.VendorAccount as OrganizationAccount";
		else
			s = s + ", Documents.Contract.VendortAdvancesMonthly as AdvancesMonthly,
			|Documents.Vendor as Organization, Documents.VendorAccount as OrganizationAccount,
			|Documents.ExpenseReport.Employee as Employee, Documents.IncomeTaxRate as IncomeTaxRate,
			|Documents.IncomeTaxAmount as IncomeTaxAmount, Documents.IncomeTax as IncomeTax,
			|Documents.IncomeTaxAccount as IncomeTaxAccount";
		endif;
	endif;
	if ( Env.Customer or not Env.Refund ) then
		s = s + ", Documents.AdvanceAccount as AdvanceAccount";
	endif;
	s = s + "
	|from Document." + Env.Document + " as Documents
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on true
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlPayments ( Env )
	
	s = "
	|// #Payments
	|select Payments.Contract.Owner as Organization, Payments.Contract as Contract, Payments.Document as Document,
	|	Payments.Discount as Discount, Payments.Amount as Amount, Payments.Advance as Advance, Payments.Payment as Payment,
	|	Payments.Debt as Debt, Payments.Bill as Bill, Payments.Detail as Detail, Payments.PaymentKey as PaymentKey
	|from Document." + Env.Document + ".Payments as Payments
	|where Payments.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure makePayments ( Env )
	
	Env.Insert ( "Buffer", GeneralRecords.Frame () );
	for each row in Env.Payments do
		proceedDiscount ( Env, row );
		payment = proceedPayment ( Env, row );
		advance = proceedOverpayment ( Env, row, payment );
		commitDebt ( Env, row.Organization, row.Contract, payment - advance, false );
	enddo;
	proceedAdvance ( Env );
	proceedIncomeTax ( Env );
	
EndProcedure

Procedure proceedDiscount ( Env, Row )

	discount = Row.Discount;
	if ( discount = 0 ) then
		return;
	endif;
	fields = Env.Fields;
	if ( providedAfterDelivery ( Row ) ) then
		movement = Env.Registers [ Env.DiscountDebts ].Add ();
		movement.Period = fields.date;
		movement.Contract = Row.Contract;
		movement.Document = Row.Document;
		movement.Detail = Row.Detail;
		movement.Amount = discount;
	else	
		movement = Env.Registers [ Env.Register ].Add ();
		movement.Period = fields.date;
		movement.Contract = Row.Contract;
		movement.Document = Row.Document;
		movement.Detail = Row.Detail;
		movement.PaymentKey = Row.PaymentKey;
		movement.Payment = - discount;
		if ( Row.Debt <> 0 ) then
			movement.Amount = - discount;
		endif; 
		if ( Row.Bill <> 0 ) then
			movement.Bill = - discount;
		endif; 
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

Function proceedPayment ( Env, Row )
	
	register = Env.Registers [ Env.Register ];
	movement = ? ( Env.Refund, register.AddReceipt (), register.AddExpense () );
	fields = Env.Fields;
	movement.Period = fields.date;
	movement.Contract = Row.Contract;
	movement.Document = Row.Document;
	movement.Detail = Row.Detail;
	movement.PaymentKey = Row.PaymentKey;
	payment = Row.Amount;
	advance = Row.Advance;
	returningAdvance = advance <> 0;
	if ( returningAdvance ) then
		advance = Min ( advance, payment );
		movement.Overpayment = - advance;
		payment = payment - advance;
		fields.PaymentAmount = fields.PaymentAmount - advance;
		if ( Env.Customer and not Env.Refund ) then
			acceptAdvance ( Env, movement, Row.Organization, Row.Contract, not fields.AdvancesMonthly );
		else
			returnAdvance ( Env, movement, Row.Organization, Row.Contract, not fields.AdvancesMonthly );
		endif;
	endif;
	payment = Min ( Max ( Row.Payment - Row.Discount, 0 ), payment );
	if ( payment <> 0 ) then
		movement.Payment = payment;
		if ( Row.Debt <> 0 ) then
			movement.Amount = payment;
		endif; 
		if ( Row.Bill <> 0 ) then
			movement.Bill = payment;
		endif; 
	endif;
	if ( returningAdvance ) then
		restorePayment ( Env, movement );
	endif;
	fields.PaymentAmount = fields.PaymentAmount - payment;
	return payment;
	
EndFunction

Procedure acceptAdvance ( Env, Record, Organization, Contract, Advance )
	
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.PaymentReturn;
	advanceData = givenAdvanceData ( Env, Record );
	if ( Advance ) then
		p.AccountCr = advanceData.AdvanceAccount;
	else
		p.AccountCr = fields.OrganizationAccount;
	endif;
	p.CurrencyCr = fields.ContractCurrency;
	amount = - Record.Overpayment;
	incomeTaxRate = advanceData.IncomeTaxRate;
	reverseIncomeTax = incomeTaxRate <> 0;
	if ( reverseIncomeTax ) then
		incomeTax = Round ( amount / 100 * incomeTaxRate, Metadata.AccountingRegisters.General.Resources.Amount.Type.NumberQualifiers.FractionDigits );
		amount = amount - incomeTax;			
	endif;
	p.CurrencyAmountCr = amount;
	p.DimCr1 = fields.Organization;
	p.DimCr2 = fields.Contract;
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
	currencyAmount = Currencies.Convert ( amount, fields.ContractCurrency, fields.Currency, fields.Date, fields.ContractRate, fields.ContractFactor, fields.Rate, fields.Factor );
	p.CurrencyAmountDr = currencyAmount;
	p.Amount = Currencies.Convert ( amount, fields.ContractCurrency, fields.LocalCurrency, fields.Date, fields.ContractRate, fields.ContractFactor );
	p.Recordset = Env.Buffer;
	GeneralRecords.Add ( p );
	if ( reverseIncomeTax ) then
		p.Operation = Enums.Operations.IncomeTaxWithheld;
		p.AccountDr = advanceData.IncomeTaxAccount;
		p.DimDr1 = advanceData.IncomeTax;
		p.Amount = Currencies.Convert ( incomeTax, fields.ContractCurrency, fields.LocalCurrency, fields.Date, fields.ContractRate, fields.ContractFactor );
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

Procedure returnAdvance ( Env, Record, Organization, Contract, Advance )
	
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.PaymentReturn;
	amount = - Record.Overpayment;			
	money = Env.Money;
	organizations = Env.Organizations;
	if ( Advance ) then
		advanceData = takenAdvanceData ( Env, Record );
		account = advanceData.AdvanceAccount;
	else
		account = fields.OrganizationAccount;
	endif;
	p [ "Account" + organizations ] = account;
	p [ "Currency" + organizations ] = fields.ContractCurrency;
	p [ "CurrencyAmount" + organizations ] = amount;
	dim = "Dim" + organizations;
	p [ dim + 1 ] = fields.Organization;
	p [ dim + 2 ] = fields.Contract;
	p [ "Account" + money ] = fields.Account;
	p [ "Currency" + money ] = fields.Currency;
	methods = Enums.PaymentMethods;
	if ( fields.Method = methods.Cash ) then
		location = fields.Location;
	elsif ( fields.Method = methods.ExpenseReport ) then
		location = fields.Employee;
	else
		location = fields.BankAccount;
	endif; 
	dim = "Dim" + money;
	p [ dim + 1 ] = location;
	p [ dim + 2 ] = fields.CashFlow;
	currencyAmount = Currencies.Convert ( amount, fields.ContractCurrency, fields.Currency, fields.Date, fields.ContractRate, fields.ContractFactor, fields.Rate, fields.Factor );
	p [ "CurrencyAmount" + money ] = currencyAmount;
	p.Amount = Currencies.Convert ( amount, fields.ContractCurrency, fields.LocalCurrency, fields.Date, fields.ContractRate, fields.ContractFactor );
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
		vatAmount = - amount + amount * ( 100 / ( 100 + advanceData.VAT ) );
		p.Amount = Currencies.Convert ( vatAmount, fields.ContractCurrency, fields.LocalCurrency, fields.Date, fields.ContractRate, fields.ContractFactor );
		p.Operation = Enums.Operations.VATAdvancesReverse;
		p.Content = String ( Enums.Operations.VATAdvancesReverse ) + ": " + payment; 
		GeneralRecords.Add ( p );
	endif;
	
EndProcedure

Function takenAdvanceData ( Env, Row )
	
	result = new Structure ( "Payment, VAT, VATAccount, AdvanceAccount, ReceivablesVATAccount", , 0 );
	customerPayment = Type ( "DocumentRef.Payment" );
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

Procedure commitDebt ( Env, Organization, Contract, Amount, Advance )
	
	if ( Amount = 0 ) then
		return;
	endif;
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	refund = Env.Refund;
	customer = Env.Customer;
	contractors = Env.Organizations;
	money = Env.Money;
	if ( customer ) then
		if ( refund ) then
			p.Operation = Enums.Operations.CustomerRefund;
		else
			p.Operation = ? ( Advance, Enums.Operations.AdvanceTaken, Enums.Operations.CustomerPayment );
		endif;
		debtAmount = Amount;
	else
		if ( refund ) then
			p.Operation = Enums.Operations.VendorRefund;
			debtAmount = Amount;
		else
			p.Operation = ? ( Advance, Enums.Operations.AdvanceGiven, Enums.Operations.VendorPayment );
			incomeTax = Round ( Amount / 100 * fields.IncomeTaxRate, Metadata.AccountingRegisters.General.Resources.Amount.Type.NumberQualifiers.FractionDigits );
			debtAmount = Amount - incomeTax;			
		endif;
	endif; 
	p [ "Account" + contractors ] = ? ( Advance and not refund, fields.AdvanceAccount, fields.OrganizationAccount );
	p [ "Currency" + contractors ] = fields.ContractCurrency;
	p [ "CurrencyAmount" + contractors ] = debtAmount;
	p [ "Dim" + contractors + "1" ] = Organization;
	p [ "Dim" + contractors + "2" ] = Contract;
	p [ "Account" + money ] = fields.Account;
	p [ "Currency" + money ] = fields.Currency;
	methods = Enums.PaymentMethods;
	if ( fields.Method = methods.Cash ) then
		location = fields.Location;
	elsif ( fields.Method = methods.ExpenseReport ) then
		location = fields.Employee;
	else
		location = fields.BankAccount;
	endif; 
	p [ "Dim" + money + "1" ] = location;
	p [ "Dim" + money + "2" ] = fields.CashFlow;
	currencyAmount = Currencies.Convert ( debtAmount, fields.ContractCurrency, fields.Currency, fields.Date, fields.ContractRate, fields.ContractFactor, fields.Rate, fields.Factor );
	p [ "CurrencyAmount" + money ] = currencyAmount;
	p.Amount = Currencies.Convert ( debtAmount, fields.ContractCurrency, fields.LocalCurrency, fields.Date, fields.ContractRate, fields.ContractFactor );
	p.Recordset = Env.Buffer;
	GeneralRecords.Add ( p );
	if ( not customer
		and not refund
		and incomeTax <> 0 ) then
		incomeTax = Currencies.Convert ( incomeTax, fields.ContractCurrency, fields.Currency, fields.Date, fields.ContractRate, fields.ContractFactor, fields.Rate, fields.Factor );
		commitIncomeTax ( Env, Organization, Contract, incomeTax, Advance );
	endif;
	if ( Advance and customer and not refund ) then
		Env.Advance = Env.Advance + Amount;
	endif;
	
EndProcedure

Procedure commitIncomeTax ( Env, Organization, Contract, Amount, Advance )
	
	if ( Amount = 0 ) then
		return;
	endif;
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.IncomeTaxWithheld;
	p.AccountDr = ? ( Advance, fields.AdvanceAccount, fields.OrganizationAccount );
	contractCurrency = fields.ContractCurrency;
	p.CurrencyDr = contractCurrency;
	currency = fields.Currency;
	currencyAmount = Currencies.Convert ( Amount, currency, contractCurrency, fields.Date, fields.Rate, fields.Factor, fields.ContractRate, fields.ContractFactor );
	p.CurrencyAmountDr = currencyAmount;
	p.DimDr1 = Organization;
	p.DimDr2 = Contract;
	p.AccountCr = fields.IncomeTaxAccount;
	p.CurrencyCr = currency;
	p.DimCr1 = fields.IncomeTax;
	p.CurrencyAmountCr = Amount;
	p.Amount = Currencies.Convert ( Amount, currency, fields.LocalCurrency, fields.Date, fields.Rate, fields.Factor );
	p.Recordset = Env.Buffer;
	GeneralRecords.Add ( p );
	Env.IncomeTaxWithheld = Env.IncomeTaxWithheld + Amount;
	
EndProcedure

Procedure commitAdvanceVAT ( Env )
	
	fields = Env.Fields;
	commit = Env.Customer and not Env.Refund and ( Env.Advance <> 0 ) and ( fields.VAT <> 0 );
	if ( not commit ) then
		return;
	endif;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.VATAdvances;
	p.AccountDr = fields.ReceivablesVATAccount;
	p.DimDr1 = fields.Organization;
	p.DimDr2 = fields.Contract;
	p.AccountCr = fields.VATAccount;
	amount = Currencies.Convert ( Env.Advance, fields.ContractCurrency, fields.LocalCurrency, fields.Date,
		fields.ContractRate, fields.ContractFactor );
	p.Amount = amount - amount * ( 100 / ( 100 + fields.VAT ) );
	p.Recordset = Env.Buffer;
	GeneralRecords.Add ( p );
	
EndProcedure

Procedure restorePayment ( Env, Record )
	
	document = TypeOf ( Record.Document );
	if ( ( Env.Customer and document = Type ( "DocumentRef.SalesOrder" ) )
		or ( not Env.Customer and document = Type ( "DocumentRef.PurchaseOrder" ) ) ) then
		register = Env.Registers [ Env.Register ];
		movement = ? ( Env.Refund, register.AddExpense (), register.AddReceipt () );
		movement.Period = Record.Period;
		movement.Contract = Record.Contract;
		movement.PaymentKey = Record.PaymentKey;
		movement.Document = Record.Document;
		movement.Detail = undefined;
		movement.Payment = Record.Overpayment;
	endif;
	
EndProcedure

Function proceedOverpayment ( Env, Row, Payment )

	debt = Row.Debt - Row.Discount;
	if ( Payment > debt ) then
		register = Env.Registers [ Env.Register ];
		movement = ? ( Env.Refund, register.AddExpense (), register.AddReceipt () );
		fields = Env.Fields;
		movement.Period = fields.date;
		movement.Contract = Row.Contract;
		movement.Document = Row.Document;
		movement.PaymentKey = Row.PaymentKey;
		movement.Detail = Env.Ref;
		advance = Payment - Max ( 0, debt );
		movement.Overpayment = advance;
		commitDebt ( Env, Row.Organization, Row.Contract, advance, not fields.AdvancesMonthly );
	else
		advance = 0;
	endif; 
	return advance;

EndFunction

Procedure proceedAdvance ( Env )

	overpayment = Env.Fields.PaymentAmount;
	if ( overpayment > 0 ) then
		register = Env.Registers [ Env.Register ];
		movement = register.AddReceipt ();
		if ( Env.Refund ) then
			movement.Amount = overpayment;
			movement.Payment = overpayment;
		else
			movement.Overpayment = overpayment;
		endif;
		fields = Env.Fields;
		movement.Period = fields.date;
		movement.Contract = fields.Contract;
		movement.Document = Env.Ref;
		commitDebt ( Env, fields.Organization, fields.Contract, overpayment, not fields.AdvancesMonthly );
	endif;

EndProcedure

Procedure proceedIncomeTax ( Env )

	if ( Env.Customer
		or Env.Refund ) then
		return;
	endif;
	fields = Env.Fields;
	rest = fields.IncomeTaxAmount - Env.IncomeTaxWithheld;
	commitIncomeTax ( Env, fields.Organization, fields.Contract, rest, true );

EndProcedure

Procedure fixCurrency ( Env )
	
	fields = Env.Fields;
	localCurrency = fields.LocalCurrency;
	currency = fields.Currency;
	contractCurrency = fields.ContractCurrency;
	if ( currency = localCurrency
		and contractCurrency = localCurrency ) then
		return;
	endif;
	if ( currency <> localCurrency ) then
		fixCurrencyAmount ( Env );
	endif;
	if ( currency <> contractCurrency ) then
		fixAmount ( Env );
	endif;

EndProcedure 

Procedure fixCurrencyAmount ( Env )
	
	fields = Env.Fields;
	account = fields.Account;
	money = "Account" + Env.Money;
	record = undefined;
	max = 0;
	fix = fields.Amount - ? ( Env.Customer or Env.Refund, 0, fields.IncomeTaxAmount );
	cash = "CurrencyAmount" + ? ( Env.Customer, "Dr", "Cr" );
	for each row in Env.Buffer do
		if ( account <> row [ money ]  ) then
			continue;
		endif;
		currencyAmount = row [ cash ];
		amount = ? ( currencyAmount < 0, - currencyAmount, currencyAmount );
		fix = fix - currencyAmount;
		if ( max < amount ) then
			Record = row;
			max = amount;
		endif; 
	enddo;
	if ( fix <> 0
		and record <> undefined ) then
		record [ cash ] = record [ cash ] + fix;
	endif; 
	
EndProcedure

Procedure fixAmount ( Env )
	
	fields = Env.Fields;
	account = fields.Account;
	money = "Account" + Env.Money;
	record = undefined;
	max = 0;
	fix = Currencies.Convert ( fields.Amount, fields.Currency, fields.LocalCurrency, fields.Date, fields.Rate, fields.Factor, , , 2 );
	for each row in Env.Buffer do
		if ( account <> row [ money ]  ) then
			continue;
		endif;
		amount = ? ( row.Amount < 0, - row.Amount, row.Amount );
		fix = fix - row.Amount;
		if ( max < amount ) then
			Record = row;
			max = amount;
		endif; 
	enddo;
	if ( fix <> 0
		and record <> undefined ) then
		record.Amount = record.Amount + fix;
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
