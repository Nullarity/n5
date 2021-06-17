
&AtServer
Procedure OnReadAtServer ( Form ) export
	
	InvoiceForm.SetLocalCurrency ( Form );
	toggleDetails ( Form );
	updateInfo ( Form );
	readAccount ( Form );
	labelDims ( Form );
	setReceiverOptions ( Form );
	if ( Form.UseReceiver ) then
		toggleReceiverDetails ( Form );
		updateInfoReceiver ( Form );
	endif;
	Appearance.Apply ( Form );

EndProcedure

&AtServer
Procedure toggleDetails ( Form )
	
	visible = false;
	for each row in Form.Object.Adjustments do
		if ( row.Detail <> undefined ) then
			visible = true;
			break;
		endif;
	enddo;
	Form.Items.AdjustmentsDetail.Visible = visible;
	
EndProcedure

Procedure updateInfo ( Form )
	
	object = Form.Object;
	difference = object.Amount - object.Applied;
	if ( difference = 0 ) then
		Form.Info = "";
	else
		Form.Info = Output.AdjustDebtsDifference ( new Structure ( "Amount", Conversion.NumberToMoney ( difference, object.Currency ) ) );
	endif;
	
EndProcedure

&AtServer
Procedure readAccount ( Form )
	
	Form.AccountData = GeneralAccounts.GetData ( Form.Object.Account );
	Form.AccountLevel = Form.AccountData.Fields.Level;
	
EndProcedure 

&AtServer
Procedure labelDims ( Form )
	
	i = 1;
	items = Form.Items;
	for each dim in Form.AccountData.Dims do
		items [ "Dim" + i ].Title = dim.Presentation;
		i = i + 1;
	enddo; 
	
EndProcedure 

&AtServer
Procedure setReceiverOptions ( Form ) 

	if ( isAdjustDebts ( Form ) ) then
		setReceiverOptionsCustomer ( Form );
	else
		setReceiverOptionsVendor ( Form );
	endif;

EndProcedure

&AtServer
Function isAdjustDebts ( Form ) 

	return TypeOf ( Form.Object.Ref ) = Type ( "DocumentRef.AdjustDebts" );

EndFunction

&AtServer
Procedure setReceiverOptionsCustomer ( Form ) 

	option = Form.Object.Option;
	adjustmentOptions = Enums.AdjustmentOptions;
	Form.ReceiverCustomer = ( option = adjustmentOptions.Customer );
	Form.UseReceiver = ( Form.ReceiverCustomer
	or option = adjustmentOptions.Vendor );

EndProcedure

&AtServer
Procedure setReceiverOptionsVendor ( Form ) 

	option = Form.Object.Option;
	adjustmentOptions = Enums.AdjustmentOptions;
	Form.ReceiverVendor = ( option = adjustmentOptions.Vendor );
	Form.UseReceiver = ( Form.ReceiverVendor
	or option = adjustmentOptions.Customer );

EndProcedure

&AtServer
Procedure toggleReceiverDetails ( Form )
	
	visible = false;
	for each row in Form.Object.ReceiverDebts do
		if ( row.Detail <> undefined ) then
			visible = true;
			break;
		endif;
	enddo;
	Form.Items.ReceiverDebtsDetail.Visible = visible;
	
EndProcedure

Procedure updateInfoReceiver ( Form )
	
	object = Form.Object;
	difference = object.Amount - object.AppliedReceiver;
	if ( difference = 0 ) then
		Form.InfoReceiver = "";
	else
		Form.InfoReceiver = Output.AdjustDebtsDifference ( new Structure ( "Amount", Conversion.NumberToMoney ( difference, object.Currency ) ) );
	endif;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Form ) export
	
	object = Form.Object;
	if ( object.Ref.IsEmpty () ) then
		InvoiceForm.SetLocalCurrency ( Form );
		DocumentForm.Init ( object );
		setReceiverOptions ( Form );
		fillNew ( Form );
		fillByOrganization ( Form );
		updateInfo ( Form );
	endif; 
	filterAccount ( Form );
	setTitle ( Form );
	if ( Form.UseReceiver ) then
		filterReceiver ( Form );
		filterReceiverAccount ( Form );
		setReceiverCaption ( Form );
	endif;
	StandardButtons.Arrange ( Form );
	readAppearance ( Form );
	Appearance.Apply ( Form );
	
EndProcedure

&AtServer
Procedure readAppearance ( Form )

	rules = new Array ();
	rules.Add ( "
	|Rate Factor enable Object.Currency <> LocalCurrency;
	|ContractRate ContractFactor enable Object.ContractCurrency <> Object.Currency and Object.ContractCurrency <> LocalCurrency;
	|Dim1 show ( AccountLevel > 0 and not UseReceiver );
	|Dim2 show ( AccountLevel > 1 and not UseReceiver );
	|Dim3 show ( AccountLevel > 2 and not UseReceiver );
	|Receiver ReceiverContract ReceiverAccount ReceiverCurrencyGroup GroupReceiverDebts show UseReceiver;
	|GroupReceiverDebts enable UseReceiver and filled ( Object.Receiver ) and filled ( Object.ReceiverContract );
	|Account show not UseReceiver;
	|ReceiverContractRate ReceiverContractFactor enable
	|	Object.ReceiverContractCurrency <> Object.Currency
	|	and Object.ReceiverContractCurrency <> LocalCurrency
	|	and filled ( Object.ReceiverContractCurrency );
	|Warning UndoPosting show Object.Posted;
	|Header Adjustments ReceiverDebts GroupMore GroupCurrency lock Object.Posted;
	|GroupFillDocuments GroupFillReceiver MarkAll1 UnmarkAll1 MarkAllReceiver1 UnmarkAllReceiver1 enable not Object.Posted
	|" );
	Appearance.Read ( Form, rules );

EndProcedure

&AtServer
Procedure fillNew ( Form )
	
	if ( not Form.Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	object = Form.Object;
	object.Company = settings.Company;
	object.Currency = DF.Pick ( object.Contract, "Currency" );
	setRates ( object );
	
EndProcedure

&AtServer
Procedure setRates ( Object )
	
	data = CurrenciesSrv.Get ( Object.Currency, Object.Date );
	Object.Rate = data.Rate;
	Object.Factor = data.Factor;

EndProcedure 

&AtServer
Procedure fillByOrganization ( Form )
	
	if ( isAdjustDebts ( Form ) ) then
		fillByCustomer ( Form );	
	else
		fillByVendor ( Form );
	endif;
	
EndProcedure 

&AtServer
Procedure fillByCustomer ( Form )
	
	params = Form.Parameters;
	apply = params.FillingValues.Property ( "Customer" )
	and params.CopyingValue.IsEmpty () 
	and not Form.Object.Customer.IsEmpty ();
	if ( apply ) then
		AdjustDebtsForm.ApplyCustomer ( Form );
	endif;
	
EndProcedure 

&AtServer
Procedure ApplyCustomer ( Form ) export
	
	object = Form.Object;
	setCustomerAccount ( object );
	setCustomerContract ( object );
	AdjustDebtsForm.ApplyContract ( Form );
	
EndProcedure

&AtServer
Procedure setCustomerAccount ( Object )
	
	accounts = AccountsMap.Organization ( Object.Customer, Object.Company, "CustomerAccount" );
	Object.CustomerAccount = accounts.CustomerAccount;
	
EndProcedure

&AtServer
Procedure setCustomerContract ( Object )
	
	data = DF.Values ( Object.Customer, "CustomerContract as Contract, CustomerContract.Company as Company" );
	if ( data.Company = Object.Company ) then
		Object.Contract = data.Contract;
	endif; 
	
EndProcedure 

&AtServer
Procedure ApplyContract ( Form ) export
	
	loadContract ( Form );
	setTitle ( Form );
	refill ( Form );
	updateInfo ( Form );
	Appearance.Apply ( Form, "Object.ContractCurrency" );
	
EndProcedure

&AtServer
Procedure loadContract ( Form )
	
	object = Form.Object;
	fields = new Array ();
	fields.Add ( "Currency" );
	if ( isAdjustDebts ( Form ) ) then
		fields.Add ( "CustomerRateType as RateType" );
		fields.Add ( "CustomerRate as Rate" );
		fields.Add ( "CustomerFactor as Factor" );
	else
		fields.Add ( "VendorRateType as RateType" );
		fields.Add ( "VendorRate as Rate" );
		fields.Add ( "VendorFactor as Factor" );
	endif;
	data = DF.Values ( object.Contract, StrConcat ( fields, "," ) );
	contractCurrency = data.Currency;
	object.ContractCurrency = contractCurrency;
	if ( data.RateType = Enums.CurrencyRates.Fixed
		and data.Rate <> 0 ) then
		currency = new Structure ( "Rate, Factor", data.Rate, data.Factor );
	else
		currency = CurrenciesSrv.Get ( contractCurrency, Object.Date );
	endif;
	Object.ContractRate = currency.Rate;
	Object.ContractFactor = currency.Factor;
	Object.Currency = contractCurrency;
	AdjustDebtsForm.ApplyCurrency ( Form );

EndProcedure

&AtServer
Procedure loadVendorContract ( Form )
	
	object = Form.Object;
	data = DF.Values ( object.Contract, "Currency, CustomerRateType, CustomerRate, CustomerFactor" );
	contractCurrency = data.Currency;
	object.ContractCurrency = contractCurrency;
	if ( data.CustomerRateType = Enums.CurrencyRates.Fixed
		and data.CustomerRate <> 0 ) then
		currency = new Structure ( "Rate, Factor", data.CustomerRate, data.CustomerFactor );
	else
		currency = CurrenciesSrv.Get ( contractCurrency, Object.Date );
	endif;
	Object.ContractRate = currency.Rate;
	Object.ContractFactor = currency.Factor;
	Object.Currency = contractCurrency;
	AdjustDebtsForm.ApplyCurrency ( Form );

EndProcedure

&AtServer
Procedure ApplyCurrency ( Form ) export
	
	setRates ( Form.Object );
	applyRate ( Form );
	if ( Form.UseReceiver ) then
		applyReceiverRate ( Form );
	endif;
	Appearance.Apply ( Form, "Object.Currency" );
	
EndProcedure 

Procedure applyRate ( Form )
	
	object = Form.Object;
	calcContract ( object, 1 );
	calcApplied ( object, 1 );
	distributeAmount ( object );
	updateInfo ( Form );
	
EndProcedure

Procedure calcContract ( Object, Method )
	
	if ( Method = 1
		or Object.Adjustments.Count () = 0 ) then
		Object.ContractAmount = Currencies.Convert ( Object.Amount, Object.Currency, Object.ContractCurrency, Object.Date, Object.Rate, Object.Factor, Object.ContractRate, Object.ContractFactor );
	elsif ( Method = 2 ) then
		Object.ContractAmount = Object.Adjustments.Total ( "Amount" );
	endif;

EndProcedure 

Procedure calcApplied ( Object, Method )
	
	if ( Method = 1 ) then
		Object.Applied = Object.Amount;
	elsif ( Method = 2 ) then
		Object.Applied = getPaymentAmount ( Object );
	endif;
	
EndProcedure

Function getPaymentAmount ( Object )
	
	return Currencies.Convert ( Object.ContractAmount, Object.ContractCurrency, Object.Currency, Object.Date, Object.ContractRate, Object.ContractFactor, Object.Rate, Object.Factor );
	
EndFunction

Procedure distributeAmount ( Object )
	
	table = Object.Adjustments;
	j = table.Count () - 1;
	if ( j = -1 ) then
		return;
	endif; 
	amount = Object.ContractAmount;
	isDebt = isDebt ( Object.Type );
	for i = 0 to j do
		row = table [ i ];
		applied = Min ( amount, appliedAmountRow ( row, isDebt ) );
		row.Amount = applied;
		amount = amount - applied;
		if ( i = j
			and amount > 0 ) then
			rest = Currencies.Convert ( amount, Object.ContractCurrency, Object.Currency, Object.Date, Object.ContractRate, Object.ContractFactor, Object.Rate, Object.Factor );
			Object.Applied = Object.Applied - rest;
		endif; 
		toggleAdjust ( row );
	enddo; 

EndProcedure

Function isDebt ( Type ) 

	return Type = PredefinedValue ( "Enum.TypesAdjustDebts.Debt" );

EndFunction

Function appliedAmountRow ( TableRow, IsDebt ) 

	if ( IsDebt ) then
		if ( TableRow.Debt = 0 ) then
			return -TableRow.Overpayment;
		else
			return TableRow.Debt;
		endif;
	else
		if ( TableRow.Overpayment = 0 ) then
			return -TableRow.Debt;
		else
			return TableRow.Overpayment;
		endif;
	endif;

EndFunction

Procedure toggleAdjust ( TableRow )
	
	TableRow.Adjust = TableRow.Amount <> 0;
	
EndProcedure

Procedure applyReceiverRate ( Form )
	
	object = Form.Object;
	calcReceiverContract ( object, 1 );
	calcAppliedReceiver ( object, 1 );
	distributeReceiverAmount ( object );
	updateInfoReceiver ( Form );
	
EndProcedure

Procedure calcReceiverContract ( Object, Method )
	
	if ( Method = 1
		or Object.ReceiverDebts.Count () = 0 ) then
		Object.ReceiverContractAmount = Currencies.Convert ( Object.Amount, Object.Currency, Object.ReceiverContractCurrency, Object.Date, Object.Rate, Object.Factor, Object.ReceiverContractRate, Object.ReceiverContractFactor );
	elsif ( Method = 2 ) then
		Object.ReceiverContractAmount = Object.ReceiverDebts.Total ( "Amount" );
	endif;

EndProcedure 

Procedure calcAppliedReceiver ( Object, Method )
	
	if ( Method = 1 ) then
		Object.AppliedReceiver = Object.Amount;
	elsif ( Method = 2 ) then
		Object.AppliedReceiver = Currencies.Convert ( Object.ReceiverContractAmount, Object.ReceiverContractCurrency,
			Object.Currency, Object.Date, Object.ReceiverContractRate, Object.ReceiverContractFactor,
			Object.Rate, Object.Factor );
	endif;
	
EndProcedure

Procedure distributeReceiverAmount ( Object )
	
	table = Object.ReceiverDebts;
	j = table.Count () - 1;
	if ( j = -1 ) then
		return;
	endif; 
	amount = Object.ReceiverContractAmount;
	isDebt = isDebt ( Object.TypeReceiver );
	for i = 0 to j do
		row = table [ i ];
		applied = Min ( amount, appliedAmountRow ( row, isDebt ) );
		row.Amount = applied;
		row.Applied = applied;
		amount = amount - applied;
		if ( i = j ) then
			row.Amount = row.Amount + amount;
			row.Difference = amount;
		else
			row.Difference = 0;
		endif; 
		toggleAdjust ( row );
	enddo; 

EndProcedure

&AtServer
Procedure setTitle ( Form )
	
	presentation = Metadata.Documents.AdjustDebts.TabularSections.Adjustments.Attributes.Amount.Presentation ();
	currency = Form.Object.ContractCurrency;
	Form.Items.AdjustmentsAmount.Title = presentation + ? ( currency.IsEmpty (), "", ", " + currency );
	
EndProcedure 

&AtServer
Procedure refill ( Form )
	
	fillTable ( Form );
	distributeAmount ( Form.Object );
	
EndProcedure

&AtServer
Procedure fillTable ( Form )
	
	object = Form.Object;
	adjustments = object.Adjustments;
	if ( object.Contract.IsEmpty () ) then
		adjustments.Clear ();
		return;
	endif; 
	adjustments.Load ( getPayments ( Form ) );
	toggleDetails ( Form );
	
EndProcedure

&AtServer
Function getPayments ( Form )
	
	object = Form.Object;
	if ( isAdjustDebts ( Form ) ) then
		tableName = "Debts";
		organization = object.Customer;
	else
		tableName = "VendorDebts";
		organization = object.Vendor;
	endif;
	s = sqlPayments ( object.Type, tableName );
	q = new Query ( s );
	date = Periods.GetDocumentDate ( object );
	q.SetParameter ( "Period", EndOfDay ( date ) );
	q.SetParameter ( "Contract", object.Contract );
	q.SetParameter ( "Currency", object.ContractCurrency );
	q.SetParameter ( "Organization", organization );
	return q.Execute ().Unload ();
	
EndFunction

&AtServer
Function sqlPayments ( Type, TableName )
	
	s = "
	|select Balances.Contract as Contract, Balances.Document as Document, Balances.PaymentKey as PaymentKey,
	|	Balances.PaymentBalance as Payment, Balances.AmountBalance as Debt, Balances.OverpaymentBalance as Overpayment,
	|	Balances.BillBalance as Bill, Balances.Detail as Detail,
	|	PaymentDetails.Option as Option, PaymentDetails.Date as Date
	|from AccumulationRegister." + TableName + ".Balance ( ,
	|	( Contract = &Contract or ( Contract.Currency = &Currency and Contract.Owner.Chain = &Organization ) ) ) as Balances
	|	//
	|	// PaymentDetails
	|	//
	|	left join InformationRegister.PaymentDetails as PaymentDetails
	|	on PaymentDetails.PaymentKey = Balances.PaymentKey
	|where ( Balances.AmountBalance <> 0 
	|	or Balances.OverpaymentBalance <> 0 )
	|and Balances.Document.Date <= &Period
	|and isnull ( Balances.Detail.Date, &Period ) <= &Period
	|and ";
	if ( Type = Enums.TypesAdjustDebts.Debt ) then
		s = s + "( Balances.AmountBalance > 0 ) or ( Balances.OverpaymentBalance < 0 )";
	else
		s = s + "( Balances.AmountBalance < 0 ) or ( Balances.OverpaymentBalance > 0 )";
	endif;
	s = s + "
	|order by PaymentDetails.Date
	|";
	return s;
	
EndFunction

&AtServer
Procedure fillByVendor ( Form )
	
	params = Form.Parameters;
	apply = params.FillingValues.Property ( "Vendor" )
	and params.CopyingValue.IsEmpty () 
	and not Form.Object.Vendor.IsEmpty ();
	if ( apply ) then
		AdjustDebtsForm.ApplyVendor ( Form );
	endif;
	
EndProcedure 

&AtServer
Procedure ApplyVendor ( Form ) export
	
	object = Form.Object;
	setVendorAccount ( object );
	setVendorContract ( object );
	AdjustDebtsForm.ApplyContract ( Form );
	
EndProcedure

&AtServer
Procedure setVendorAccount ( Object )
	
	accounts = AccountsMap.Organization ( Object.Vendor, Object.Company, "VendorAccount" );
	Object.VendorAccount = accounts.VendorAccount;
	
EndProcedure

&AtServer
Procedure setVendorContract ( Object )
	
	data = DF.Values ( Object.Vendor, "VendorContract as Contract, VendorContract.Company as Company" );
	if ( data.Company = Object.Company ) then
		Object.Contract = data.Contract;
	endif; 
	
EndProcedure 

&AtServer
Procedure filterAccount ( Form )
	
	if ( Form.UseReceiver ) then
		return;
	endif;
	option = Form.Object.Option;
	adjustOptions = Enums.AdjustmentOptions;
	accounts = Enums.Accounts;
	values = new Array ();
	if ( option = adjustOptions.Income ) then
		values.Add ( accounts.Income );
		values.Add ( accounts.OtherIncome );
	elsif ( option = adjustOptions.Expenses ) then
		values.Add ( accounts.Expenses );
		values.Add ( accounts.OtherExpenses );
		values.Add ( accounts.CostOfGoodsSold );
	endif;
	list = new Array ();
	if ( values.Count () > 0 ) then
		list.Add ( new ChoiceParameter ( "Filter.Class", new FixedArray ( values ) ) );
		clearAccount ( Form, values );
	endif;
	list.Add ( new ChoiceParameter ( "Filter.Folder", false ) );
	list.Add ( new ChoiceParameter ( "Filter.Offline", false ) );
	Form.Items.Account.ChoiceParameters = new FixedArray ( list );
	
EndProcedure

&AtServer
Procedure clearAccount ( Form, Accounts ) 

	object = Form.Object;
	if ( Accounts.Find ( DF.Pick ( object.Account, "Class" ) ) = undefined ) then
		object.Account = undefined;
		AdjustDebtsForm.ApplyAccount ( Form );
	endif;

EndProcedure

&AtServer
Procedure ApplyAccount ( Form ) export
	
	readAccount ( Form );
	adjustDims ( Form.AccountData, Form.Object );
	labelDims ( Form );
	Appearance.Apply ( Form, "AccountLevel" );
	      	
EndProcedure

&AtServer
Procedure adjustDims ( Data, Target )
	
	fields = Data.Fields;
	dims = Data.Dims;
	level = fields.Level;
	if ( level = 0 ) then
		Target.Dim1 = null;
		Target.Dim2 = null;
		Target.Dim3 = null;
	elsif ( level = 1 ) then
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = null;
		Target.Dim3 = null;
	elsif ( level = 2 ) then
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = dims [ 1 ].ValueType.AdjustValue ( Target.Dim2 );
		Target.Dim3 = null;
	else
		Target.Dim1 = dims [ 0 ].ValueType.AdjustValue ( Target.Dim1 );
		Target.Dim2 = dims [ 1 ].ValueType.AdjustValue ( Target.Dim2 );
		Target.Dim3 = dims [ 2 ].ValueType.AdjustValue ( Target.Dim3 );
	endif; 

EndProcedure 

&AtServer
Procedure filterReceiver ( Form ) 

	param = new ChoiceParameter ( ? ( isReceiverCustomer ( Form ), "Filter.Customer", "Filter.Vendor" ), true );
	list = new Array ();
	list.Add ( param );
	items = Form.Items;
	items.Receiver.ChoiceParameters = new FixedArray ( list );
	items.ReceiverContract.ChoiceParameters = new FixedArray ( list );

EndProcedure

&AtServer
Function isReceiverCustomer ( Form ) 

	if ( isAdjustDebts ( Form ) ) then
		return Form.ReceiverCustomer;
	else
		return not Form.ReceiverVendor;
	endif;

EndFunction

&AtServer
Procedure filterReceiverAccount ( Form )
	
	list = new Array ();
	class = ? ( isReceiverCustomer ( Form ), Enums.Accounts.AccountsReceivable, Enums.Accounts.AccountsPayable );
	list.Add ( new ChoiceParameter ( "Filter.Class", class ) );
	list.Add ( new ChoiceParameter ( "Filter.Folder", false ) );
	list.Add ( new ChoiceParameter ( "Filter.Offline", false ) );
	Form.Items.ReceiverAccount.ChoiceParameters = new FixedArray ( list );
	
EndProcedure

&AtServer
Procedure setReceiverCaption ( Form )
	
	presentation = Metadata.Documents.AdjustDebts.TabularSections.ReceiverDebts.Attributes.Amount.Presentation ();
	currency = Form.Object.ReceiverContractCurrency;
	Form.Items.ReceiverDebtsAmount.Title = presentation + ? ( currency.IsEmpty (), "", ", " + currency );
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( CurrentObject, Form ) export
	
	clean ( CurrentObject.Adjustments );
	if ( Form.UseReceiver ) then
		clean ( CurrentObject.ReceiverDebts );
	endif;

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

&AtClient
Procedure RateOnChange ( Form ) export
	
	object = Form.Object;
	if ( object.Rate = 0 ) then
		object.Rate = 1;
	endif;
	applyRate ( Form );
	
EndProcedure

&AtClient
Procedure FactorOnChange ( Form ) export
	
	object = Form.Object;
	if ( object.Factor = 0 ) then
		object.Factor = 1;
	endif;
	applyRate ( Form );
	
EndProcedure

&AtClient
Procedure CalcPaymentAmount ( Object ) export
	
	Object.Amount = getPaymentAmount ( Object );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Form ) export
	
	object = Form.Object;
	calcContract ( object, 1 );
	calcApplied ( object, 1 );
	distributeAmount ( object );
	updateInfo ( Form );
	if ( Form.UseReceiver ) then
		applyReceiverRate ( Form );
	endif;
	
EndProcedure

&AtServer
Procedure ApplyOption ( Form ) export
	
	setReceiverOptions ( Form );
	filterAccount ( Form );
	setTypeReceiver ( Form );
	if ( Form.UseReceiver ) then
		filterReceiver ( Form );
		filterReceiverAccount ( Form );
	endif;
	Appearance.Apply ( Form, "UseReceiver" );
	
EndProcedure

&AtServer
Procedure setTypeReceiver ( Form ) 

	if ( not Form.UseReceiver ) then
		return;
	endif;
	isAdjustDebts = isAdjustDebts ( Form );
	object = Form.Object;
	if ( isAdjustDebts and Form.ReceiverCustomer )
		or ( not isAdjustDebts and Form.ReceiverVendor ) then
		if ( isDebt ( object.Type ) ) then
			type = PredefinedValue ( "Enum.TypesAdjustDebts.Advance" );
		else
			type = PredefinedValue ( "Enum.TypesAdjustDebts.Debt" );
		endif;
	else
		type = object.Type;
	endif;
	object.TypeReceiver = type;

EndProcedure

&AtServer
Procedure ApplyType ( Form ) export
	
	setTypeReceiver ( Form );
	refill ( Form );
	updateInfo ( Form );
	if ( Form.UseReceiver ) then
		refillReceiver ( Form );
		updateInfoReceiver ( Form );
	endif;
	
EndProcedure

&AtServer
Procedure refillReceiver ( Form )
	
	fillReceiverDebts ( Form );
	distributeReceiverAmount ( Form.Object );
	
EndProcedure

&AtServer
Procedure fillReceiverDebts ( Form )
	
	object = Form.Object;
	receiverDebts = object.ReceiverDebts;
	if ( object.ReceiverContract.IsEmpty () ) then
		receiverDebts.Clear ();
		return;
	endif; 
	receiverDebts.Load ( getPaymentsReceiver ( Form ) );
	toggleReceiverDetails ( Form );
	
EndProcedure

&AtServer
Function getPaymentsReceiver ( Form )
	
	object = Form.Object;
	if ( isAdjustDebts ( Form ) ) then
		if ( Form.ReceiverCustomer ) then
			type = object.TypeReceiver;
			tableName = "Debts";
		else
			type = object.Type;
			tableName = "VendorDebts";
		endif;
	else
		if ( Form.ReceiverVendor ) then
			type = object.TypeReceiver;	
			tableName = "VendorDebts";
		else
			type = object.Type;
			tableName = "Debts";
		endif;
	endif;
	q = new Query ( sqlPayments ( type, tableName ) );
	date = Periods.GetDocumentDate ( object );
	q.SetParameter ( "Period", EndOfDay ( date ) );
	q.SetParameter ( "Contract", object.ReceiverContract );
	q.SetParameter ( "Currency", object.ReceiverContractCurrency );
	q.SetParameter ( "Organization", object.Receiver );
	return q.Execute ().Unload ();
	
EndFunction

&AtServer
Procedure ApplyReceiver ( Form ) export
	
	setReceiverAccount ( Form );
	setReceiverContract ( Form );
	AdjustDebtsForm.ApplyReceiverContract ( Form );
	
EndProcedure

&AtServer
Procedure setReceiverAccount ( Form )
	
	field = ? ( isReceiverCustomer ( Form ), "CustomerAccount", "VendorAccount" );
	object = Form.Object;
	accounts = AccountsMap.Organization ( object.Receiver, object.Company, field );
	object.ReceiverAccount = accounts [ field ];
	
EndProcedure

&AtServer
Procedure setReceiverContract ( Form )
	
	if ( isReceiverCustomer ( Form ) ) then
		params = "CustomerContract as Contract, CustomerContract.Company as Company";
	else
		params = "VendorContract as Contract, VendorContract.Company as Company";
	endif;
	object = Form.Object;
	data = DF.Values ( object.Receiver, params );
	if ( data.Company = object.Company ) then
		object.ReceiverContract = data.Contract;
	endif; 
	
EndProcedure 

&AtServer
Procedure ApplyReceiverContract ( Form ) export
	
	loadReceiverContract ( Form );
	setReceiverCaption ( Form );
	refillReceiver ( Form );
	updateInfoReceiver ( Form );
	Appearance.Apply ( Form, "Object.ReceiverContract, Object.ReceiverContractCurrency" );
	
EndProcedure

&AtServer
Procedure loadReceiverContract ( Form )
	
	object = Form.Object;
	currency = DF.Pick ( object.ReceiverContract, "Currency" );
	object.ReceiverContractCurrency = currency;
	data = CurrenciesSrv.Get ( currency, object.Date );
	object.ReceiverContractRate = data.Rate;
	object.ReceiverContractFactor = data.Factor;
	applyReceiverRate ( Form );
	
EndProcedure

&AtClient
Procedure ReceiverContractFactorOnChange ( Form ) export
	
	object = Form.Object;
	if ( object.ReceiverContractFactor = 0 ) then
		object.ReceiverContractFactor = 1;
	endif;
	applyReceiverRate ( Form );
	
EndProcedure

&AtClient
Procedure ReceiverContractRateOnChange ( Form ) export
	
	object = Form.Object;
	if ( object.ReceiverContractRate = 0 ) then
		object.ReceiverContractRate = 1;
	endif;
	applyReceiverRate ( Form );
	
EndProcedure

&AtServer
Procedure AdjustmentDataUpdateConfirmation ( Form, Refilling ) export
	
	if ( Refilling ) then
		refill ( Form );
	else
		update ( Form );
	endif;
	updateInfo ( Form );
	Form.CurrentItem = Form.Items.Adjustments;

EndProcedure

&AtServer
Procedure update ( Form )
	
	object = Form.Object;
	tableAdjustments = object.Adjustments;
	adjustments = fetchAdjustments ( tableAdjustments );
	fillTable ( Form );
	applyAdjustments ( adjustments, tableAdjustments );
	calcContract ( object, 2 );
	calcApplied ( object, 2 );

EndProcedure

&AtServer
Function fetchAdjustments ( TableAdjustments )
	
	adjustments = new Array ();
	for each row in TableAdjustments do
		if ( row.Adjust ) then
			adjustment = new Structure ( "Contract, Document, Detail, Date, Option" );
			FillPropertyValues ( adjustment, row );
			adjustments.Add ( new Structure ( "Key, Amount", adjustment, row.Amount ) );
		endif;
	enddo;
	return adjustments;
	
EndFunction

&AtServer
Procedure applyAdjustments ( Adjustments, TableAdjustments )
	
	for each adjustment in Adjustments do
		rows = TableAdjustments.FindRows ( adjustment.Key );
		if ( rows.Count () = 0 ) then
			adjustmentNotFound ( adjustment );
		else
			row = rows [ 0 ];
			row.Amount = adjustment.Amount;
			toggleAdjust ( row );
		endif;
	enddo;
	
EndProcedure

&AtServer
Procedure adjustmentNotFound ( Adjustment )
	
	data = Adjustment.Key;
	s = Conversion.ValuesToString ( data.Document, data.Detail, data.Date, data.Option );
	Output.AdjustmentNotFound ( new Structure ( "Adjustment, Amount", s, Adjustment.Amount ) );
	
EndProcedure

&AtClient
Procedure Mark ( Form, Flag ) export

	tempRow = Form.AdjustmentsRow;
	object = Form.Object;
	for each row in object.Adjustments do
		if ( row.Adjust = Flag ) then
			continue;
		endif;
		row.Adjust = Flag;
		Form.AdjustmentsRow = row;
		AdjustDebtsForm.ApplyAdjust ( Form );
		calcContract ( object, 2 );
		calcApplied ( object, 2 );
	enddo;
	updateInfo ( Form );
	Form.AdjustmentsRow = tempRow;

EndProcedure

&AtClient
Procedure ApplyAdjust ( Form ) export
	
	if ( Form.AdjustmentsRow.Adjust ) then
		object = Form.Object;
		appliedRow = appliedAmountRow ( Form.AdjustmentsRow, isDebt ( object.Type ) );
		rest = object.Amount - object.Applied;
		rest = Currencies.Convert ( rest, object.Currency, object.ContractCurrency, object.Date, object.Rate, object.Factor, object.ContractRate, object.ContractFactor );
		amount = ? ( rest <= 0, appliedRow, Max ( 0, Min ( rest, appliedRow ) ) );
		Form.AdjustmentsRow.Amount = amount;
	else
		Form.AdjustmentsRow.Amount = 0;
	endif;
	
EndProcedure

&AtClient
Procedure AdjustmentsOnEditEnd ( Form, Item, CancelEdit ) export
	
	if ( not CancelEdit ) then
		toggleAdjust ( Item.CurrentData );
	endif;
	AdjustDebtsForm.CalcTotals ( Form );

EndProcedure

&AtClient
Procedure CalcTotals ( Form ) export
	
	object = Form.Object;
	calcContract ( object, 2 );
	calcApplied ( object, 2 );
	updateInfo ( Form );
	
EndProcedure 

&AtClient
Procedure AdjustmentsSelection ( Item, StandardProcessing ) export
	
	StandardProcessing = not Item.CurrentItem.ReadOnly;
	show ( Item );
	
EndProcedure

&AtClient
Procedure show ( Item )
	
	value = undefined;
	name = Item.CurrentItem.Name;
	row = Item.CurrentData;
	if ( name = "AdjustmentsDocument" ) then
		value = row.Document;
	elsif ( name = "AdjustmentsDetail" ) then
		value = row.Detail;
	endif; 
	if ( ValueIsFilled ( value ) ) then
		ShowValue ( , value );
	endif; 
	
EndProcedure

&AtClient
Procedure AdjustmentsAmountOnChange ( Form ) export
	
	Form.AdjustmentsRow.Amount = Min ( Form.AdjustmentsRow.Amount, appliedAmountRow ( Form.AdjustmentsRow, isDebt ( Form.Object.Type ) ) );
	
EndProcedure

&AtServer
Procedure ReceiverDataUpdateConfirmation ( Form, Refilling ) export
	
	if ( Refilling ) then
		refillReceiver ( Form );
	else
		updateReceiverDebts ( Form );
	endif;
	updateInfoReceiver ( Form );
	Form.CurrentItem = Form.Items.ReceiverDebts;

EndProcedure

&AtServer
Procedure updateReceiverDebts ( Form )
	
	object = Form.Object;
	tableAdjustments = object.ReceiverDebts;
	adjustments = fetchAdjustments ( tableAdjustments );
	fillReceiverDebts ( Form );
	applyAdjustments ( adjustments, tableAdjustments );
	calcReceiverContract ( object, 2 );
	calcAppliedReceiver ( object, 2 );

EndProcedure

&AtClient
Procedure MarkReceiver ( Form, Flag ) export

	tempRow = Form.ReceiverRow;
	object = Form.Object;
	for each row in object.ReceiverDebts do
		if ( row.Adjust = Flag ) then
			continue;
		endif;
		row.Adjust = Flag;
		Form.ReceiverRow = row;
		AdjustDebtsForm.ApplyReceiverAdjust ( Form );
		calcReceiverContract ( object, 2 );
		calcAppliedReceiver ( object, 2 );
	enddo;
	updateInfoReceiver ( Form );
	Form.ReceiverRow = tempRow;

EndProcedure

&AtClient
Procedure ApplyReceiverAdjust ( Form ) export
	
	if ( Form.ReceiverRow.Adjust ) then
		object = Form.Object;
		appliedRow = appliedAmountRow ( Form.ReceiverRow, isDebt ( object.TypeReceiver ) );
		rest = object.Amount - object.Applied;
		rest = Currencies.Convert ( rest, object.Currency, object.ReceiverContractCurrency, object.Date, object.Rate, object.Factor, object.ReceiverContractRate, object.ReceiverContractFactor );
		amount = ? ( rest <= 0, appliedRow, Max ( 0, Min ( rest, appliedRow ) ) );
		Form.ReceiverRow.Amount = amount;
	else
		Form.ReceiverRow.Amount = 0;
	endif;
	
EndProcedure

&AtClient
Procedure ReceiverDebtsSelection ( Item, StandardProcessing ) export
	
	StandardProcessing = not Item.CurrentItem.ReadOnly;
	showReceiverDocument ( Item );
	
EndProcedure

&AtClient
Procedure showReceiverDocument ( Item )
	
	value = undefined;
	name = Item.CurrentItem.Name;
	row = Item.CurrentData;
	if ( name = "ReceiverDebtsDocument" ) then
		value = row.Document;
	elsif ( name = "ReceiverDebtsDetail" ) then
		value = row.Detail;
	endif; 
	if ( ValueIsFilled ( value ) ) then
		ShowValue ( , value );
	endif; 
	
EndProcedure

&AtClient
Procedure ReceiverDebtsOnEditEnd ( Form, Item, CancelEdit ) export
	
	if ( not CancelEdit ) then
		toggleAdjust ( Item.CurrentData );
	endif;
	AdjustDebtsForm.CalcTotalsReceiver ( Form );

EndProcedure

&AtClient
Procedure CalcTotalsReceiver ( Form ) export
	
	object = Form.Object;
	calcReceiverContract ( object, 2 );
	calcAppliedReceiver ( object, 2 );
	updateInfoReceiver ( Form );
	
EndProcedure

&AtClient
Procedure ReceiverDebtsAmountOnChange ( Form ) export
	
	receiverRow = Form.ReceiverRow;
	amount = receiverRow.Amount;
	applied = Min ( amount, appliedAmountRow ( receiverRow, isDebt ( Form.Object.TypeReceiver ) ) );
	receiverRow.Applied = applied;
	receiverRow.Difference = Max ( 0, amount - applied );
	
EndProcedure
