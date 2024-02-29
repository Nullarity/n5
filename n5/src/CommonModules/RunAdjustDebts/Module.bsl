Function Post ( Env ) export
	
	setContext ( Env );
	getData ( Env );
	PaymentDetails.Init ( Env );
	fields = Env.Fields;
	option = fields.Option;
	decreaseDebt ( Env, Env.Adjustments, false );
	increaseDebt ( Env, Env.Accounting, false );
	if ( option = Enums.AdjustmentOptions.Customer
		or option = Enums.AdjustmentOptions.Vendor ) then
		decreaseDebt ( Env, Env.AdjustmentsReceiver, true );
		increaseDebt ( Env, Env.AccountingReceiver, true );
	endif;
	if ( fields.IsExpense ) then
		makeExpenses ( Env );
	endif;
	flagRegisters ( Env );
	PaymentDetails.Save ( Env );
	return true;
	
EndFunction

Procedure setContext ( Env )
	
	Env.Insert ( "Customer", Env.Type = Type ( "DocumentRef.AdjustDebts" ) );
	
EndProcedure

Procedure getData ( Env )

	sqlFields ( Env );
	getFields ( Env );
	fields = Env.Fields;
	option = fields.Option;
	sqlAdjustments ( Env );
	sqlAccounting ( Env );
	if ( option = Enums.AdjustmentOptions.Customer
		or option = Enums.AdjustmentOptions.Vendor ) then
		sqlAdjustmentsReceiver ( Env );
		sqlAccountingReceiver ( Env );
	endif;
	q = Env.Q;
	q.SetParameter ( "Organization", fields.Organization );
	q.SetParameter ( "OrganizationAccount", fields.OrganizationAccount );
	q.SetParameter ( "ReceiverAccount", fields.ReceiverAccount );
	q.SetParameter ( "Contract", fields.Contract );
	SQL.Perform ( Env );
	Env.Insert ( "DrCr", drcr ( Env ) );
	Env.Insert ( "Buffer", GeneralRecords.Frame () );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company, Documents.Contract as Contract,
	|	Documents.Option as Option, Documents.ApplyVAT as ApplyVAT,
	|	Documents.AmountDifference as AmountDifference, Documents.AdvanceAccount as AdvanceAccount,
	|	Documents.VATAdvance.Rate as VATAdvanceRate, Documents.VATAccount as PrepaymentVATAccount,
	|	Documents.ReceivablesVATAccount as ReceivablesVATAccount";
	if ( Env.Customer ) then
		s = s + ",
		|Documents.CustomerAccount as OrganizationAccount, Documents.Customer as Organization,
		|Documents.Contract.CustomerAdvancesMonthly as AdvancesMonthly";
	else
		s = s + ",
		|Documents.VendorAccount as OrganizationAccount, Documents.Vendor as Organization,
		|Documents.Contract.VendorAdvancesMonthly as AdvancesMonthly";
	endif;
	s = s + ",
	|	Documents.Type as Type, Documents.Amount as Amount, Documents.ContractAmount as ContractAmount,
	|	Documents.Rate as Rate, Documents.Factor as Factor, Documents.ReceiverAccount as ReceiverAccount,
	|	Documents.Account as Account, Documents.Dim1 as Dim1, Documents.Dim2 as Dim2, Documents.Dim3 as Dim3, 
	|	Documents.ContractCurrency as ContractCurrency, Documents.Currency as Currency,
	|	Constants.Currency as LocalCurrency, Documents.ContractRate as ContractRate,
	|	Documents.ContractFactor as ContractFactor,  
	|	isnull ( Documents.Account.Class, undefined ) in (
	|		value ( Enum.Accounts.Expenses ),
	|		value ( Enum.Accounts.OtherExpenses ),
	|		value ( Enum.Accounts.CostOfGoodsSold )
	|	) as IsExpense,
	|	Documents.Receiver as Receiver, Documents.ReceiverContract as ReceiverContract,
	|	Documents.ReceiverContractCurrency as ReceiverContractCurrency,
	|	Documents.ReceiverContract.CustomerAdvancesMonthly as ReceiverAdvancesMonthly,
	|	Documents.Reversal as Reversal, Documents.TypeReceiver as TypeReceiver
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

Procedure getFields ( Env ) 

	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );

EndProcedure

Procedure sqlAdjustments ( Env )
	
	table = "Document." + Env.Document;
	s = "
	|select Adjustments.Document
	|into Adjustments
	|from " + table + ".Adjustments as Adjustments
	|where Adjustments.Ref = &Ref
	|and valuetype ( Adjustments.Document ) in (
	|	type ( Document.AdjustDebts ),
	|	type ( Document.AdjustVendorDebts )
	|)
	|union all
	|select Adjustments.Detail
	|from " + table + ".Adjustments as Adjustments
	|where Adjustments.Ref = &Ref
	|and valuetype ( Adjustments.Detail ) in (
	|	type ( Document.AdjustDebts ),
	|	type ( Document.AdjustVendorDebts )
	|)
	|union all
	|select Adjustments.Document
	|from " + table + ".ReceiverDebts as Adjustments
	|where Adjustments.Ref = &Ref
	|and valuetype ( Adjustments.Document ) in (
	|	type ( Document.AdjustDebts ),
	|	type ( Document.AdjustVendorDebts )
	|)
	|union all
	|select Adjustments.Detail
	|from " + table + ".ReceiverDebts as Adjustments
	|where Adjustments.Ref = &Ref
	|and valuetype ( Adjustments.Detail ) in (
	|	type ( Document.AdjustDebts ),
	|	type ( Document.AdjustVendorDebts )
	|)
	|;
	|// Adjustmets Customer Accounts
	|select Documents.Ref as Ref,
	|	case
	|		when Documents.Option in (
	|			value ( Enum.AdjustmentOptions.Customer ), value ( Enum.AdjustmentOptions.Vendor )
	|		) then
	|			case Documents.Type when value ( Enum.TypesAdjustDebts.Debt ) then Documents.CustomerAccount
	|				else Documents.ReceiverAccount
	|			end
	|		else
	|			Documents.CustomerAccount
	|	end as Account
	|into AdjustmentAccounts
	|from Document.AdjustDebts as Documents
	|where Documents.Ref in ( select Ref from Adjustments )
	|union all
	|select Documents.Ref, Documents.ReceiverAccount
	|from Document.AdjustVendorDebts as Documents
	|where Documents.Ref in ( select Ref from Adjustments )
	|;
	|// #Adjustments
	|select Adjustments.Document as Document, Adjustments.Amount as Amount, Adjustments.Payment as Payment
	|";
	if ( Env.Fields.AmountDifference ) then
		s = s + ",
		|	Adjustments.Accounting as Debt, Adjustments.Advance as Overpayment,
		|	case
		|		when ( Adjustments.Accounting = 0 
		|			and Adjustments.Advance > 0 )
		|			or Adjustments.Accounting > 0 then Adjustments.Amount
		|		else -Adjustments.Amount
		|	end as AmountDebts";
	else
		s = s + ",
		|	Adjustments.Overpayment as Overpayment, Adjustments.Debt as Debt,
		|	case
		|		when ( Adjustments.Debt = 0 
		|			and Adjustments.Overpayment > 0 )
		|			or Adjustments.Debt > 0 then Adjustments.Amount
		|		else -Adjustments.Amount
		|	end as AmountDebts";
	endif;
	s = s + ",
	|	Adjustments.Detail as Detail, Adjustments.PaymentKey as PaymentKey,
	|	Adjustments.VAT as VAT, Adjustments.VATAccount as VATAccount, Adjustments.AmountLocal as AmountLocal,
	|	Adjustments.VATLocal as VATLocal, Adjustments.AmountDocument as AmountDocument,
	|	Adjustments.VATDocument as VATDocument,
	|	valuetype ( Adjustments.Document ) in (
	|		type ( Document.SalesOrder ),
	|		type ( Document.PurchaseOrder )
	|	) as ByOrder
	|";
	s = s + documentAccounts ( Env, false );
	if ( Env.Customer ) then
		s = s + vatAccounts ();
	endif;
	s = s + "
	|from " + table + ".Adjustments as Adjustments
	|where Adjustments.Ref = &Ref
	|// :order by Adjustments.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Function documentAccounts ( Env, ForReceiver )
	 
	organizationAccount = new Array ();
	advanceAccount = new Array ();
	customer = Env.Customer;
	if ( customer or ForReceiver ) then
		organizationAccount.Add ( "
		|	when Adjustments.Document refs Document.Payment then cast ( Adjustments.Document as Document.Payment ).CustomerAccount
		|	when Adjustments.Document refs Document.Invoice then cast ( Adjustments.Document as Document.Invoice ).CustomerAccount
		|	when Adjustments.Document refs Document.AdjustDebts then cast ( Adjustments.Document as Document.AdjustDebts ).CustomerAccount
		|	when Adjustments.Document refs Document.AdjustVendorDebts then cast ( Adjustments.Document as Document.AdjustVendorDebts ).ReceiverAccount
		|	when Adjustments.Document refs Document.Refund then cast ( Adjustments.Document as Document.Refund ).CustomerAccount
		|	when Adjustments.Document refs Document.Return then cast ( Adjustments.Document as Document.Return ).CustomerAccount
		|	when Adjustments.Document refs Document.Debts then cast ( Adjustments.Document as Document.Debts ).CustomerAccount
		|	when Adjustments.Detail refs Document.Payment then cast ( Adjustments.Detail as Document.Payment ).CustomerAccount
		|	when Adjustments.Detail refs Document.Invoice then cast ( Adjustments.Detail as Document.Invoice ).CustomerAccount
		|	when Adjustments.Detail refs Document.AdjustDebts then cast ( Adjustments.Detail as Document.AdjustDebts ).CustomerAccount
		|	when Adjustments.Detail refs Document.AdjustVendorDebts then cast ( Adjustments.Detail as Document.AdjustVendorDebts ).ReceiverAccount
		|	when Adjustments.Detail refs Document.Refund then cast ( Adjustments.Detail as Document.Refund ).CustomerAccount
		|	when Adjustments.Detail refs Document.Return then cast ( Adjustments.Detail as Document.Return ).CustomerAccount
		|	when Adjustments.Detail refs Document.Debts then cast ( Adjustments.Detail as Document.Debts ).CustomerAccount
		|" );
		advanceAccount.Add ( "
		|	when Adjustments.Document refs Document.Payment then cast ( Adjustments.Document as Document.Payment ).AdvanceAccount
		|	when Adjustments.Document refs Document.AdjustDebts then cast ( Adjustments.Document as Document.AdjustDebts ).AdvanceAccount
		|	when Adjustments.Document refs Document.AdjustVendorDebts then cast ( Adjustments.Document as Document.AdjustVendorDebts ).AdvanceAccount
		|	when Adjustments.Document refs Document.Refund then cast ( Adjustments.Document as Document.Refund ).AdvanceAccount
		|	when Adjustments.Document refs Document.Debts then cast ( Adjustments.Document as Document.Debts ).AdvanceAccount
		|	when Adjustments.Detail refs Document.Payment then cast ( Adjustments.Detail as Document.Payment ).AdvanceAccount
		|	when Adjustments.Detail refs Document.AdjustDebts then cast ( Adjustments.Detail as Document.AdjustDebts ).AdvanceAccount
		|	when Adjustments.Detail refs Document.AdjustVendorDebts then cast ( Adjustments.Detail as Document.AdjustVendorDebts ).AdvanceAccount
		|	when Adjustments.Detail refs Document.Refund then cast ( Adjustments.Detail as Document.Refund ).AdvanceAccount
		|	when Adjustments.Detail refs Document.Debts then cast ( Adjustments.Detail as Document.Debts ).AdvanceAccount
		|" );
	endif;
	if ( not customer or ForReceiver ) then
		organizationAccount.Add ( "
		|	when Adjustments.Document refs Document.VendorPayment then cast ( Adjustments.Document as Document.VendorPayment ).VendorAccount
		|	when Adjustments.Document refs Document.VendorInvoice then cast ( Adjustments.Document as Document.VendorInvoice ).VendorAccount
		|	when Adjustments.Document refs Document.AdjustVendorDebts then cast ( Adjustments.Document as Document.AdjustVendorDebts ).VendorAccount
		|	when Adjustments.Document refs Document.AdjustDebts then cast ( Adjustments.Document as Document.AdjustDebts ).ReceiverAccount
		|	when Adjustments.Document refs Document.VendorRefund then cast ( Adjustments.Document as Document.VendorRefund ).VendorAccount
		|	when Adjustments.Document refs Document.VendorReturn then cast ( Adjustments.Document as Document.VendorReturn ).VendorAccount
		|	when Adjustments.Document refs Document.VendorDebts then cast ( Adjustments.Document as Document.VendorDebts ).VendorAccount
		|	when Adjustments.Detail refs Document.VendorPayment then cast ( Adjustments.Detail as Document.VendorPayment ).VendorAccount
		|	when Adjustments.Detail refs Document.VendorInvoice then cast ( Adjustments.Detail as Document.VendorInvoice ).VendorAccount
		|	when Adjustments.Detail refs Document.AdjustVendorDebts then cast ( Adjustments.Detail as Document.AdjustVendorDebts ).VendorAccount
		|	when Adjustments.Detail refs Document.AdjustDebts then cast ( Adjustments.Detail as Document.AdjustDebts ).ReceiverAccount
		|	when Adjustments.Detail refs Document.VendorRefund then cast ( Adjustments.Detail as Document.VendorRefund ).VendorAccount
		|	when Adjustments.Detail refs Document.VendorReturn then cast ( Adjustments.Detail as Document.VendorReturn ).VendorAccount
		|	when Adjustments.Detail refs Document.VendorDebts then cast ( Adjustments.Detail as Document.VendorDebts ).VendorAccount
		|" );
		advanceAccount.Add ( "
		|	when Adjustments.Document refs Document.VendorPayment then cast ( Adjustments.Document as Document.VendorPayment ).AdvanceAccount
		|	when Adjustments.Document refs Document.AdjustVendorDebts then cast ( Adjustments.Document as Document.AdjustVendorDebts ).AdvanceAccount
		|	when Adjustments.Document refs Document.AdjustDebts then cast ( Adjustments.Document as Document.AdjustDebts ).AdvanceAccount
		|	when Adjustments.Document refs Document.VendorDebts then cast ( Adjustments.Document as Document.VendorDebts ).AdvanceAccount
		|	when Adjustments.Detail refs Document.VendorPayment then cast ( Adjustments.Detail as Document.VendorPayment ).AdvanceAccount
		|	when Adjustments.Detail refs Document.AdjustVendorDebts then cast ( Adjustments.Detail as Document.AdjustVendorDebts ).AdvanceAccount
		|	when Adjustments.Detail refs Document.AdjustDebts then cast ( Adjustments.Detail as Document.AdjustDebts ).AdvanceAccount
		|	when Adjustments.Detail refs Document.VendorDebts then cast ( Adjustments.Detail as Document.VendorDebts ).AdvanceAccount
		|" );
	endif;
	return ",
	|	case " + StrConcat ( organizationAccount ) + " end as OrganizationAccount,
	|	case " + StrConcat ( advanceAccount ) + " end as AdvanceAccount,
	|	case Adjustments.Detail when undefined then Adjustments.Document else Adjustments.Detail end as PrepaymentRef
	|";

EndFunction

Function vatAccounts ()

	s = ",
	|	case
	|		when Adjustments.Document refs Document.Payment then cast ( Adjustments.Document as Document.Payment ).VATAccount
	|		when Adjustments.Detail refs Document.Payment then cast ( Adjustments.Detail as Document.Payment ).VATAccount
	|		when Adjustments.Document refs Document.AdjustDebts then cast ( Adjustments.Document as Document.AdjustDebts ).VATAccount
	|		when Adjustments.Detail refs Document.AdjustDebts then cast ( Adjustments.Detail as Document.AdjustDebts ).VATAccount
	|		when Adjustments.Document refs Document.Debts then cast ( Adjustments.Document as Document.Debts ).VATAccount
	|		when Adjustments.Detail refs Document.Debts then cast ( Adjustments.Detail as Document.Debts ).VATAccount
	|	end as PrepaymentVATAccount,
	|	case
	|		when Adjustments.Document refs Document.Payment then cast ( Adjustments.Document as Document.Payment ).ReceivablesVATAccount
	|		when Adjustments.Detail refs Document.Payment then cast ( Adjustments.Detail as Document.Payment ).ReceivablesVATAccount
	|		when Adjustments.Document refs Document.AdjustDebts then cast ( Adjustments.Document as Document.AdjustDebts ).ReceivablesVATAccount
	|		when Adjustments.Detail refs Document.AdjustDebts then cast ( Adjustments.Detail as Document.AdjustDebts ).ReceivablesVATAccount
	|		when Adjustments.Document refs Document.Debts then cast ( Adjustments.Document as Document.Debts ).ReceivablesVATAccount
	|		when Adjustments.Detail refs Document.Debts then cast ( Adjustments.Detail as Document.Debts ).ReceivablesVATAccount
	|	end as ReceivablesVATAccount,
	|	case
	|		when Adjustments.Document refs Document.Payment then cast ( Adjustments.Document as Document.Payment ).VATAdvance.Rate
	|		when Adjustments.Detail refs Document.Payment then cast ( Adjustments.Detail as Document.Payment ).VATAdvance.Rate
	|		when Adjustments.Document refs Document.AdjustDebts then cast ( Adjustments.Document as Document.AdjustDebts ).VATAdvance.Rate
	|		when Adjustments.Detail refs Document.AdjustDebts then cast ( Adjustments.Detail as Document.AdjustDebts ).VATAdvance.Rate
	|		when Adjustments.Document refs Document.Debts then cast ( Adjustments.Document as Document.Debts ).VATAdvance.Rate
	|		when Adjustments.Detail refs Document.Debts then cast ( Adjustments.Detail as Document.Debts ).VATAdvance.Rate
	|	end as VATAdvanceRate
	|";
	return s;

EndFunction
	
Procedure sqlAdjustmentsReceiver ( Env )
	
	table = "Document." + Env.Document + ".ReceiverDebts";
	s = "
	|// #AdjustmentsReceiver
	|select Adjustments.Document as Document, Adjustments.Applied as Amount, Adjustments.Payment as Payment,
	|	Adjustments.Overpayment as Overpayment, Adjustments.Debt as Debt, Adjustments.AmountLocal as AmountLocal,
	|	Adjustments.Detail as Detail, Adjustments.PaymentKey as PaymentKey,
	|	Adjustments.AmountDocument as AmountDocument,
	|	valuetype ( Adjustments.Document ) in (
	|		type ( Document.SalesOrder ),
	|		type ( Document.PurchaseOrder )
	|	) as ByOrder,
	|	case 
	|		when ( Adjustments.Debt = 0 
	|			and Adjustments.Overpayment > 0 )
	|			or Adjustments.Debt > 0 then Adjustments.Applied
	|		else -Adjustments.Applied
	|	end as AmountDebts
	|" + documentAccounts ( Env, true ) + vatAccounts () + "
	|from " + table + " as Adjustments
	|where Adjustments.Ref = &Ref
	|// :order by Adjustments.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlAccounting ( Env )
	
	s = "
	|// #Accounting
	|select Accounting.Amount as Amount, &OrganizationAccount as OrganizationAccount,
	|	Accounting.VAT as VAT, Accounting.VATAccount as VATAccount, Accounting.AmountLocal as AmountLocal,
	|	Accounting.VATLocal as VATLocal, Accounting.AmountDocument as AmountDocument,
	|	Accounting.VATDocument as VATDocument, Accounting.PaymentOption as PaymentOption,
	|	Accounting.PaymentDate as PaymentDate, PaymentDetails.PaymentKey as PaymentKey
	|from Document." + Env.Document + ".Accounting as Accounting
	|	//
	|	// Payment Details
	|	//
	|	left join InformationRegister.PaymentDetails as PaymentDetails
	|	on PaymentDetails.Option = Accounting.PaymentOption
	|	and PaymentDetails.Date =
	|		case when Accounting.PaymentDate = datetime ( 1, 1, 1 )
	|			then datetime ( 3999, 12, 31 )
	|			else Accounting.PaymentDate
	|		end
	|where Accounting.Ref = &Ref
	|// :order by Accounting.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlAccountingReceiver ( Env )
	
	s = "
	|// #AccountingReceiver
	|select Accounting.Amount as Amount, &ReceiverAccount as OrganizationAccount,
	|	Accounting.VAT as VAT, Accounting.VATAccount as VATAccount, Accounting.AmountLocal as AmountLocal,
	|	Accounting.VATLocal as VATLocal, Accounting.AmountDocument as AmountDocument,
	|	Accounting.VATDocument as VATDocument, Accounting.PaymentOption as PaymentOption,
	|	Accounting.PaymentDate as PaymentDate, PaymentDetails.PaymentKey as PaymentKey
	|from Document." + Env.Document + ".AccountingReceiver as Accounting
	|	//
	|	// Payment Details
	|	//
	|	left join InformationRegister.PaymentDetails as PaymentDetails
	|	on PaymentDetails.Option = Accounting.PaymentOption
	|	and PaymentDetails.Date =
	|		case when Accounting.PaymentDate = datetime ( 1, 1, 1 )
	|			then datetime ( 3999, 12, 31 )
	|			else Accounting.PaymentDate
	|		end
	|where Accounting.Ref = &Ref
	|// :order by Accounting.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Function drcr ( Env )

	fields = Env.Fields;
	advance = ( fields.Type = Enums.TypesAdjustDebts.Advance );
	customer = Env.Customer;
	if ( fields.AmountDifference ) then
		option = fields.Option;
		if ( option = Enums.AdjustmentOptions.CustomAccountCr ) then
			organizationDr = true;
		elsif ( option = Enums.AdjustmentOptions.CustomAccountDr ) then
			organizationDr = false;
		else
			organizationDr = ( customer and advance ) or not ( customer or advance );
		endif;
		operation = Enums.Operations.AdjustDebts;
		straight = ( customer and organizationDr )
			or not ( customer or organizationDr );
		direction = ? ( straight, -1, 1 );
	else
		organizationDr = ( customer and advance ) or not ( customer or advance );
		if ( customer ) then
			operation = ? ( advance,
				Enums.Operations.AdjustAdvances, Enums.Operations.AdjustDebts );
		else
			operation = ? ( advance,
				Enums.Operations.AdjustVendorAdvances, Enums.Operations.AdjustVendorDebts );
		endif;
		direction = 1;
	endif;
	advanceDr = not organizationDr;
	if ( fields.Reversal ) then
		organizationDr = not organizationDr;
	endif;
	result = new Structure ( "Organization, Receiver, Operation, AdvanceDr, DebtDirection" );
	result.Operation = operation;
	result.AdvanceDr = advanceDr;
	result.DebtDirection = direction;
	if ( organizationDr ) then
		result.Organization = "Dr";
		result.Receiver = "Cr";
	else
		result.Organization = "Cr";
		result.Receiver = "Dr";
	endif;
	return result;

EndFunction

Procedure decreaseDebt ( Env, Table, ForReceiver )
	
	fields = Env.Fields;
	if ( ForReceiver ) then
		isCustomer = ( fields.Option = Enums.AdjustmentOptions.Customer );
		contract = fields.ReceiverContract;
	else
		isCustomer = Env.Customer;
		contract = fields.Contract;
	endif;
	if ( isCustomer ) then
		register = Env.Registers.Debts;
	else
		register = Env.Registers.VendorDebts;
	endif;
	date = fields.Date;
	reversal = fields.Reversal;
	regularAdjustment = ForReceiver or not fields.AmountDifference;
	for each row in Table do
		if ( not ForReceiver ) then
			commitDebt ( Env, row );
		endif;
		if ( reversal ) then
			movement = register.AddReceipt ();
			coef = -1;
		else
			movement = register.AddExpense ();
			coef = 1;
		endif;
		movement.Period = date;
		movement.Contract = contract;
		movement.Document = row.Document;
		movement.Detail = row.Detail;
		movement.PaymentKey = row.PaymentKey;
		amount = row.AmountDebts;
		amountAccounting = row.AmountLocal;
		if ( row.Debt = 0 ) then
			movement.Advance = coef * amountAccounting * ? ( amount < 0, - 1, 1 ); //* ? ( regularAdjustment, 1, -1 );
			if ( regularAdjustment ) then
				movement.Overpayment = coef * amount;
				if ( row.ByOrder ) then
					record = register.Add ();
					movement.Period = fields.date;
					FillPropertyValues ( record, movement,
						"Period, RecordType, Contract, Document, PaymentKey" );
					record.Payment = - amount * coef;
				endif;
			endif;
			registerAdvance ( Env, row, ForReceiver, true );
		else
			movement.Accounting = coef * amountAccounting * ? ( amount < 0, - 1, 1 );
			if ( regularAdjustment ) then
				movement.Amount = coef * amount;
				if ( amount < 0 ) then
					movement.Payment = coef * Max ( amount, row.Payment );
				else
					movement.Payment = coef * Min ( amount, row.Payment );
				endif;
			endif;
		endif;
	enddo;
	
EndProcedure

Procedure increaseDebt ( Env, Table, ForReceiver )
	
	fields = Env.Fields;
	increaseDebt = fields.Type = Enums.TypesAdjustDebts.Advance;
	customerDebts = Env.Customer;
	if ( ForReceiver ) then
		option = fields.Option;
		isCustomer = option = Enums.AdjustmentOptions.Customer;
		contract = fields.ReceiverContract;
		direct = ( customerDebts and option = Enums.AdjustmentOptions.Customer )
			or not ( customerDebts or option = Enums.AdjustmentOptions.Customer );
		if ( direct ) then
			increaseDebt = not increaseDebt;
		endif;
	else
		isCustomer = customerDebts;
		contract = fields.Contract;
	endif;
	register = ? ( isCustomer, Env.Registers.Debts, Env.Registers.VendorDebts );
	date = fields.Date;
	ref = Env.Ref;
	reversal = fields.Reversal;
	regularAdjustment = ForReceiver or not fields.AmountDifference;
	for each row in Table do
		if ( not ForReceiver ) then
			commitDebt ( Env, row );
		endif;
		if ( reversal ) then
			movement = register.AddExpense ();
			coef = -1;
		else
			movement = register.AddReceipt ();
			coef = 1;
		endif;
		movement.Period = date;
		movement.Contract = contract;
		movement.Document = ref;
		amount = row.Amount * coef;
		amountAccounting = row.AmountLocal * coef;
		if ( increaseDebt ) then
			movement.Accounting = amountAccounting;
			movement.PaymentKey = getPaymentKey ( Env, row.PaymentKey, row.PaymentOption, row.PaymentDate );
			if ( regularAdjustment ) then
				movement.Amount = amount;
				movement.Payment = amount;
			endif;
		else
			movement.Advance = amountAccounting;
			if ( regularAdjustment ) then
				movement.Overpayment = amount;
			endif;
			registerAdvance ( Env, row, ForReceiver, false );
		endif;
	enddo; 
	
EndProcedure

Function getPaymentKey ( Env, PaymentKey, Option, Date )
	
	if ( PaymentKey = null ) then
		Env.PaymentDetails.Option = Option;
		Env.PaymentDetails.Date = Date;
		return PaymentDetails.GetKey ( Env );
	endif; 
	return PaymentKey;
		
EndFunction 

Procedure commitDebt ( Env, Row )

	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Recordset = Env.Buffer;
	date = fields.Date;
	p.Date = date;
	p.Company = fields.Company;
	drcr = Env.DrCr;
	coef = ? ( fields.Reversal, -1, 1 ) * drcr.DebtDirection;
	sideOrganization = drcr.Organization;
	sideReceiver = drcr.Receiver;
	dim = "Dim" + sideReceiver;
	option = fields.Option;
	if ( option = Enums.AdjustmentOptions.Customer
		or option = Enums.AdjustmentOptions.Vendor ) then
		p [ "Account" + sideReceiver ] = fields.ReceiverAccount;
		p [ dim + "1" ] = fields.Receiver;
		p [ dim + "2" ] = fields.ReceiverContract;
		p [ "Currency" + sideReceiver ] =  fields.ReceiverContractCurrency;
	else
		p [ "Account" + sideReceiver ] = fields.Account;
		p [ dim + "1" ] = fields.Dim1;
		p [ dim + "2" ] = fields.Dim2;
		p [ dim + "3" ] = fields.Dim3;
		p [ "Currency" + sideReceiver ] =  fields.Currency;
	endif;
	p [ "CurrencyAmount" + sideReceiver ] = ( row.AmountDocument - row.VATDocument ) * coef;
	p [ "Account" + sideOrganization ] = Row.OrganizationAccount;
	dim = "Dim" + sideOrganization;
	p [ dim + "1" ] = fields.Organization;
	p [ dim + "2" ] = fields.Contract;
	p [ "Currency" + sideOrganization ] = fields.ContractCurrency;
	p [ "CurrencyAmount" + sideOrganization ] = ( row.Amount - row.VAT ) * coef;
	p.Operation = drcr.Operation;
	if ( fields.ApplyVAT ) then
		vat = row.VATLocal;
		p.Amount = ( row.AmountLocal - vat ) * coef;
		GeneralRecords.Add ( p );
		if ( vat <> 0 ) then
			p [ "Account" + sideReceiver ] = Row.VATAccount;
			p [ "CurrencyAmount" + sideReceiver ] = row.VATDocument * coef;
			p [ "CurrencyAmount" + sideOrganization ] = row.VAT * coef;
			p.Amount = vat * coef;
			p.Operation = Enums.Operations.VATPayable;
			GeneralRecords.Add ( p );
		endif;
	else
		p.Amount = row.AmountLocal * coef;
		GeneralRecords.Add ( p );
	endif;
	
EndProcedure

Procedure registerAdvance ( Env, Row, ForReceiver, Closing )
	
	if ( monthlyAdvances ( Env, ForReceiver ) ) then
		return;
	endif;
	fields = Env.Fields;
	drcr = Env.DrCr;
	if ( ForReceiver ) then
		advanceDr = not drcr.AdvanceDr;
		organization = fields.Receiver;
		contract = fields.ReceiverContract;
		contractCurrency = fields.ReceiverContractCurrency;
		isCustomer = ( fields.Option = Enums.AdjustmentOptions.Customer );
	else
		advanceDr = drcr.AdvanceDr;
		organization = fields.Organization;
		contract = fields.Contract;
		contractCurrency = fields.ContractCurrency;
		isCustomer = Env.Customer;
	endif;
	if ( advanceDr ) then
		sideOrganization = "Cr";
		sideReceiver = "Dr";
	else
		sideOrganization = "Dr";
		sideReceiver = "Cr";
	endif;
	if ( Closing ) then
		organizationAccount = Row.OrganizationAccount;
		advanceAccount = Row.AdvanceAccount;
		operation = ? ( isCustomer, Enums.Operations.AdvanceApplied, Enums.Operations.AdvanceGivenApplied );
		dependency = Row.PrepaymentRef;
	else
		organizationAccount = fields.OrganizationAccount;
		advanceAccount = fields.AdvanceAccount;
		operation = ? ( isCustomer, Enums.Operations.AdvanceTakenAfterAdjustments, Enums.Operations.AdvanceGivenAfterAdjustments );
		dependency = undefined;
	endif;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;;
	p.Company = fields.Company;
	p [ "Account" + sideReceiver ] = organizationAccount;
	p [ "Dim" + sideReceiver + "1" ] = organization;
	p [ "Dim" + sideReceiver + "2" ] = contract;
	p [ "Currency" + sideReceiver ] =  contractCurrency;
	amount = Row.Amount;
	p [ "CurrencyAmount" + sideReceiver ] = amount;
	p [ "Account" + sideOrganization ] = advanceAccount;
	p [ "Dim" + sideOrganization + "1" ] = organization;
	p [ "Dim" + sideOrganization + "2" ] = contract;
	p [ "Currency" + sideOrganization ] = contractCurrency;
	p [ "CurrencyAmount" + sideOrganization ] = amount;
	p.Amount = Row.AmountLocal;
	p.Operation = operation;
	p.Dependency = dependency;
	p.Recordset = Env.Buffer;
	GeneralRecords.Add ( p );
	if ( vatFromAdvances ( Env, ForReceiver ) ) then
		registerAdvanceVAT ( Env, row, ForReceiver, Closing );
	endif;
	
EndProcedure

Function monthlyAdvances ( Env, ForReceiver )

	fields = Env.Fields;
	return ( ForReceiver and fields.ReceiverAdvancesMonthly )
		or ( not ForReceiver and fields.AdvancesMonthly );

EndFunction

Function vatFromAdvances ( Env, ForReceiver )

	fields = Env.Fields;
	if ( ForReceiver ) then
		return
			fields.Option = Enums.AdjustmentOptions.Customer
			and not fields.ReceiverAdvancesMonthly;
	else
		return
			Env.Customer
			and not fields.AdvancesMonthly;
	endif;

EndFunction

Procedure registerAdvanceVAT ( Env, Row, ForReceiver, Reverse )
	
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Recordset = Env.Buffer;
	date = fields.Date;
	p.Date = date;
	p.Company = fields.Company;
	if ( ForReceiver ) then
		organization = fields.Receiver;
		contract = fields.ReceiverContract;
	else
		organization = fields.Organization;
		contract = fields.Contract;
	endif;
	p.DimDr1 = organization;
	p.DimDr2 = contract;
	amount = Row.AmountLocal;
	if ( Reverse ) then
		p.AccountDr = Row.ReceivablesVATAccount;
		p.AccountCr = Row.PrepaymentVATAccount;
		p.Amount = - amount + amount * ( 100 / ( 100 + Row.VATAdvanceRate ) );
		payment = Row.PrepaymentRef;
		p.Operation = Enums.Operations.VATAdvancesReverse;
		p.Content = String ( Enums.Operations.VATAdvancesReverse ) + ": " + payment; 
		p.Dependency = payment;
	else
		p.AccountDr = fields.ReceivablesVATAccount;
		p.AccountCr = fields.PrepaymentVATAccount;
		p.Amount = 	amount - amount * ( 100 / ( 100 + fields.VATAdvanceRate ) );
		p.Operation = Enums.Operations.VATAdvances;
	endif;
	GeneralRecords.Add ( p );

EndProcedure
	
Procedure makeExpenses ( Env ) 

	fields = Env.Fields;
	movement = Env.Registers.Expenses.Add ();
	movement.Period = fields.Date;
	movement.Account = fields.Account;
	value = fields.Dim1;
	if ( TypeOf ( value ) = Type ( "CatalogRef.Expenses" ) ) then
		movement.Expense = value;
	endif;
	value = fields.Dim2;
	if ( TypeOf ( value ) = Type ( "CatalogRef.Departments" ) ) then
		movement.Department = value;
	endif;
	movement.Document = Env.Ref;
	movement.AmountDr = Env.Adjustments.Total ( "AmountLocal" )
		+ Env.Accounting.Total ( "AmountLocal" );

EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	GeneralRecords.Flush ( registers.General, Env.Buffer, true );
	registers.General.Write = true;
	registers.Debts.Write = true;
	registers.VendorDebts.Write = true;
	registers.Expenses.Write = true;
	
EndProcedure
