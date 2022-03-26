#region Filling

&AtServer
Procedure FillNew ( Form ) export
	
	p = Form.Parameters;
	if ( not p.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	object = Form.Object;
	settings = Logins.Settings ( "Company, PaymentLocation, PaymentLocation.CashFlow as CashFlow" );
	object.Company = settings.Company;
	object.Location = settings.PaymentLocation;
	object.CashFlow = settings.CashFlow;
	type = TypeOf ( object.Ref );
	if ( type = Type ( "DocumentRef.Payment" )
		or type = Type ( "DocumentRef.VendorRefund" ) ) then
		PaymentForm.SetVATAdvance ( object );
	endif;
	PaymentForm.SetAccount ( object );
	PaymentForm.SetCurrency ( object );
	PaymentForm.SetRates ( object );
	
EndProcedure

&AtServer
Procedure SetVATAdvance ( Object ) export
	
	accounts = AccountsMap.Item ( Catalogs.Items.EmptyRef (), Object.Company, Catalogs.Warehouses.EmptyRef (), "VAT" );
	Object.VATAccount = accounts.VAT;
	Object.ReceivablesVATAccount = receivablesVAT ();

EndProcedure

&AtServer
Function receivablesVAT ()

	s = "
	|select Settings.Value as Value
	|from InformationRegister.Settings.SliceLast ( ,
	|	Parameter = value ( ChartOfCharacteristicTypes.Settings.ReceivablesVATAccount )
	|) as Settings
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Value );
	
EndFunction

&AtServer
Procedure Fill ( Form ) export
	
	env = getEnv ( Form );
	object = Form.Object;
	type = env.BaseType;
	if ( type = Type ( "DocumentRef.Bill" )
		or type = Type ( "DocumentRef.VendorBill" ) ) then
		getBillData ( env );
	else
		getInvoiceData ( env );
	endif;
	fillHeader ( Env );
	PaymentForm.FillTable ( object );
	PaymentForm.ToggleDetails ( Form );
	fillAmounts ( object );
	PaymentForm.CalcContractAmount ( object, 2 );
	PaymentForm.CalcPaymentAmount ( object );
	type = TypeOf ( object.Ref );
	if ( type = Type ( "DocumentRef.Payment" )
		or type = Type ( "DocumentRef.VendorRefund" ) ) then
		PaymentForm.CalcAppliedAmount ( Object, 1 );
		PaymentForm.SetVATAdvance ( Object );
	endif;
	PaymentForm.SetAccount ( object );
	PaymentForm.SetOrganizationAccounts ( object );
	
EndProcedure

&AtServer
Function getEnv ( Form )
	
	object = Form.Object;
	p = Form.Parameters;
	base = p.Basis;
	env = new Structure ();
	env.Insert ( "Form", Form );
	env.Insert ( "Object", object );
	env.Insert ( "BaseType", TypeOf ( base ) );
	env.Insert ( "BaseName", base.Metadata ().Name );
	env.Insert ( "Base", base );
	SQL.Init ( env );
	return env;
	
EndFunction
 
&AtServer
Procedure getBillData ( Env )
	
	s = "
	|// @Fields
	|select Document.Company as Company, Document.Contract as Contract, Document.DiscountRate as DiscountRate,
	|	Document.Deposit as Deposit, Document.Deposit.Account as Account
	|";
	if ( Env.BaseType = Type ( "DocumentRef.Bill" ) ) then
		s = s + ", Document.Customer as Customer, Document.CustomerDeposit as CustomerDeposit";
	else
		s = s + ", Document.Vendor as Vendor, Document.VendorDeposit as VendorDeposit";
	endif; 
	s = s + "
	|from Document." + Env.BaseName + " as Document
	|where Document.Ref = &Bill
	|";
	Env.Selection.Add ( s );
	Env.Q.SetParameter ( "Bill", Env.Base );
	SQL.Prepare ( Env );
	Env.Insert ( "Data", Env.Q.ExecuteBatch () );
	SQL.Unload ( Env, Env.Data );
	
EndProcedure

&AtServer
Procedure fillHeader ( Env )
	
	settings = Logins.Settings ( "PaymentLocation, PaymentLocation.CashFlow as CashFlow" );
	object = Env.Object;
	object.Location = settings.PaymentLocation;
	object.CashFlow = settings.CashFlow;
	object.Base = Env.Base;
	FillPropertyValues ( object, Env.Fields );
	type = TypeOf ( object.Ref );
	if ( type = Type ( "DocumentRef.Payment" )
		or type = Type ( "DocumentRef.Refund" ) ) then
		Env.Object.Customer = Env.Fields.Customer;
	else
		Env.Object.Vendor = Env.Fields.Vendor;
	endif; 	
	PaymentForm.SetRates ( object );
	PaymentForm.LoadContract ( object );
	
EndProcedure

&AtServer
Procedure FillTable ( Object ) export
	
	payments = Object [ getTableName ( Object ) ];
	if ( Object.Contract.IsEmpty () ) then
		payments.Clear ();
		return;
	endif; 
	payments.Load ( getPayments ( Object ) );
	for each row in payments do
		PaymentForm.CalcDiscount ( row );
	enddo; 
	
EndProcedure

Function getTableName ( Object )
	
	type = TypeOf ( Object.Ref );
	if ( type = Type ( "DocumentRef.Payment" )
		or type = Type ( "DocumentRef.Refund" )
		or type = Type ( "DocumentRef.VendorPayment" )
		or type = Type ( "DocumentRef.VendorRefund" ) ) then
		return "Payments";
	else
		return "PaymentsByBase";
	endif; 
	
EndFunction

&AtServer
Function getPayments ( Object )
	
	s = sqlPayments ( Object );
	q = new Query ( s );
	date = Periods.GetDocumentDate ( Object );
	q.SetParameter ( "OperationDate", date );
	q.SetParameter ( "Period", EndOfDay ( date ) );
	q.SetParameter ( "Contract", Object.Contract );
	q.SetParameter ( "Currency", Object.ContractCurrency );
	q.SetParameter ( "Base", getBase ( Object.Base ) );
	name = Metadata.FindByType ( TypeOf ( Object.Ref ) ).Name;
	q.SetParameter ( "Types", Metadata.Documents [ name ].TabularSections.Payments.Attributes.Document.Type.Types () );
	if ( TypeOf ( Object.Ref ) = Type ( "DocumentRef.Payment" )
		or TypeOf ( Object.Ref ) = Type ( "DocumentRef.Refund" ) ) then
		q.SetParameter ( "Organization", Object.Customer );
	else
		q.SetParameter ( "Organization", Object.Vendor );
	endif;
	SetPrivilegedMode ( true );
	return q.Execute ().Unload ();
	
EndFunction

&AtServer
Function getBase ( Base )
	
	baseType = TypeOf ( Base );
	if ( baseType = Type ( "DocumentRef.Bill" )
		or baseType = Type ( "DocumentRef.VendorBill" ) ) then
		firstBase = DF.Pick ( Base, "Base" );
		if ( firstBase = undefined ) then
			return Base;
		else
			return firstBase;
		endif; 
	else
		return Base;
	endif; 
	
EndFunction

&AtServer
Function sqlPayments ( Object )
	
	objectType = TypeOf ( Object.Ref );
	refund = ( objectType = Type ( "DocumentRef.Refund" ) )
	or ( objectType = Type ( "DocumentRef.VendorRefund" ) );
	debts = objectType = Type ( "DocumentRef.Payment" )
	or objectType = Type ( "DocumentRef.Refund" );
	s = "
	|select Balances.Contract as Contract, Balances.Document as Document, Balances.PaymentKey as PaymentKey,
	|	" + ? ( refund, "- ", "" ) + "( Balances.PaymentBalance + Balances.OverpaymentBalance ) as Payment, 
	|	" + ? ( refund, "- ", "" ) + "Balances.AmountBalance as Debt,
	|	" + ? ( refund, "", "- " ) + "Balances.OverpaymentBalance as Advance,
	|	Balances.BillBalance as Bill, Balances.Detail as Detail,
	|	PaymentDetails.Option as Option, PaymentDetails.Date as Date, Discounts.Discount as DiscountRate
	|from AccumulationRegister." + ? ( debts, "Debts", "VendorDebts" ) + ".Balance ( ,
	|	( Contract = &Contract or ( Contract.Currency = &Currency and Contract.Owner.Chain = &Organization ) )";
	if ( ValueIsFilled ( Object.Base ) ) then
		s = s + " and &Base in ( Document, Detail )";
	endif; 
	s = s + " ) as Balances
	|	//
	|	// PaymentDetails
	|	//
	|	left join InformationRegister.PaymentDetails as PaymentDetails
	|	on PaymentDetails.PaymentKey = Balances.PaymentKey
	|	//
	|	// Discounts
	|	//
	|	left join Catalog.PaymentOptions.Discounts as Discounts
	|	on Balances.Contract.Company.EarlyPayments
	|	and Discounts.Ref = PaymentDetails.Option
	|	and PaymentDetails.Date <> datetime ( 3999, 12, 31 )
	|	and case when PaymentDetails.Date > &OperationDate then 0
	|			else datediff ( PaymentDetails.Date, &OperationDate, day )
	|		end
	|	between Discounts.Begin and Discounts.Edge
	|where ";
	if ( refund ) then
		s = s + "( Balances.OverpaymentBalance > 0 or Balances.PaymentBalance < 0 )";
	else
		s = s + "( Balances.OverpaymentBalance < 0 or Balances.PaymentBalance > 0 )";
	endif;
	s = s + "
	|and Balances.Document.Date <= &Period
	|and isnull ( Balances.Detail.Date, &Period ) <= &Period
	|and valuetype ( Balances.Document ) in ( &Types )
	|order by PaymentDetails.Date
	|";
	return s;
	
EndFunction

&AtServer
Procedure getInvoiceData ( Env )
	
	type = Env.BaseType;
	s = "
	|// @Fields
	|select Document.Company as Company, Document.Contract as Contract,
	|	Document.Contract.Currency as ContractCurrency, Document.Currency as Currency,
	|	case when Document.Contract.CustomerBank = value ( Catalog.BankAccounts.EmptyRef ) then
	|			Document.Contract.Company.BankAccount
	|		else Document.Contract.CustomerBank
	|	end as BankAccount
	|";
	if ( type = Type ( "DocumentRef.SalesOrder" )
		or type = Type ( "DocumentRef.Invoice" )
		or type = Type ( "DocumentRef.Return" ) ) then
		s = s + ", Customer as Customer, Document.Contract.CustomerPayment as Method";
	else
		s = s + ", Vendor as Vendor, Document.Contract.VendorPayment as Method";
	endif; 
	s = s + "
	|from Document." + Env.BaseName + " as Document
	|where Document.Ref = &Base
	|";
	Env.Selection.Add ( s );
	Env.Q.SetParameter ( "Base", Env.Base );
	SQL.Perform ( Env );
	
EndProcedure

&AtServer
Procedure fillAmounts ( Object )
	
	table = Object [ getTableName ( Object ) ];
	for each row in table do
		PaymentForm.CalcAmount ( row );
		PaymentForm.TogglePay ( row );
	enddo; 
	
EndProcedure

#endregion

Procedure DistributeAmount ( Object ) export
	
	table = Object [ getTableName ( Object ) ];
	j = table.Count () - 1;
	if ( j = -1 ) then
		return;
	endif; 
	amount = Object.ContractAmount;
	for i = 0 to j do
		row = table [ i ];
		payment = row.Payment - row.Discount;
		row.Amount = Min ( amount, payment );
		amount = amount - row.Amount;
		if ( i = j
			and amount > 0 ) then
			row.Amount = row.Amount + amount;
		endif; 
		PaymentForm.TogglePay ( row );
		PaymentForm.CalcOverpayment ( row );
	enddo; 

EndProcedure

Procedure TogglePay ( TableRow ) export
	
	TableRow.Pay = TableRow.Amount <> 0;
	
EndProcedure

Procedure CalcContractAmount ( Object, Method ) export
	
	if ( Method = 1
		or Object.Payments.Count () = 0 ) then
		Object.ContractAmount = Currencies.Convert ( Object.Amount, Object.Currency, Object.ContractCurrency, Object.Date, Object.Rate, Object.Factor, Object.ContractRate, Object.ContractFactor );
	elsif ( Method = 2 ) then
		Object.ContractAmount = Object.Payments.Total ( "Amount" );
	endif;

EndProcedure 

Procedure CalcPaymentAmount ( Object ) export
	
	Object.Amount = getPaymentAmount ( Object );
	if ( TypeOf ( Object.Ref ) = Type ( "DocumentRef.VendorPayment" ) ) then
		PaymentForm.CalcHandout ( Object );
	endif;
	
EndProcedure 

Procedure CalcHandout ( Object ) export
	
	Object.IncomeTaxAmount = Object.Amount / 100 * Object.IncomeTaxRate;
	Object.Total = Object.Amount - Object.IncomeTaxAmount;
	
EndProcedure

Function getPaymentAmount ( Object )
	
	return Currencies.Convert ( Object.ContractAmount, Object.ContractCurrency, Object.Currency, Object.Date, Object.ContractRate, Object.ContractFactor, Object.Rate, Object.Factor );
	
EndFunction

Procedure CalcAppliedAmount ( Object, Method ) export
	
	if ( Method = 1 ) then
		Object.Applied = Object.Amount;
	elsif ( Method = 2 ) then
		Object.Applied = getPaymentAmount ( Object );
	endif;
	
EndProcedure 

Procedure CalcDiscount ( TableRow ) export
	
	TableRow.Discount = TableRow.Payment / 100 * TableRow.DiscountRate;
	
EndProcedure

&AtClient
Procedure CalcDiscountRate ( TableRow ) export
	
	discount = TableRow.Discount;
	amount = TableRow.Amount;
	TableRow.DiscountRate = 100 - 100 * ( amount / ( discount + amount ) );

EndProcedure

Procedure CalcAmount ( TableRow ) export
	
	TableRow.Amount = Max ( 0, TableRow.Payment - TableRow.Discount );
	
EndProcedure

Procedure CalcOverpayment ( TableRow ) export
	
	payment = TableRow.Amount;
	debt = TableRow.Payment + TableRow.Discount;
	if ( payment = 0 ) then
		TableRow.Overpayment = 0;
	else
		TableRow.Overpayment = Max ( 0, payment - ? ( debt > 0, debt, - debt ) );
	endif;
	
EndProcedure 

&AtServer
Procedure SetAccount ( Object ) export
	
	method = Object.Method;
	if ( method.IsEmpty () ) then
		Object.Account = undefined;
	elsif ( method = Enums.PaymentMethods.ExpenseReport ) then
		account = DF.Pick ( Object.ExpenseReport, "EmployeeAccount" );
		Object.Account = account;
	else
		cash = Enums.PaymentMethods.Cash;
		locationAccount = not Object.Location.IsEmpty () and ( method = cash );
		if ( locationAccount ) then
			account = DF.Pick ( Object.Location, "Account" );
			if ( not account.IsEmpty () ) then
				Object.Account = account;
			endif; 
		else
			account = DF.Pick ( Object.BankAccount, "Account" );
			Object.Account = account;
		endif;
	endif;
	
EndProcedure 

&AtServer
Procedure SetOrganizationAccounts ( Object ) export
	
	type = TypeOf ( Object.Ref );
	if ( type = Type ( "DocumentRef.Payment" ) ) then
		accounts = AccountsMap.Organization ( Object.Customer, Object.Company, "CustomerAccount, AdvanceTaken" );
		Object.CustomerAccount = accounts.CustomerAccount;
		Object.AdvanceAccount = accounts.AdvanceTaken;
	elsif ( type = Type ( "DocumentRef.Refund" ) ) then
		accounts = AccountsMap.Organization ( Object.Customer, Object.Company, "CustomerAccount, AdvanceGiven" );
		Object.CustomerAccount = accounts.CustomerAccount;
		Object.AdvanceAccount = accounts.AdvanceGiven;
	elsif ( type = Type ( "DocumentRef.VendorPayment" ) ) then
		accounts = AccountsMap.Organization ( Object.Vendor, Object.Company, "VendorAccount, AdvanceGiven, IncomeTax" );
		Object.VendorAccount = accounts.VendorAccount;
		Object.AdvanceAccount = accounts.AdvanceGiven;
		Object.IncomeTaxAccount = accounts.IncomeTax;
	elsif ( type = Type ( "DocumentRef.VendorRefund" ) ) then
		accounts = AccountsMap.Organization ( Object.Vendor, Object.Company, "VendorAccount, AdvanceTaken" );
		Object.VendorAccount = accounts.VendorAccount;
		Object.AdvanceAccount = accounts.AdvanceTaken;
	endif; 
	
EndProcedure

&AtServer
Procedure SetBankAccount ( Object ) export
	
	method = Object.Method;
	if ( method = Enums.PaymentMethods.Cash
		or method.IsEmpty () ) then
		Object.BankAccount = undefined;
	elsif ( Object.BankAccount.IsEmpty () ) then
		Object.BankAccount = DF.Pick ( Object.Company, "BankAccount" );
	endif; 
	
EndProcedure 

&AtServer
Procedure SetCurrency ( Object ) export
	
	method = Object.Method;
	if ( method = Enums.PaymentMethods.Cash
		or method.IsEmpty () ) then
		Object.Currency = DF.Pick ( Object.Contract, "Currency" );
	else
		Object.Currency = DF.Pick ( Object.BankAccount, "Currency" );
	endif; 

EndProcedure 

&AtServer
Procedure SetRates ( Object ) export
	
	info = CurrenciesSrv.Get ( Object.Currency, Object.Date );
	Object.Rate = info.Rate;
	Object.Factor = info.Factor;
	
EndProcedure 

&AtServer
Procedure Clean ( Table ) export
	
	i = Table.Count ();
	while ( i > 0 ) do
		i = i - 1;
		row = Table [ i ];
		if ( row.Amount = 0 ) then
			Table.Delete ( i );
		endif; 
	enddo; 
	
EndProcedure

&AtServer
Procedure SetContract ( Object ) export
	
	type = TypeOf ( Object.Ref );
	if ( type = Type ( "DocumentRef.Payment" )
		or type = Type ( "DocumentRef.Refund" ) ) then
		data = DF.Values ( Object.Customer, "CustomerContract as Contract, CustomerContract.Company as Company" );
	else
		data = DF.Values ( Object.Vendor, "VendorContract as Contract, VendorContract.Company as Company" );
	endif;
	if ( data.Company = Object.Company ) then
		Object.Contract = data.Contract;
	endif; 
	
EndProcedure 

&AtServer
Procedure LoadContract ( Object ) export
	
	data = contractData ( Object );
	FillPropertyValues ( Object, data, , "CashFlow" );
	if ( Object.CashFlow.IsEmpty () ) then
		Object.CashFlow = data.CashFlow;
	endif;
	currency = contractCurrency ( Object, data );
	Object.ContractRate = currency.Rate;
	Object.ContractFactor = currency.Factor;
	
EndProcedure 

&AtServer
Function contractData ( Object )
	
	fields = new Array ();
	fields.Add ( "Currency as ContractCurrency" );
	type = TypeOf ( Object.Ref );
	payment = type = Type ( "DocumentRef.Payment" );
	if ( payment
		or type = Type ( "DocumentRef.Refund" ) ) then
		fields.Add ( "CustomerPayment as Method" );
		fields.Add ( "CustomerCashFlow as CashFlow" );
		fields.Add ( "CustomerRateType as ContractRateType" );
		fields.Add ( "CustomerRate as ContractRate" );
		fields.Add ( "CustomerFactor as ContractFactor" );
	else
		if ( Object.Method <> Enums.PaymentMethods.ExpenseReport ) then
			fields.Add ( "VendorPayment as Method" );
		endif;
		fields.Add ( "VendorCashFlow as CashFlow" );
		fields.Add ( "VendorRateType as ContractRateType" );
		fields.Add ( "VendorRate as ContractRate" );
		fields.Add ( "VendorFactor as ContractFactor" );
	endif;
	if ( payment ) then
		fields.Add ( "CustomerVATAdvance as VATAdvance" );
	elsif ( type = Type ( "DocumentRef.VendorRefund" ) ) then
		fields.Add ( "VendorVATAdvance as VATAdvance" );
	endif;
	return DF.Values ( Object.Contract, fields );
	
EndFunction

&AtServer
Function contractCurrency ( Object, Fields )
	
	result = undefined;
	if ( Fields.ContractRateType = Enums.CurrencyRates.Fixed ) then
		if ( ValueIsFilled ( Object.Base ) ) then
			result = DF.Values ( Object.Base, "Rate, Factor" );
		elsif ( Fields.ContractRate <> 0 ) then
			result = new Structure ( "Rate, Factor", Fields.ContractRate, Fields.ContractFactor )
		endif;
	endif;
	return ? ( result = undefined, CurrenciesSrv.Get ( Object.ContractCurrency, Object.Date ), result );
	
EndFunction

&AtClient
Procedure Show ( Item ) export
	
	value = undefined;
	name = Item.CurrentItem.Name;
	row = Item.CurrentData;
	if ( name = "PaymentsDocument" ) then
		value = row.Document;
	elsif ( name = "PaymentsDetail" ) then
		value = row.Detail;
	endif; 
	if ( ValueIsFilled ( value ) ) then
		ShowValue ( , value );
	endif; 
	
EndProcedure

&AtServer
Procedure Check ( Object, Cancel, CheckedAttributes ) export
	
	if ( not credits ( Object ) ) then
		CheckedAttributes.Add ( "Amount" );
	endif;
	if ( TypeOf ( Object.Ref ) = Type ( "DocumentRef.VendorPayment" ) ) then
		checkExpenseReport ( Object, CheckedAttributes );
		checkIncomeTax ( Object, CheckedAttributes );
	endif;
	
EndProcedure

&AtServer
Function credits ( Object )
	
	credit = 0;
	payment = 0;
	for each row in Object.Payments do
		amount = row.Amount;
		if ( amount > 0 ) then
			payment = payment + amount;
		else
			credit = credit + ( - amount );
		endif;
	enddo;
	return ( ( payment - credit ) = 0 ) and ( ( payment + credit ) <> 0 );
	
EndFunction

&AtServer
Procedure checkExpenseReport ( Object, CheckedAttributes )
	
	if ( Object.Method = Enums.PaymentMethods.ExpenseReport ) then
		CheckedAttributes.Add ( "ExpenseReport" );
	endif; 
	
EndProcedure 

&AtServer
Procedure checkIncomeTax ( Object, CheckedAttributes )
	
	if ( not Object.IncomeTax.IsEmpty () ) then
		CheckedAttributes.Add ( "IncomeTaxAccount" );
	endif; 
	
EndProcedure 

&AtServer
Procedure SetTitle ( Form ) export
	
	object = Form.Object;
	items = Form.Items;
	title = object.Ref.Metadata ().TabularSections.Payments.Attributes.Amount.Presentation ();
	currency = object.ContractCurrency;
	items.PaymentsAmount.Title = title + ? ( currency.IsEmpty (), "", ", " + currency );
	
EndProcedure 

&AtServer
Procedure FilterAccount ( Form ) export
	
	object = Form.Object;
	items = Form.Items;
	method = object.Method;
	if ( method = Enums.PaymentMethods.ExpenseReport ) then
		class = Enums.Accounts.OtherCurrentAssets;
	elsif ( method = Enums.PaymentMethods.Cash ) then
		class = Enums.Accounts.Cash;
	else
		class = Enums.Accounts.Bank;
	endif;
	filter = new ChoiceParameter ( "Filter.Class", class );
	if ( items.Account.ChoiceParameters.Find ( filter ) = undefined ) then
		list = new Array ();
		list.Add ( filter );
		list.Add ( new ChoiceParameter ( "Filter.Folder", false ) );
		list.Add ( new ChoiceParameter ( "Filter.Offline", false ) );
		items.Account.ChoiceParameters = new FixedArray ( list );
	endif; 
	
EndProcedure 

&AtServer
Procedure ToggleDetails ( Form ) export
	
	object = Form.Object;
	type = TypeOf ( object.Ref );
	if ( type = Type ( "DocumentRef.Payment" )
		or type = Type ( "DocumentRef.VendorPayment" )
		or type = Type ( "DocumentRef.Refund" ) 
		or type = Type ( "DocumentRef.VendorRefund" ) ) then
	else
		return;
	endif; 
	visible = false;
	for each row in object.Payments do
		if ( row.Detail <> undefined ) then
			visible = true;
			break;
		endif;
	enddo;
	Form.Items.PaymentsDetail.Visible = visible;
	
EndProcedure

&AtServer
Procedure Refill ( Form ) export
	
	object = Form.Object;
	PaymentForm.FillTable ( object );
	PaymentForm.DistributeAmount ( object );
	PaymentForm.ToggleDetails ( Form );

EndProcedure

&AtServer
Procedure Update ( Form ) export
	
	object = Form.Object;
	paid = fetchPaid ( object );
	PaymentForm.FillTable ( object );
	PaymentForm.ToggleDetails ( Form );
	applyPayments ( object, paid );
	PaymentForm.CalcContractAmount ( object, 2 );
	if ( TypeOf ( object.Ref ) = Type ( "DocumentRef.Payment" )
		or TypeOf ( object.Ref ) = Type ( "DocumentRef.VendorRefund" ) ) then
		PaymentForm.CalcAppliedAmount ( object, 2 );
	endif;

EndProcedure

&AtServer
Function fetchPaid ( Object )
	
	paid = new Array ();
	for each row in Object.Payments do
		if ( row.Pay ) then
			payment = new Structure ( "Contract, Document, Detail, Date, Option" );
			FillPropertyValues ( payment, row );
			paid.Add ( new Structure ( "Key, Amount", payment, row.Amount ) );
		endif;
	enddo;
	return paid;
	
EndFunction

&AtServer
Procedure applyPayments ( Object, Paid )
	
	payments = Object.Payments;
	for each payment in Paid do
		rows = payments.FindRows ( payment.Key );
		if ( rows.Count () = 0 ) then
			paymentNotFound ( payment );
		else
			row = rows [ 0 ];
			row.Amount = payment.Amount;
			PaymentForm.CalcOverpayment ( row );
			PaymentForm.TogglePay ( row );
		endif;
	enddo;
	
EndProcedure

&AtServer
Procedure paymentNotFound ( Payment )
	
	data = Payment.Key;
	s = Conversion.ValuesToString ( data.Document, data.Detail, data.Date, data.Option );
	Output.PaymentNotFound ( new Structure ( "Payment, Amount", s, Payment.Amount ) );
	
EndProcedure

&AtClient
Procedure ApplyPay ( Form ) export
	
	object = Form.Object;
	paymentsRow = Form.PaymentsRow;
	if ( paymentsRow.Pay ) then
		debt = paymentsRow.Payment - paymentsRow.Discount;
		if ( TypeOf ( object.Ref ) = Type ( "DocumentRef.Payment" )
			or TypeOf ( object.Ref ) = Type ( "DocumentRef.VendorRefund" ) ) then
			rest = object.Amount - object.Applied;
			rest = Currencies.Convert ( rest, object.Currency, object.ContractCurrency, object.Date, object.Rate, object.Factor, object.ContractRate, object.ContractFactor );
			if ( rest > 0 ) then
				if ( debt > 0 ) then
					amount = Max ( 0, Min ( rest, debt ) )
				else
					amount = debt;
				endif;
			else
				amount = debt;
			endif;
		else
			amount = Max ( 0, debt );
		endif;
		paymentsRow.Amount = amount;
	else
		paymentsRow.Amount = 0;
	endif;
	PaymentForm.CalcOverpayment ( paymentsRow );
	
EndProcedure
