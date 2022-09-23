Function Post ( Env ) export
	
	setContext ( Env );
	getData ( Env );
	PaymentDetails.Init ( Env );
	fields = Env.Fields;
	option = fields.Option;
	if ( option = Enums.AdjustmentOptions.CustomAccountDr
		or option = Enums.AdjustmentOptions.CustomAccountDr
		or option = Enums.AdjustmentOptions.Customer
		or option = Enums.AdjustmentOptions.Vendor
	) then
		adjustDebt ( Env, Env.Adjustments, false );
		changeDebt ( Env, Env.Accounting, false );
		if ( option = Enums.AdjustmentOptions.Customer
			or option = Enums.AdjustmentOptions.Vendor ) then
			adjustDebt ( Env, Env.AdjustmentsReceiver, true );
			changeDebt ( Env, Env.AccountingReceiver, true );
			reverseReceiverAdvances ( Env );
		endif;
	endif;
	commitAdjustments ( Env );
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
	sqlAdjustments ( Env );
	sqlAccounting ( Env );
	fields = Env.Fields;
	option = fields.Option;
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
	|	Documents.Option as Option";
	if ( Env.Customer ) then
		s = s + ",
		|Documents.CustomerAccount as OrganizationAccount, Documents.Customer as Organization,
		|Documents.Contract.CustomerAdvancesMonthly as AdvancesMonthly, Documents.ApplyVAT as ApplyVAT";
	else
		s = s + ",
		|Documents.VendorAccount as OrganizationAccount, Documents.Vendor as Organization";
	endif;
	s = s + ",
	|	Documents.Type as Type, Documents.Amount as Amount, Documents.ContractAmount as ContractAmount,
	|	Documents.Rate as Rate, Documents.Factor as Factor, Documents.ReceiverAccount as ReceiverAccount,
	|	Documents.Account as Account, Documents.Dim1 as Dim1, Documents.Dim2 as Dim2, Documents.Dim3 as Dim3, 
	|	Documents.ContractCurrency as ContractCurrency, Documents.Currency as Currency,
	|	Constants.Currency as LocalCurrency, Documents.ContractRate as ContractRate,
	|	Documents.ContractFactor as ContractFactor,  
	|	Documents.Account.Class in (
	|		value ( Enum.Accounts.Expenses ),
	|		value ( Enum.Accounts.OtherExpenses ),
	|		value ( Enum.Accounts.CostOfGoodsSold )
	|	) as IsExpense,
	|	Documents.Receiver as Receiver, Documents.ReceiverContract as ReceiverContract,
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
	|select Adjustments.Document as Document, Adjustments.Amount as Amount, Adjustments.Payment as Payment,
	|	Adjustments.Overpayment as Overpayment, Adjustments.Debt as Debt, Adjustments.Bill as Bill,
	|	Adjustments.Detail as Detail, Adjustments.PaymentKey as PaymentKey,
	|	Adjustments.VAT as VAT, Adjustments.VATAccount as VATAccount, Adjustments.AmountLocal as AmountLocal,
	|	Adjustments.VATLocal as VATLocal, Adjustments.AmountDocument as AmountDocument,
	|	Adjustments.VATDocument as VATDocument,
	|	case 
	|		when ( Adjustments.Debt = 0 
	|			and Adjustments.Overpayment > 0 )
	|			or Adjustments.Debt > 0 then Adjustments.Amount
	|		else -Adjustments.Amount
	|	end as AmountDebts, " + vatSelection ( table + ".Adjustments" );
	Env.Selection.Add ( s );
	
EndProcedure

Function vatSelection ( Table )
	
	s = "
	|	case
	|	when Adjustments.Document refs Document.Payment then cast ( Adjustments.Document as Document.Payment ).CustomerAccount
	|		when Adjustments.Document refs Document.Invoice then cast ( Adjustments.Document as Document.Invoice ).CustomerAccount
	|		when Adjustments.Document refs Document.AdjustDebts then cast ( Adjustments.Document as Document.AdjustDebts ).CustomerAccount
	|		when Adjustments.Document refs Document.Refund then cast ( Adjustments.Document as Document.Refund ).CustomerAccount
	|		when Adjustments.Document refs Document.Return then cast ( Adjustments.Document as Document.Return ).CustomerAccount
	|		when Adjustments.Document refs Document.Debts
	|			and not cast ( Adjustments.Document as Document.Debts ).Advances then cast ( Adjustments.Document as Document.Debts ).Account
	|		when Adjustments.Detail refs Document.Payment then cast ( Adjustments.Detail as Document.Payment ).CustomerAccount
	|		when Adjustments.Detail refs Document.Invoice then cast ( Adjustments.Detail as Document.Invoice ).CustomerAccount
	|		when Adjustments.Detail refs Document.AdjustDebts then cast ( Adjustments.Detail as Document.AdjustDebts ).CustomerAccount
	|		when Adjustments.Detail refs Document.Refund then cast ( Adjustments.Detail as Document.Refund ).CustomerAccount
	|		when Adjustments.Detail refs Document.Return then cast ( Adjustments.Detail as Document.Return ).CustomerAccount
	|		when Adjustments.Detail refs Document.Debts
	|			and not cast ( Adjustments.Detail as Document.Debts ).Advances then cast ( Adjustments.Detail as Document.Debts ).Account
	|		when Adjustments.Document refs Document.AdjustDebts then AdjustmentAccountsDocuments.Account
	|		when Adjustments.Detail refs Document.AdjustDebts then AdjustmentAccountsDetails.Account
	|		else Adjustments.Ref.CustomerAccount
	|	end as OrganizationAccount,
	|	case
	|		when Adjustments.Document refs Document.Payment then cast ( Adjustments.Document as Document.Payment ).AdvanceAccount
	|		when Adjustments.Detail refs Document.Payment then cast ( Adjustments.Detail as Document.Payment ).AdvanceAccount
	|		when Adjustments.Document refs Document.AdjustDebts then cast ( Adjustments.Document as Document.AdjustDebts ).AdvanceAccount
	|		when Adjustments.Detail refs Document.AdjustDebts then cast ( Adjustments.Detail as Document.AdjustDebts ).AdvanceAccount
	|		when Adjustments.Document refs Document.Debts
	|			and cast ( Adjustments.Document as Document.Debts ).Advances then cast ( Adjustments.Document as Document.Debts ).Account
	|		when Adjustments.Detail refs Document.Debts
	|			and cast ( Adjustments.Detail as Document.Debts ).Advances then cast ( Adjustments.Detail as Document.Debts ).Account
	|	end as AdvanceAccount,
	|	case
	|		when Adjustments.Document refs Document.Payment then cast ( Adjustments.Document as Document.Payment ).VATAccount
	|		when Adjustments.Detail refs Document.Payment then cast ( Adjustments.Detail as Document.Payment ).VATAccount
	|		when Adjustments.Document refs Document.AdjustDebts then cast ( Adjustments.Document as Document.AdjustDebts ).VATAccount
	|		when Adjustments.Detail refs Document.AdjustDebts then cast ( Adjustments.Detail as Document.AdjustDebts ).VATAccount
	|		when Adjustments.Document refs Document.Debts
	|			and cast ( Adjustments.Document as Document.Debts ).Advances then cast ( Adjustments.Document as Document.Debts ).VATAccount
	|		when Adjustments.Detail refs Document.Debts
	|			and cast ( Adjustments.Detail as Document.Debts ).Advances then cast ( Adjustments.Detail as Document.Debts ).VATAccount
	|	end as PrepaymentVATAccount,
	|	case
	|		when Adjustments.Document refs Document.Payment then cast ( Adjustments.Document as Document.Payment ).ReceivablesVATAccount
	|		when Adjustments.Detail refs Document.Payment then cast ( Adjustments.Detail as Document.Payment ).ReceivablesVATAccount
	|		when Adjustments.Document refs Document.AdjustDebts then cast ( Adjustments.Document as Document.AdjustDebts ).ReceivablesVATAccount
	|		when Adjustments.Detail refs Document.AdjustDebts then cast ( Adjustments.Detail as Document.AdjustDebts ).ReceivablesVATAccount
	|		when Adjustments.Document refs Document.Debts
	|			and cast ( Adjustments.Document as Document.Debts ).Advances then cast ( Adjustments.Document as Document.Debts ).ReceivablesVATAccount
	|		when Adjustments.Detail refs Document.Debts
	|			and cast ( Adjustments.Detail as Document.Debts ).Advances then cast ( Adjustments.Detail as Document.Debts ).ReceivablesVATAccount
	|	end as ReceivablesVATAccount,
	|	case
	|		when Adjustments.Document refs Document.Payment then cast ( Adjustments.Document as Document.Payment ).VATAdvance.Rate
	|		when Adjustments.Detail refs Document.Payment then cast ( Adjustments.Detail as Document.Payment ).VATAdvance.Rate
	|		when Adjustments.Document refs Document.AdjustDebts then cast ( Adjustments.Document as Document.AdjustDebts ).VATAdvance.Rate
	|		when Adjustments.Detail refs Document.AdjustDebts then cast ( Adjustments.Detail as Document.AdjustDebts ).VATAdvance.Rate
	|		when Adjustments.Document refs Document.Debts
	|			and cast ( Adjustments.Document as Document.Debts ).Advances then cast ( Adjustments.Document as Document.Debts ).VATAdvance.Rate
	|		when Adjustments.Detail refs Document.Debts
	|			and cast ( Adjustments.Detail as Document.Debts ).Advances then cast ( Adjustments.Detail as Document.Debts ).VATAdvance.Rate
	|	end as VATAdvanceRate,
	|	case
	|		when Adjustments.Document refs Document.Payment then Adjustments.Document
	|		when Adjustments.Detail refs Document.Payment then Adjustments.Detail
	|		when Adjustments.Document refs Document.AdjustDebts then Adjustments.Document
	|		when Adjustments.Detail refs Document.AdjustDebts then Adjustments.Detail
	|		when Adjustments.Document refs Document.Debts
	|			and cast ( Adjustments.Document as Document.Debts ).Advances then Adjustments.Document
	|		when Adjustments.Detail refs Document.Debts
	|			and cast ( Adjustments.Detail as Document.Debts ).Advances then Adjustments.Detail
	|	end as PrepaymentRef
	|from " + Table + " as Adjustments
	|	//
	|	// Adjustment Accounts for Documents
	|	//
	|	left join AdjustmentAccounts as AdjustmentAccountsDocuments
	|	on AdjustmentAccountsDocuments.Ref = Adjustments.Document
	|	//
	|	// Adjustment Accounts for Details
	|	//
	|	left join AdjustmentAccounts as AdjustmentAccountsDetails
	|	on AdjustmentAccountsDetails.Ref = Adjustments.Detail
	|where Adjustments.Ref = &Ref
	|";
	return s;

EndFunction

Procedure sqlAdjustmentsReceiver ( Env )
	
	table = "Document." + Env.Document + ".ReceiverDebts";
	s = "
	|// #AdjustmentsReceiver
	|select Adjustments.Document as Document, Adjustments.Applied as Amount, Adjustments.Payment as Payment,
	|	Adjustments.Overpayment as Overpayment, Adjustments.Debt as Debt, Adjustments.Bill as Bill, Adjustments.Detail as Detail,
	|	Adjustments.PaymentKey as PaymentKey,
	|	case 
	|		when ( Adjustments.Debt = 0 
	|			and Adjustments.Overpayment > 0 )
	|			or Adjustments.Debt > 0 then Adjustments.Applied
	|		else -Adjustments.Applied
	|	end as AmountDebts, " + vatSelection ( table );
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
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Function drcr ( Env )

	customer = Env.Customer;
	fields = Env.Fields;
	advance = ( fields.Type = Enums.TypesAdjustDebts.Advance );
	organizationDr = ( customer and advance ) or not ( customer or advance );
	if ( fields.Reversal ) then
		organizationDr = not organizationDr;
	endif;
	if ( customer ) then
		operation = ? ( advance, Enums.Operations.AdjustAdvances, Enums.Operations.AdjustDebts );
	else
		operation = ? ( advance, Enums.Operations.AdjustVendorAdvances, Enums.Operations.AdjustVendorDebts );
	endif;
	result = new Structure ( "Organization, Receiver, Operation" );
	result.Operation = operation;
	if ( organizationDr ) then
		result.Organization = "Dr";
		result.Receiver = "Cr";
	else
		result.Organization = "Cr";
		result.Receiver = "Dr";
	endif;
	return result;

EndFunction

Procedure adjustDebt ( Env, Table, ForReceiver )
	
	fields = Env.Fields;
	if ( ForReceiver ) then
		isCustomer = fields.Option = Enums.AdjustmentOptions.Customer;
		contract = fields.ReceiverContract;
	else
		isCustomer = Env.Customer;
		contract = fields.Contract;
	endif;
	if ( isCustomer ) then
		regiter = Env.Registers.Debts;
	else
		regiter = Env.Registers.VendorDebts;
	endif;
	date = fields.Date;
	reversal = fields.Reversal;
	for each row in Table do
		if ( reversal ) then
			movement = regiter.AddReceipt ();
			coef = -1;
		else
			movement = regiter.AddExpense ();
			coef = 1;
		endif;
		movement.Period = date;
		movement.Contract = contract;
		movement.Document = row.Document;
		movement.Detail = row.Detail;
		movement.PaymentKey = row.PaymentKey;
		amount = row.AmountDebts;
		if ( row.Debt = 0 ) then
			movement.Overpayment = coef * amount;
		else
			movement.Amount = coef * amount;
		endif;
		if ( amount < 0 ) then
			movement.Payment = coef * Max ( amount, row.Payment );
			movement.Bill =  coef * Max ( amount, -row.Bill );
		else
			movement.Payment = coef * Min ( amount, row.Payment );
			movement.Bill =  coef * Min ( amount, -row.Bill );
		endif;
	enddo;
	
EndProcedure

Procedure changeDebt ( Env, Table, ForReceiver )
	
	fields = Env.Fields;
	if ( ForReceiver ) then
		isCustomer = fields.Option = Enums.AdjustmentOptions.Customer;
		contract = fields.ReceiverContract;
	else
		isCustomer = Env.Customer;
		contract = fields.Contract;
	endif;
	if ( isCustomer ) then
		regiter = Env.Registers.Debts;
		increaseDebt = fields.Type = Enums.TypesAdjustDebts.Advance;
	else
		regiter = Env.Registers.VendorDebts;
		increaseDebt = fields.Type = Enums.TypesAdjustDebts.Debt;
	endif;
	if ( ForReceiver ) then
		increaseDebt = not increaseDebt;
	endif;
	date = fields.Date;
	ref = Env.Ref;
	reversal = fields.Reversal;
	for each row in Table do
		if ( reversal ) then
			movement = regiter.AddExpense ();
			coef = -1;
		else
			movement = regiter.AddReceipt ();
			coef = 1;
		endif;
		movement.Period = date;
		movement.Contract = contract;
		movement.Document = ref;
		amount = row.Amount * coef;
		if ( increaseDebt ) then
			movement.PaymentKey = getPaymentKey ( Env, row.PaymentKey, row.PaymentOption, row.PaymentDate );
			movement.Amount = amount;
			movement.Payment = amount;
		else
			movement.Overpayment = amount;
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

Procedure commitAdjustments ( Env )
	
	reverseVAT = vatReversal ( Env, false );
	for each row in Env.Adjustments do
		if ( reverseVAT ) then
			reverseAdvance ( Env, row );
			reverseVAT ( Env, row );
		endif;
		commitDebt ( Env, row );
	enddo;
	for each row in Env.Accounting do
		commitDebt ( Env, row );
	enddo;

EndProcedure

Function vatReversal ( Env, ForReceiver )

	fields = Env.Fields;
	if ( ForReceiver ) then
		isCustomer = fields.Option = Enums.AdjustmentOptions.Customer;
		advance = fields.TypeReceiver = Enums.TypesAdjustDebts.Advance;
		advancesMonthly = fields.ReceiverAdvancesMonthly;
	else
		isCustomer = Env.Customer;
		advance = fields.Type = Enums.TypesAdjustDebts.Advance;
		advancesMonthly = fields.AdvancesMonthly;
	endif;
	return isCustomer and advance and fields.ApplyVAT and not advancesMonthly;

EndFunction

Procedure reverseAdvance ( Env, Row )
	
	fields = Env.Fields;
	coef = ? ( fields.Reversal, -1, 1 );
	p = GeneralRecords.GetParams ();
	date = fields.Date;
	p.Date = date;
	p.Company = fields.Company;
	drcr = Env.DrCr;
	sideOrganization = drcr.Organization;
	sideReceiver = drcr.Receiver;
	organization = fields.Organization;
	contract = fields.Contract;
	p [ "Account" + sideReceiver ] = fields.OrganizationAccount;
	p [ "Dim" + sideReceiver + "1" ] = organization;
	p [ "Dim" + sideReceiver + "2" ] = contract;
	p [ "Currency" + sideReceiver ] =  fields.Currency;
	p [ "CurrencyAmount" + sideReceiver ] = Row.AmountDocument * coef;
	p [ "Account" + sideOrganization ] = Row.AdvanceAccount;
	p [ "Dim" + sideOrganization + "1" ] = organization;
	p [ "Dim" + sideOrganization + "2" ] = contract;
	p [ "Currency" + sideOrganization ] = fields.ContractCurrency;
	p [ "CurrencyAmount" + sideOrganization ] = Row.Amount * coef;
	p.Amount = Row.AmountLocal * coef;
	p.Operation = drcr.Operation;
	p.Dependency = Row.PrepaymentRef;
	p.Recordset = Env.Buffer;
	GeneralRecords.Add ( p );
	
EndProcedure

Procedure reverseVAT ( Env, Row )
	
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	date = fields.Date;
	p.Date = date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.VATAdvancesReverse;
	p.AccountDr = Row.ReceivablesVATAccount;
	p.DimDr1 = fields.Organization;
	p.DimDr2 = fields.Contract;
	p.AccountCr = Row.PrepaymentVATAccount;
	p.Recordset = Env.Buffer;
	overpayment = Row.Amount;
	vatAmount = - overpayment + overpayment * ( 100 / ( 100 + Row.VATAdvanceRate ) );
	amount = Currencies.Convert ( vatAmount, fields.ContractCurrency, fields.LocalCurrency, date,
		fields.ContractRate, fields.ContractFactor, fields.Rate, fields.Factor );
	p.Amount = amount;
	payment = Row.PrepaymentRef;
	p.Content = String ( Enums.Operations.VATAdvancesReverse ) + ": " + payment; 
	p.Dependency = payment;
	GeneralRecords.Add ( p );

EndProcedure

Procedure commitDebt ( Env, Row )
	
	fields = Env.Fields;
	coef = ? ( fields.Reversal, -1, 1 );
	p = GeneralRecords.GetParams ();
	p.Recordset = Env.Buffer;
	date = fields.Date;
	p.Date = date;
	p.Company = fields.Company;
	drcr = Env.DrCr;
	sideOrganization = drcr.Organization;
	sideReceiver = drcr.Receiver;
	dim = "Dim" + sideReceiver;
	option = fields.Option;
	if ( option = Enums.AdjustmentOptions.Customer
		or option = Enums.AdjustmentOptions.Vendor ) then
		p [ "Account" + sideReceiver ] = fields.ReceiverAccount;
		p [ dim + "1" ] = fields.Receiver;
		p [ dim + "2" ] = fields.ReceiverContract;
	else
		p [ "Account" + sideReceiver ] = fields.Account;
		p [ dim + "1" ] = fields.Dim1;
		p [ dim + "2" ] = fields.Dim2;
		p [ dim + "3" ] = fields.Dim3;
	endif;
	p [ "Currency" + sideReceiver ] =  fields.Currency;
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

Procedure reverseReceiverAdvances ( Env )
	
	if ( not vatReversal ( Env, true ) ) then
		return;
	endif;
	for each row in Env.AdjustmentsReceiver do
		reverseAdvance ( Env, row );
		reverseVAT ( Env, row );
	enddo;

EndProcedure

Procedure makeExpenses ( Env ) 

	fields = Env.Fields;
	if ( not fields.IsExpense ) then
		return;
	endif;
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
	movement.AmountDr = Env.Adjustments.Total ( "Amount" );

EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	GeneralRecords.Flush ( registers.General, Env.Buffer, true );
	registers.General.Write = true;
	registers.Debts.Write = true;
	registers.VendorDebts.Write = true;
	registers.Expenses.Write = true;
	
EndProcedure
