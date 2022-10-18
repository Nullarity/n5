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
	if ( isAdjustDebts ( Form.Object ) ) then
		InvoiceRecords.Read ( Form );
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
	Appearance.Apply ( Form, "Info" );
	
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

	if ( isAdjustDebts ( Form.Object ) ) then
		setReceiverOptionsCustomer ( Form );
	else
		setReceiverOptionsVendor ( Form );
	endif;

EndProcedure

&AtServer
Function isAdjustDebts ( Object ) 

	return TypeOf ( Object.Ref ) = Type ( "DocumentRef.AdjustDebts" );

EndFunction

&AtServer
Procedure setReceiverOptionsCustomer ( Form ) 

	option = Form.Object.Option;
	customer = option = Enums.AdjustmentOptions.Customer;
	Form.ReceiverCustomer = customer;
	Form.UseReceiver = customer or ( option = Enums.AdjustmentOptions.Vendor );

EndProcedure

&AtServer
Procedure setReceiverOptionsVendor ( Form ) 

	option = Form.Object.Option;
	vendor = option = Enums.AdjustmentOptions.Vendor;
	Form.ReceiverVendor = vendor;
	Form.UseReceiver = vendor or ( option = Enums.AdjustmentOptions.Customer );

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
	setTitle ( Form );
	if ( Form.UseReceiver ) then
		filterReceiver ( Form );
		setReceiverCaption ( Form );
	endif;
	if ( isAdjustDebts ( object ) ) then
		AdjustDebtsForm.SetLinks ( Form );
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
	|Info hide empty ( Info );
	|Account hide UseReceiver;
	|Type Receiver ReceiverContract ReceiverAccount ReceiverCurrencyGroup GroupReceiverDebts show UseReceiver;
	|GroupReceiverDebts enable UseReceiver and filled ( Object.Receiver ) and filled ( Object.ReceiverContract );
	|AdjustmentsItem AdjustmentsDescription AccountingItem AccountingDescription AdjustmentsVATAccount AdjustmentsVATCode
	|AdjustmentsVAT AccountingVATAccount AccountingVATCode AccountingVAT AccountingReceiverVATAccount
	|AccountingReceiverItem AccountingReceiverDescription AccountingReceiverVATCode AccountingReceiverVAT
	|	show Object.ApplyVAT;
	|ReceiverContractRate ReceiverContractFactor enable
	|	Object.ReceiverContractCurrency <> Object.Currency
	|	and Object.ReceiverContractCurrency <> LocalCurrency
	|	and filled ( Object.ReceiverContractCurrency );
	|WarningPosted UndoPosting show Object.Posted;
	|AdjustmentsDebt AdjustmentsOverpayment hide inlist ( Object.Option,
	|		Enum.AdjustmentOptions.AccountingDr,
	|		Enum.AdjustmentOptions.AccountingCr );
	|AdjustmentsAccounting AdjustmentsAdvance show inlist ( Object.Option,
	|		Enum.AdjustmentOptions.AccountingDr,
	|		Enum.AdjustmentOptions.AccountingCr );
	|Currency Currency1 lock inlist ( Object.Option,
	|		Enum.AdjustmentOptions.AccountingDr,
	|		Enum.AdjustmentOptions.AccountingCr );
	|" );
	if ( isAdjustDebts ( Form.Object ) ) then
		rules.Add ( "
		|Links show ShowLinks;
		|FormInvoice show filled ( InvoiceRecord );
		|NewInvoiceRecord show FormStatus = Enum.FormStatuses.Canceled or empty ( FormStatus );
		|Warning show ChangesDisallowed;
		|Header Adjustments AdjustmentsItem AdjustmentsDescription Accounting AccountingReceiver ReceiverDebts
		|	GroupMore GroupCurrency lock Object.Posted or ChangesDisallowed;
		|GroupFillDocuments GroupFillReceiver MarkAll1 UnmarkAll1 MarkAllReceiver1 UnmarkAllReceiver1
		|	disable Object.Posted or ChangesDisallowed;
		|AccountingPaymentDate AccountingPaymentOption show Object.Type = Enum.TypesAdjustDebts.Advance;
		|" );
	else
		rules.Add ( "
		|Header Adjustments AdjustmentsItem AdjustmentsDescription Accounting AccountingReceiver ReceiverDebts
		|	GroupMore GroupCurrency lock Object.Posted;
		|GroupFillDocuments GroupFillReceiver MarkAll1 UnmarkAll1 MarkAllReceiver1 UnmarkAllReceiver1
		|	disable Object.Posted;
		|AccountingPaymentDate AccountingPaymentOption show Object.Type = Enum.TypesAdjustDebts.Advance;
		|" );
	endif;
	Appearance.Read ( Form, rules );

EndProcedure

&AtServer
Procedure SetLinks ( Form ) export
	
	SQL.Init ( Form.Env );
	env = Form.Env;
	sqlLinks ( Form );
	if ( env.Selection.Count () = 0 ) then
		Form.ShowLinks = false;
	else
		q = env.Q;
		q.SetParameter ( "Ref", Form.Object.Ref );
		SQL.Perform ( env, false );
		setURLPanel ( Form );
	endif;
	Appearance.Apply ( Form, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ( Form )
	
	env = Form.Env;
	selection = env.Selection;
	if ( Form.Object.Ref.IsEmpty () ) then
		return;
	endif; 
	s = "
	|// #InvoiceRecords
	|select Documents.Ref as Document, Documents.DeliveryDate as Date, Documents.Number as Number
	|from Document.InvoiceRecord as Documents
	|where Documents.Base = &Ref
	|and not Documents.DeletionMark
	|";
	selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setURLPanel ( Form )
	
	parts = new Array ();
	if ( not Form.Object.Ref.IsEmpty () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Form.Env.InvoiceRecords, Metadata.Documents.InvoiceRecord ) );
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		Form.ShowLinks = false;
	else
		Form.ShowLinks = true;
		Form.Links = s;
	endif; 
	
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
	
	if ( isAdjustDebts ( Form.Object ) ) then
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
	
	accounts = AccountsMap.Organization ( Object.Customer, Object.Company, "CustomerAccount, AdvanceTaken" );
	Object.CustomerAccount = accounts.CustomerAccount;
	Object.AdvanceAccount = accounts.AdvanceTaken;	
	setVATAccounts ( Object );
	
EndProcedure

&AtServer
Procedure setVATAccounts ( Object )
	
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
	customerDebts = isAdjustDebts ( object );
	if ( customerDebts ) then
		fields.Add ( "CustomerRateType as RateType" );
		fields.Add ( "CustomerRate as Rate" );
		fields.Add ( "CustomerFactor as Factor" );
		fields.Add ( "CustomerVATAdvance as VATAdvance" );
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
	if ( not isAccounting ( object ) ) then
		Object.Currency = contractCurrency;
	endif;
	if ( customerDebts ) then
		Object.VATAdvance = data.VATAdvance;
	endif;
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
	calcContract ( object );
	calcApplied ( object );
	updateInfo ( Form );
	
EndProcedure

Procedure calcContract ( Object )
	
	Object.ContractAmount = Currencies.Convert ( Object.Amount, Object.Currency, Object.ContractCurrency,
		Object.Date, Object.Rate, Object.Factor, Object.ContractRate, Object.ContractFactor );

EndProcedure 

Procedure calcApplied ( Object )
	
	applied = Object.Adjustments.Total ( "Amount" ) + Object.Accounting.Total ( "Amount" );
	if ( isAccounting ( Object ) ) then
		Object.Applied = applied;
	else
		if ( applied = 0 ) then
			Object.Applied = 0;
		elsif ( applied = Object.ContractAmount ) then
			Object.Applied = Object.Amount;
		else
			Object.Applied = Currencies.Convert ( applied, Object.ContractCurrency, Object.Currency, Object.Date,
				Object.ContractRate, Object.ContractFactor, Object.Rate, Object.Factor );
		endif;
	endif;
	
EndProcedure

Procedure distributeAmount ( Object )
	
	accounting = isAccounting ( Object );
	if ( accounting ) then
		amount = Object.Amount - Object.Accounting.Total ( "Amount" );
	else
		amount = Object.ContractAmount - Object.Accounting.Total ( "Amount" );
	endif;
	isDebt = isDebt ( Object.Type );
	for each row in Object.Adjustments do
		applied = Min ( amount, appliedAmountRow ( row, isDebt, accounting ) );
		row.Amount = applied;
		toggleAdjust ( row );
		calcVAT ( row );
		amount = amount - applied;
	enddo; 

EndProcedure

Function isDebt ( Type ) 

	return Type = PredefinedValue ( "Enum.TypesAdjustDebts.Debt" );

EndFunction

Function isAccounting ( Object )
	
	option = Object.Option;
	return option = PredefinedValue ( "Enum.AdjustmentOptions.AccountingDr" )
		or option = PredefinedValue ( "Enum.AdjustmentOptions.AccountingCr" );
	
EndFunction

Function appliedAmountRow ( TableRow, IsDebt, Accounting ) 

	if ( Accounting ) then
		return TableRow.Accounting - TableRow.Advance;
	else
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
	accounting = isAccounting ( Object );
	for i = 0 to j do
		row = table [ i ];
		applied = Min ( amount, appliedAmountRow ( row, isDebt, accounting ) );
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
	object = Form.Object;
	currency = ? ( isAccounting ( object ), object.Currency, object.ContractCurrency );
	presentation = presentation + ? ( currency.IsEmpty (), "", ", " + currency );
	items = Form.Items;
	items.AdjustmentsAmount.Title = presentation;
	items.AccountingAmount.Title = presentation;
	
EndProcedure 

&AtServer
Procedure refill ( Form )
	
	fillTable ( Form );
	object = Form.Object;
	distributeAmount ( object );
	calcApplied ( object );
	
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
	if ( isAdjustDebts ( object ) ) then
		tableName = "Debts";
		organization = object.Customer;
	else
		tableName = "VendorDebts";
		organization = object.Vendor;
	endif;
	s = sqlPayments ( object.Type, tableName, isAccounting ( object ) );
	q = new Query ( s );
	date = Periods.GetDocumentDate ( object );
	q.SetParameter ( "Period", EndOfDay ( date ) );
	q.SetParameter ( "Contract", object.Contract );
	q.SetParameter ( "VATAccount", object.VATAccount );
	q.SetParameter ( "Currency", object.ContractCurrency );
	q.SetParameter ( "Organization", organization );
	return q.Execute ().Unload ();
	
EndFunction

&AtServer
Function sqlPayments ( Type, TableName, Accounting )
	
	if ( Accounting ) then
		s = "
		|select Balances.Document as Document, Balances.PaymentKey as PaymentKey,
		|	Balances.PaymentBalance as Payment, Balances.AmountBalance as Debt, Balances.OverpaymentBalance as Overpayment,
		|	Balances.AccountingBalance as Accounting, Balances.AdvanceBalance as Advance,
		|	Balances.Detail as Detail, PaymentDetails.Option as Option, PaymentDetails.Date as Date
		|into Balances
		|from AccumulationRegister." + TableName + ".Balance ( , Contract = &Contract ) as Balances
		|	//
		|	// PaymentDetails
		|	//
		|	left join InformationRegister.PaymentDetails as PaymentDetails
		|	on PaymentDetails.PaymentKey = Balances.PaymentKey
		|where Balances.Document.Date <= &Period
		|and isnull ( Balances.Detail.Date, &Period ) <= &Period
		|and ( Balances.AmountBalance = 0 and Balances.OverpaymentBalance = 0 )
		|and ( Balances.AccountingBalance <> 0 or Balances.AdvanceBalance <> 0 )
		|;
		|select Items.Document as Document, max ( Items.Rate ) as Rate, max ( Items.Account ) as Account
		|into VAT
		|from (
		|	select Items.Ref as Document, Items.VATCode as Rate, Items.VATAccount as Account
		|	from Document.Invoice.Items as Items
		|		//
		|		// Amounts
		|		//
		|		join (
		|			select Items.Ref as Ref, max ( Items.Amount ) as Amount
		|			from Document.Invoice.Items as Items
		|			where Items.Ref in (
		|				select Document from Balances
		|				union
		|				select Detail from Balances
		|			)
		|			group by Items.Ref
		|		) as Amounts
		|		on Amounts.Amount = Items.Amount
		|	where Items.Ref in (
		|		select Document from Balances
		|		union
		|		select Detail from Balances
		|	)
		|	union
		|	select Services.Ref, Services.VATCode, Services.VATAccount
		|	from Document.Invoice.Services as Services
		|		//
		|		// Amounts
		|		//
		|		join (
		|			select Services.Ref as Ref, max ( Services.Amount ) as Amount
		|			from Document.Invoice.Services as Services
		|			where Services.Ref in (
		|				select Document from Balances
		|				union
		|				select Detail from Balances
		|			)
		|			group by Services.Ref
		|		) as Amounts
		|		on Amounts.Amount = Services.Amount
		|	where Services.Ref in (
		|		select Document from Balances
		|		union
		|		select Detail from Balances
		|	)
		|	union
		|	select Documents.Ref, Documents.VATAdvance, Documents.VATAccount
		|	from Document.Payment as Documents
		|	where Documents.Ref in (
		|		select Document from Balances
		|		union
		|		select Detail from Balances
		|	)
		|) as Items
		|group by Items.Document
		|;
		|select Balances.Document as Document, Balances.PaymentKey as PaymentKey,
		|	Balances.Accounting as Accounting, Balances.Advance as Advance,
		|	Balances.Detail as Detail, Balances.Option as Option, Balances.Date as Date,
		|	isnull ( isnull ( VATDocuments.Rate, VATDetails.Rate ), Constants.ItemsVAT ) as VATCode,
		|	cast ( isnull ( isnull ( VATDocuments.Rate, VATDetails.Rate ), Constants.ItemsVAT ) as Catalog.VAT ).Rate as VATRate,
		|	isnull ( isnull ( VATDocuments.Account, VATDetails.Account ), &VATAccount ) as VATAccount
		|from Balances as Balances
		|	//
		|	// VATDocuments
		|	//
		|	left join VAT as VATDocuments
		|	on VATDocuments.Document = Balances.Document
		|	//
		|	// VATDetails
		|	//
		|	left join VAT as VATDetails
		|	on VATDetails.Document = Balances.Detail
		|	//
		|	// Constants
		|	//
		|	left join Constants as Constants
		|	on true
		|order by Balances.Date
		|";
	else
		s = "
		|select Balances.Document as Document, Balances.PaymentKey as PaymentKey,
		|	Balances.PaymentBalance as Payment, Balances.AmountBalance as Debt, Balances.OverpaymentBalance as Overpayment,
		|	Balances.AccountingBalance as Accounting, Balances.AdvanceBalance as Advance,
		|	Balances.Detail as Detail, PaymentDetails.Option as Option, PaymentDetails.Date as Date
		|from AccumulationRegister." + TableName + ".Balance ( , Contract = &Contract ) as Balances
		|	//
		|	// PaymentDetails
		|	//
		|	left join InformationRegister.PaymentDetails as PaymentDetails
		|	on PaymentDetails.PaymentKey = Balances.PaymentKey
		|where Balances.Document.Date <= &Period
		|and isnull ( Balances.Detail.Date, &Period ) <= &Period
		|and ";
		if ( Type = Enums.TypesAdjustDebts.Debt ) then
			s = s + "( Balances.AmountBalance > 0 or Balances.OverpaymentBalance < 0 )";
		else
			s = s + "( Balances.AmountBalance < 0 or Balances.OverpaymentBalance > 0 )";
		endif;
		s = s + "
		|order by PaymentDetails.Date
		|";
	endif;
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
	
	accounts = AccountsMap.Organization ( Object.Vendor, Object.Company, "VendorAccount, AdvanceGiven" );
	Object.VendorAccount = accounts.VendorAccount;
	Object.AdvanceAccount = accounts.AdvanceGiven;
	setVATAccounts ( Object );	
	
EndProcedure

&AtServer
Procedure setVendorContract ( Object )
	
	data = DF.Values ( Object.Vendor, "VendorContract as Contract, VendorContract.Company as Company" );
	if ( data.Company = Object.Company ) then
		Object.Contract = data.Contract;
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

	if ( isAdjustDebts ( Form.Object ) ) then
		return Form.ReceiverCustomer;
	else
		return not Form.ReceiverVendor;
	endif;

EndFunction

&AtServer
Procedure setReceiverCaption ( Form )
	
	presentation = Metadata.Documents.AdjustDebts.TabularSections.ReceiverDebts.Attributes.Amount.Presentation ();
	currency = Form.Object.ReceiverContractCurrency;
	Form.Items.ReceiverDebtsAmount.Title = presentation + ? ( currency.IsEmpty (), "", ", " + currency );
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( CurrentObject, Form ) export
	
	clean ( CurrentObject.Adjustments );
	useReceiver = Form.UseReceiver;
	calcTables ( CurrentObject, useReceiver );
	if ( useReceiver ) then
		clean ( CurrentObject.ReceiverDebts );
		calcTablesReceiver ( CurrentObject );
	endif;
	if ( CurrentObject.ApplyVAT ) then
		calcTablesVAT ( CurrentObject );
		if ( useReceiver ) then
			calcTablesVATReceiver ( CurrentObject );
		endif;
	else
		resetVATfields ( CurrentObject );
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

&AtServer
Procedure calcTables ( Object, UseReceiver )
	
	date = Object.Date;
	localCurrency = Application.Currency ();
	currency = Object.Currency;
	rate = Object.Rate;
	factor = Object.Factor;
	if ( isAccounting ( Object ) ) then
		contractCurrency = localCurrency;
		contractRate = 1;
		contractFactor = 1;
		receiverCurrency = localCurrency;
		receiverRate = 1;
		receiverFactor = 1;
	else
		if ( UseReceiver ) then
			receiverCurrency = Object.ReceiverContractCurrency;
			receiverRate = Object.ReceiverContractRate;
			receiverFactor = Object.ReceiverContractFactor;
		else
			receiverCurrency = currency;
			receiverRate = rate;
			receiverFactor = factor;
		endif;
		contractCurrency = Object.ContractCurrency;
		contractRate = Object.ContractRate;
		contractFactor = Object.ContractFactor;
	endif;
	tables = new Array ();
	tables.Add ( Object.Adjustments );
	tables.Add ( Object.Accounting );
	biggestRow = undefined;
	for each table in tables do
		for each row in table do
			amount = row.Amount;
			row.AmountLocal = Currencies.Convert ( amount, contractCurrency, localCurrency, date,
				contractRate, contractFactor, , , 2 );
			row.AmountDocument = Currencies.Convert ( amount, contractCurrency, receiverCurrency, date,
				contractRate, contractFactor, receiverRate, receiverFactor, 2 );
			if ( biggestRow = undefined
				or amount > biggestRow.Amount ) then
				biggestRow = row;
			endif;
		enddo;
	enddo;
	if ( biggestRow <> undefined ) then
		biggestRow.AmountDocument = biggestRow.AmountDocument + (
			Object.ReceiverContractAmount
			- Object.Adjustments.Total ( "AmountDocument" )
			- Object.Accounting.Total ( "AmountDocument" ) );
		totalLocalAmount = Currencies.Convert ( Object.Amount,
			currency, localCurrency, date, rate, factor, , , 2 );
		biggestRow.AmountLocal = biggestRow.AmountLocal + (
			totalLocalAmount
			- Object.Adjustments.Total ( "AmountLocal" )
			- Object.Accounting.Total ( "AmountLocal" ) );
	endif;

EndProcedure

&AtServer
Procedure calcTablesReceiver ( Object )
	
	date = Object.Date;
	localCurrency = Application.Currency ();
	currency = Object.Currency;
	rate = Object.Rate;
	factor = Object.Factor;
	contractCurrency = Object.ReceiverContractCurrency;
	contractRate = Object.ReceiverContractRate;
	contractFactor = Object.ReceiverContractFactor;
	biggestRow = undefined;
	tables = new Array ();
	tables.Add ( Object.ReceiverDebts );
	tables.Add ( Object.AccountingReceiver );
	biggestRow = undefined;
	for each table in tables do
		for each row in table do
			amount = row.Amount;
			row.AmountLocal = Currencies.Convert ( amount, contractCurrency, localCurrency, date,
				contractRate, contractFactor, , , 2 );
			row.AmountDocument = Currencies.Convert ( amount, contractCurrency, currency, date,
				contractRate, contractFactor, rate, factor, 2 );
			if ( biggestRow = undefined
				or amount > biggestRow.Amount ) then
				biggestRow = row;
			endif;
		enddo;
	enddo;
	if ( biggestRow <> undefined ) then
		biggestRow.AmountDocument = biggestRow.AmountDocument + (
			Object.Amount
			- Object.ReceiverDebts.Total ( "AmountDocument" )
			- Object.AccountingReceiver.Total ( "AmountDocument" ) );
		totalLocalAmount = Currencies.Convert ( Object.Amount, currency, localCurrency, date, rate, factor, , , 2 );
		biggestRow.AmountLocal = biggestRow.AmountLocal + (
			totalLocalAmount
			- Object.ReceiverDebts.Total ( "AmountLocal" )
			- Object.AccountingReceiver.Total ( "AmountLocal" ) );
	endif;

EndProcedure

&AtServer
Procedure calcTablesVAT ( Object )
	
	localCurrency = Application.Currency ();
	documentCurrency = Object.Currency;
	date = Object.Date;
	rate = Object.Rate;
	factor = Object.Factor;
	tables = new Array ();
	tables.Add ( Object.Adjustments );
	tables.Add ( Object.Accounting );
	tables.Add ( Object.AccountingReceiver );
	for each table in tables do
		for each row in table do
			amount = row.AmountLocal;
			vat = Round ( amount - amount * ( 100 / ( 100 + row.VATRate ) ), 2 );
			row.VATLocal = vat;
			row.VATDocument = Currencies.Convert ( vat, localCurrency, documentCurrency, date,
				, , rate, factor );
		enddo;
	enddo;

EndProcedure

&AtServer
Procedure calcTablesVATReceiver ( Object )
	
	localCurrency = Application.Currency ();
	documentCurrency = Object.Currency;
	date = Object.Date;
	rate = Object.Rate;
	factor = Object.Factor;
	for each row in Object.AccountingReceiver do
		amount = row.AmountLocal;
		vat = Round ( amount - amount * ( 100 / ( 100 + row.VATRate ) ), 2 );
		row.VATLocal = vat;
		row.VATDocument = Currencies.Convert ( vat, localCurrency, documentCurrency, date,
			, , rate, factor );
	enddo;

EndProcedure

&AtServer
Procedure resetVATfields ( Object )
	
	tables = new Array ();
	tables.Add ( Object.Adjustments );
	tables.Add ( Object.Accounting );
	tables.Add ( Object.AccountingReceiver );
	for each table in tables do
		for each row in table do
			row.Item = undefined;
			row.Description = "";
			row.VAT = 0;
			row.VATRate = 0;
			row.VATLocal = 0;
			row.VATDocument = 0;
			row.VATAccount = undefined;
			row.VATCode = undefined;
		enddo;
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
Procedure ApplyContractRate ( Form ) export
	
	object = Form.Object;
	calcContract ( object );
	calcApplied ( object );
	updateInfo ( Form );
	
EndProcedure

&AtClient
Procedure AmountOnChange ( Form ) export
	
	object = Form.Object;
	calcContract ( object );
	distributeAmount ( object );
	calcApplied ( object );
	updateInfo ( Form );
	if ( Form.UseReceiver ) then
		applyReceiverRate ( Form );
	endif;
	
EndProcedure

&AtServer
Procedure ApplyOption ( Form ) export
	
	setReceiverOptions ( Form );
	object = Form.Object;
	if ( Form.UseReceiver ) then
		setTypeReceiver ( Form );
		filterReceiver ( Form );
	else
		object.ReceiverDebts.Clear ();
		object.AccountingReceiver.Clear ();
		AdjustDebtsForm.CalcTotalsReceiver ( Form );
		option = object.Option;
		if ( option = Enums.AdjustmentOptions.CustomAccountDr
			or option = Enums.AdjustmentOptions.AccountingDr ) then
			newType = Enums.TypesAdjustDebts.Debt;
		else
			newType = Enums.TypesAdjustDebts.Advance;
		endif;
		if ( object.Type <> newType ) then
			object.Type = newType;
			AdjustDebtsForm.ApplyType ( Form );
		endif;
		if ( isAccounting ( object )
			and object.Currency <> Form.LocalCurrency ) then
			object.Currency = Form.LocalCurrency;
			AdjustDebtsForm.ApplyCurrency ( Form );
		endif;
	endif;
	Appearance.Apply ( Form, "UseReceiver, Object.Option" );
	
EndProcedure

&AtServer
Procedure setTypeReceiver ( Form ) 

	object = Form.Object;
	isAdjustDebts = isAdjustDebts ( object );
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
	
	refill ( Form );
	updateInfo ( Form );
	if ( Form.UseReceiver ) then
		setTypeReceiver ( Form );
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
	if ( isAdjustDebts ( object ) ) then
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
	q = new Query ( sqlPayments ( type, tableName, isAccounting ( Object ) ) );
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
	vendorToCustomer = not ( isAdjustDebts ( object ) or Form.ReceiverVendor );
	if ( vendorToCustomer ) then
		fields = "Currency, CustomerVATAdvance";
	else
		fields = "Currency";
	endif;
	data = DF.Values ( object.ReceiverContract, fields );
	if ( vendorToCustomer ) then
		object.VATAdvance = data.CustomerVATAdvance;
	endif;
	currency = data.Currency;
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
	calcApplied ( object );

EndProcedure

&AtServer
Function fetchAdjustments ( TableAdjustments )
	
	adjustments = new Array ();
	for each row in TableAdjustments do
		if ( row.Adjust ) then
			adjustment = new Structure ( "Document, Detail, Date, Option" );
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
			calcVAT ( row );
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
	enddo;
	calcApplied ( object );
	updateInfo ( Form );
	Form.AdjustmentsRow = tempRow;

EndProcedure

&AtClient
Procedure ApplyAdjust ( Form ) export
	
	if ( Form.AdjustmentsRow.Adjust ) then
		object = Form.Object;
		appliedRow = appliedAmountRow ( Form.AdjustmentsRow, isDebt ( object.Type ), isAccounting ( object ) );
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
	AdjustDebtsForm.ChahgeApplied ( Form );

EndProcedure

Procedure ChahgeApplied ( Form ) export
	
	object = Form.Object;
	calcApplied ( object );
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
	
	object = Form.Object;
	Form.AdjustmentsRow.Amount = Min ( Form.AdjustmentsRow.Amount,
		appliedAmountRow ( Form.AdjustmentsRow, isDebt ( object.Type ), isAccounting ( object ) ) );
	if ( object.ApplyVAT ) then
		calcVAT ( Form.AdjustmentsRow );
	endif;
	
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
		appliedRow = appliedAmountRow ( Form.ReceiverRow, isDebt ( object.TypeReceiver ), isAccounting ( object ) );
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
	object = Form.Object;
	applied = Min ( amount, appliedAmountRow ( receiverRow, isDebt ( object.TypeReceiver ), isAccounting ( object ) ) );
	receiverRow.Applied = applied;
	receiverRow.Difference = Max ( 0, amount - applied );
	
EndProcedure

&AtClient
Procedure AccountingOnEditEnd ( Form, Item, CancelEdit ) export
	
	AdjustDebtsForm.ChahgeApplied ( Form );

EndProcedure

&AtClient
Procedure ApplyVATOnChange ( Form ) export

	Appearance.Apply ( Form, "Object.ApplyVAT" );

EndProcedure

&AtClient
Procedure AdjustmentsVATCodeOnChange ( Row ) export
	
	setVATRate ( Row );
	calcVAT ( Row );

EndProcedure

&AtClient
Procedure setVATRate ( Row )
	
	Row.VATRate = DF.Pick ( Row.VATCode, "Rate", 0 );

EndProcedure

Procedure calcVAT ( Row )
	
	Row.VAT = Row.Amount - Row.Amount * ( 100 / ( 100 + Row.VATRate ) );

EndProcedure

&AtClient
Procedure AdjustmentsItemOnChange ( Object, Row ) export
	
	if ( isAccounting ( Object ) ) then
		applyAccountingItem ( Object, Row );
	else
		applyItem ( Object, Row );
	endif;

EndProcedure

&AtClient
Procedure applyAccountingItem ( Object, Row )
	
	item = Row.Item;
	if ( item.IsEmpty () ) then
		return;
	endif;
	description = DF.Pick ( item, "FullDescription" );
	Row.Description = description;
	for each row in Object.Adjustments do
		if ( row.Item.IsEmpty () ) then
			row.Item = item;
			row.Description = description;
		endif;
	enddo;
	
EndProcedure

&AtClient
Procedure applyItem ( Object, Row )
	
	p = new Structure ();
	p.Insert ( "Company", Object.Company );
	p.Insert ( "Item", Row.Item );
	data = getItemData ( p );
	Row.Description = data.FullDescription;
	Row.VATCode = data.VAT;
	Row.VATRate = data.Rate;
	Row.VATAccount = data.VATAccount;
	calcVAT ( Row );

EndProcedure

Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "FullDescription, VAT, VAT.Rate as Rate" );
	accounts = AccountsMap.Item ( item, Params.Company, , "VAT" );
	data.Insert ( "VATAccount", accounts.VAT );
	return data;

EndFunction

&AtClient
Procedure AccountingItemOnChange ( Object, Row ) export
	
	applyItem ( Object, Row );

EndProcedure

&AtClient
Procedure AccountingAmountOnChange ( Form ) export

	if ( Form.Object.ApplyVAT ) then
		calcVAT ( Form.AccountingRow );
	endif;

EndProcedure
