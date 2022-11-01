#region Filling

&AtServer
Procedure fillNew ( Form )
	
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
	if ( type = Type ( "DocumentRef.Payment" ) ) then
		PaymentForm.SetVATAdvance ( object );
	endif;
	PaymentForm.SetAccount ( object );
	setCurrency ( object );
	setRates ( object );
	
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
Procedure fill ( Form )
	
	env = getEnv ( Form );
	object = Form.Object;
	getInvoiceData ( env );
	fillHeader ( Env );
	fillTable ( object );
	toggleDetails ( Form );
	fillAmounts ( object );
	calcContract ( object );
	calcApplied ( object );
	if ( TypeOf ( object.Ref ) = Type ( "DocumentRef.Payment" ) ) then
		PaymentForm.SetVATAdvance ( object );
	endif;
	PaymentForm.SetAccount ( object );
	setOrganizationAccounts ( object );
	
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
	setRates ( object );
	loadContract ( object );
	
EndProcedure

&AtServer
Procedure fillTable ( Object )
	
	payments = Object [ getTableName ( Object ) ];
	if ( Object.Contract.IsEmpty () ) then
		payments.Clear ();
		return;
	endif; 
	payments.Load ( getPayments ( Object ) );
	for each row in payments do
		calcDiscount ( row );
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
	q.SetParameter ( "Base", Object.Base );
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
	|	Balances.Detail as Detail,
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
	|order by PaymentDetails.Date, Balances.Document.Date
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
		calcAmount ( row );
		togglePay ( row );
	enddo; 
	
EndProcedure

#endregion

Procedure distributeAmount ( Object )
	
	table = Object [ getTableName ( Object ) ];
	amount = Object.ContractAmount;
	for each row in table do
		applied = Min ( row.Payment - row.Discount, amount );
		if ( applied <= 0 ) then
			continue;
		endif;
		row.Amount = applied;
		togglePay ( row );
		amount = amount - applied;
	enddo; 

EndProcedure

Procedure togglePay ( TableRow )
	
	TableRow.Pay = TableRow.Amount <> 0;
	
EndProcedure

Procedure calcContract ( Object )
	
	Object.ContractAmount = Currencies.Convert ( Object.Amount, Object.Currency, Object.ContractCurrency,
		Object.Date, Object.Rate, Object.Factor, Object.ContractRate, Object.ContractFactor );

EndProcedure 

Procedure CalcHandout ( Object ) export
	
	Object.IncomeTaxAmount = Object.Amount / 100 * Object.IncomeTaxRate;
	Object.Total = Object.Amount - Object.IncomeTaxAmount;
	
EndProcedure

Procedure calcApplied ( Object )
	
	applied = Object.Payments.Total ( "Amount" );
	if ( applied = 0 ) then
		Object.Applied = 0;
	elsif ( applied = Object.ContractAmount ) then
		Object.Applied = Object.Amount;
	else
		Object.Applied = Currencies.Convert ( applied, Object.ContractCurrency, Object.Currency, Object.Date,
			Object.ContractRate, Object.ContractFactor, Object.Rate, Object.Factor );
	endif;
	
EndProcedure 

Procedure calcDiscount ( TableRow )
	
	TableRow.Discount = TableRow.Payment / 100 * TableRow.DiscountRate;
	
EndProcedure

&AtClient
Procedure calcDiscountRate ( TableRow )
	
	discount = TableRow.Discount;
	amount = TableRow.Amount;
	TableRow.DiscountRate = 100 - 100 * ( amount / ( discount + amount ) );

EndProcedure

Procedure calcAmount ( TableRow )
	
	TableRow.Amount = Max ( 0, TableRow.Payment - TableRow.Discount );
	
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
Procedure setOrganizationAccounts ( Object )
	
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
Procedure setCurrency ( Object )
	
	method = Object.Method;
	if ( method = Enums.PaymentMethods.Cash
		or method.IsEmpty () ) then
		Object.Currency = DF.Pick ( Object.Contract, "Currency" );
	else
		Object.Currency = DF.Pick ( Object.BankAccount, "Currency" );
	endif; 

EndProcedure 

&AtServer
Procedure setRates ( Object )
	
	info = CurrenciesSrv.Get ( Object.Currency, Object.Date );
	Object.Rate = info.Rate;
	Object.Factor = info.Factor;
	
EndProcedure 

&AtServer
Procedure clean ( Table )
	
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
Procedure setContract ( Object )
	
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
Procedure loadContract ( Object )
	
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
	
	if ( not checkAmount ( Object ) ) then
		Cancel = true;
		return;
	endif;
	if ( not credits ( Object ) ) then
		CheckedAttributes.Add ( "Amount" );
	endif;
	if ( TypeOf ( Object.Ref ) = Type ( "DocumentRef.VendorPayment" ) ) then
		checkExpenseReport ( Object, CheckedAttributes );
		checkIncomeTax ( Object, CheckedAttributes );
	endif;
	
EndProcedure

Function checkAmount ( Object )
	
	if ( Object.Amount < Object.Applied ) then
		Output.PaymentError ( , "Amount" );
		return false;
	endif;
	return true;
	
EndFunction

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
Procedure setTitle ( Form )
	
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
Procedure toggleDetails ( Form )
	
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
Procedure refill ( Form )
	
	object = Form.Object;
	fillTable ( object );
	distributeAmount ( object );
	calcApplied ( object );
	toggleDetails ( Form );

EndProcedure

&AtServer
Procedure update ( Form )
	
	object = Form.Object;
	paid = fetchPaid ( object );
	fillTable ( object );
	toggleDetails ( Form );
	applyPayments ( object, paid );
	calcContract ( object );
	calcApplied ( object );

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
			togglePay ( row );
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
Procedure ApplyPay ( Object, Row ) export
	
	if ( Row.Pay ) then
		payment = Row.Payment - Row.Discount;
		if ( Object.Amount > 0 ) then
			Row.Amount = ? ( payment > 0, payment, - payment );
		else
			Row.Amount = ? ( payment > 0, - payment, payment );
		endif;
	else
		Row.Amount = 0;
	endif;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( CurrentObject, Form ) export
	
	passCopy ( CurrentObject, Form );
	clean ( CurrentObject.Payments );	

EndProcedure

&AtServer
Procedure passCopy ( CurrentObject, Form )
	
	if ( CurrentObject.IsNew () ) then
		CurrentObject.AdditionalProperties.Insert ( Enum.AdditionalPropertiesCopyOf (), Form.CopyOf ); 
	endif;

EndProcedure

&AtClient
Procedure ApplyContractRate ( Form ) export
	
	object = Form.Object;
	calcContract ( object );
	calcApplied ( object );
	updateInfo ( Form );
	
EndProcedure

Procedure updateInfo ( Form )
	
	object = Form.Object;
	difference = object.Amount - object.Applied;
	if ( difference = 0 ) then
		Form.Info = "";
	else
		Form.Info = Output.PaymentDifference ( new Structure ( "Amount", Conversion.NumberToMoney ( difference, object.Currency ) ) );
	endif;
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Form ) export
	
	object = Form.Object;
	calcContract ( object );
	distributeAmount ( object );
	calcApplied ( object );
	updateInfo ( Form );
	
EndProcedure

&AtServer
Procedure OnReadAtServer ( Form ) export
	
	PettyCash.Read ( Form );
	InvoiceForm.SetLocalCurrency ( Form );
	Constraints.ShowAccess ( Form );
	toggleDetails ( Form );
	updateInfo ( Form );
	Appearance.Apply ( Form );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Form ) export
	
	object = Form.Object;
	if ( object.Ref.IsEmpty () ) then
		InvoiceForm.SetLocalCurrency ( Form );
		DocumentForm.Init ( Object );
		params = Form.Parameters;
		if ( params.Basis = undefined ) then
			fillNew ( Form );
			fillByOrganization ( Form );
		else
			fill ( Form );
		endif; 
		Form.CopyOf = params.CopyingValue;
		updateInfo ( Form );
		Constraints.ShowAccess ( Form );
	endif; 
	PaymentForm.FilterAccount ( Form );
	setTitle ( Form );
	StandardButtons.Arrange ( Form );
	readAppearance ( Form );
	Appearance.Apply ( Form );
	
EndProcedure

&AtServer
Procedure readAppearance ( Form )

	type = TypeOf ( Form.Object.Ref );
	isPayment = type = Type ( "DocumentRef.Payment" );
	isRefund = type = Type ( "DocumentRef.Refund" );
	isVendorPayment = type = Type ( "DocumentRef.VendorPayment" );
	isVendorRefund = type = Type ( "DocumentRef.VendorRefund" );
	rules = new Array ();
	rules.Add ( "
	|Base show filled ( Object.Base );
	|Rate Factor enable Object.Currency <> LocalCurrency and Object.Currency <> Object.ContractCurrency;
	|ContractRate ContractFactor enable Object.ContractCurrency <> LocalCurrency;
	|BankAccount show Object.Method <> Enum.PaymentMethods.Cash;
	|Reference ReferenceDate PaymentContent show Object.Method <> Enum.PaymentMethods.Cash;
	|Warning UndoPosting show Object.Posted;
	|Header GroupDocuments GroupCurrency GroupMore lock Object.Posted;
	|GroupFill MarkAll1 UnmarkAll1 enable not Object.Posted
	|" );
	if ( isPayment or isRefund ) then
		rules.Add ( "
		|Customer Contract Company lock filled ( Object.Base );
		|" );
	else
		rules.Add ( "
		|Vendor Contract Company lock filled ( Object.Base );
		|" );
		if ( isVendorPayment ) then
			rules.Add ( "
			|Employee ExpenseReport show Object.Method = Enum.PaymentMethods.ExpenseReport;
			|Location show Object.Method <> Enum.PaymentMethods.ExpenseReport;
			|GroupIncomeTax show filled ( Object.IncomeTax );
			|" );
		endif;
	endif;
	if ( isVendorPayment or isRefund ) then
		rules.Add ( "
		|NewVoucher show empty ( Voucher ) and Object.Method = Enum.PaymentMethods.Cash;
		|Voucher FormVoucher show filled ( Voucher ) and Object.Method = Enum.PaymentMethods.Cash;
		|" );
	endif;
	if ( isPayment or isVendorRefund ) then
		rules.Add ( "
		|NewReceipt show empty ( Receipt ) and Object.Method = Enum.PaymentMethods.Cash
		|	and not field ( Object.Location, ""Register"" );
		|Receipt FormReceipt show filled ( Receipt ) and Object.Method = Enum.PaymentMethods.Cash;
		|" );
	endif;
	Appearance.Read ( Form, rules );

EndProcedure

&AtServer
Procedure fillByOrganization ( Form )
	
	params = Form.Parameters;
	object = Form.Object;
	type = TypeOf ( object );
	if ( type = Type ( "DocumentRef.Payment" )
		or type = Type ( "DocumentRef.Refund" )
	) then
		field = "Customer";
	else
		field = "Vendor";
	endif;
	apply = params.FillingValues.Property ( field )
	and params.CopyingValue.IsEmpty () 
	and not object [ field ].IsEmpty ();
	if ( apply ) then
		PaymentForm.ApplyOrganization ( Form );
		if ( type = Type ( "DocumentRef.VendorPayment" ) ) then
			fillByExpenseReport ( Form );
		endif;
	endif;
	
EndProcedure 

&AtServer
Procedure fillByExpenseReport ( Form )
	
	object = Form.Object;
	if ( not object.ExpenseReport.IsEmpty () ) then
		object.Method = Enums.PaymentMethods.ExpenseReport;
		PaymentForm.ApplyExpenseReport ( Form );
	endif;

EndProcedure 

&AtServer
Procedure ApplyExpenseReport ( Form ) export 
	
	object = Form.Object;
	data = DF.Values ( Object.ExpenseReport, "EmployeeAccount, Currency" );
	object.Account = data.EmployeeAccount;
	object.Currency = data.Currency;
	PaymentForm.ApplyCurrency ( Form );
	
EndProcedure

&AtServer
Procedure ApplyOrganization ( Form ) export
	
	object = Form.Object;
	setOrganizationAccounts ( object );
	setContract ( object );
	PaymentForm.ApplyContract ( Form );
	
EndProcedure

&AtServer
Procedure ApplyContract ( Form ) export
	
	object = Form.Object;
	loadContract ( object );
	PaymentForm.ApplyMethod ( Form );
	calcContract ( object );
	calcApplied ( object );
	setTitle ( Form );
	refill ( Form );
	updateInfo ( Form );
	Appearance.Apply ( Form, "Object.ContractCurrency" );
	
EndProcedure

&AtServer
Procedure ExecuteContract ( Object ) export
	
	loadContract ( Object );
	calcContract ( Object );
	fillTable ( Object );
	distributeAmount ( Object );
	calcApplied ( Object );
	clean ( Object.Payments );
	
EndProcedure

&AtServer
Procedure ApplyMethod ( Form ) export
	
	object = Form.Object;
	PaymentForm.SetBankAccount ( object );
	applyBankAccount ( Form );
	PaymentForm.FilterAccount ( Form );
	if ( TypeOf ( object.Ref ) = Type ( "DocumentRef.VendorPayment" ) ) then
		resetExpenseReport ( object );
	endif;
	Appearance.Apply ( Form, "Object.Method" );
	
EndProcedure

&AtServer
Procedure resetExpenseReport ( Object ) 
	
	if ( Object.Method <> Enums.PaymentMethods.ExpenseReport ) then
		Object.ExpenseReport = undefined;
	endif;
	
EndProcedure

&AtServer
Procedure ApplyBankAccount ( Form ) export
	
	object = Form.Object;
	setAccount ( object );
	setCurrency ( object );
	PaymentForm.ApplyCurrency ( Form );
	
EndProcedure 

&AtServer
Procedure ApplyCurrency ( Form ) export
	
	object = Form.Object;
	setRates ( object );
	applyRate ( Form );
	Appearance.Apply ( Form, "Object.Currency" );
	
EndProcedure 

Procedure applyRate ( Form )
	
	object = Form.Object;
	calcContract ( object );
	calcApplied ( object );
	distributeAmount ( object );
	updateInfo ( Form );
	
EndProcedure 

&AtServer
Procedure ApplyDataUpdate ( Form, Refilling ) export
	
	object = Form.Object;
	if ( Refilling ) then
		calcContract ( object );
		refill ( Form );
	else
		update ( Form );
	endif;
	updateInfo ( Form );
	Form.CurrentItem = Form.Items.Payments;

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( Form ) export
	
	PettyCash.Read ( Form );
	Appearance.Apply ( Form );
	
EndProcedure

&AtClient
Procedure AfterWrite ( Form ) export
	
	object = Form.Object;
	type = TypeOf ( object.Ref );
	if ( type = Type ( "DocumentRef.Payment" ) ) then
		Notify ( Enum.MessagePaymentIsSaved (), object );
	elsif ( type = Type ( "DocumentRef.Refund" ) ) then
		Notify ( Enum.MessageRefundIsSaved (), object );
	elsif ( type = Type ( "DocumentRef.VendorPayment" ) ) then
		Notify ( Enum.MessageVendorPaymentIsSaved (), object );
	elsif ( type = Type ( "DocumentRef.VendorRefund" ) ) then
		Notify ( Enum.MessageVendorRefundIsSaved (), object );
	endif;
	
EndProcedure

&AtServer
Procedure ApplyLocation ( Form ) export
	
	object = Form.Object;
	setAccount ( object );
	PaymentForm.FilterAccount ( Form );
	Appearance.Apply ( Form, "Object.Location" );
	
EndProcedure 

&AtClient
Procedure RateOnChange ( Form ) export
	
	object = Form.Object;
	if ( object.Rate = 0 ) then
		object.Rate = 1;
	endif;
	if ( object.Factor = 0 ) then
		object.Factor = 1;
	endif;
	applyRate ( Form );
	
EndProcedure

&AtClient
Procedure Mark ( Form, Flag ) export 

	object = Form.Object;
	for each row in object.Payments do
		if ( row.Pay = Flag ) then
			continue;
		endif;
		row.Pay = Flag;
		PaymentForm.ApplyPay ( object, row );
	enddo;
	calcContract ( object );
	calcApplied ( object );
	updateInfo ( Form );

EndProcedure

&AtClient
Procedure PaymentsDiscountRateOnChange ( Row ) export
	
	calcDiscount ( Row );
	calcAmount ( Row );
	
EndProcedure

&AtClient
Procedure PaymentsDiscountOnChange ( Row ) export
	
	calcDiscountRate ( Row );
	calcAmount ( Row );
	
EndProcedure

&AtClient
Procedure PaymentsOnEditEnd ( Form, Item, CancelEdit ) export
	
	if ( not CancelEdit ) then
		togglePay ( Item.CurrentData );
	endif;
	changeApplied ( Form );

EndProcedure

&AtClient
Procedure changeApplied ( Form )
	
	object = Form.Object;
	calcApplied ( object );
	updateInfo ( Form );
	
EndProcedure 

&AtClient
Procedure PaymentsAfterDeleteRow ( Form ) export
	
	changeApplied ( Form );

EndProcedure
