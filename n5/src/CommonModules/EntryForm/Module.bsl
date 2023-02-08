
Procedure InitAccounts ( Form ) export
	
	tableRow = Form.TableRow;
	Form.AccountDr = tableRow.AccountDr;
	Form.AccountCr = tableRow.AccountCr;
	
EndProcedure 

Procedure EnableAnalytics ( Form ) export
	
	readAccounts ( Form, true, true );
	enableSide ( Form, "Dr" );
	enableSide ( Form, "Cr" );
	
EndProcedure 

Procedure readAccounts ( Form, Dr, Cr )
	
	tableRow = Form.TableRow;
	if ( Dr and Cr ) then
		data = EntryFormSrv.AccountsData ( tableRow.AccountDr, tableRow.AccountCr );
		Form.DrData = data.Dr;
		Form.CrData = data.Cr;
	elsif ( Dr ) then
		Form.DrData = GeneralAccounts.GetData ( tableRow.AccountDr );
	elsif ( Cr ) then
		Form.CrData = GeneralAccounts.GetData ( tableRow.AccountCr );
	endif; 
	
EndProcedure

Procedure enableSide ( Form, Side )
	
	data = accountData ( Form, Side );
	dims = data.Dims;
	fields = data.Fields;
	items = Form.Items;
	items [ "Quantity" + Side ].Enabled = fields.Quantitative;
	currency = fields.Currency;
	items [ "Currency" + Side ].Enabled = currency;
	items [ "CurrencyAmount" + Side ].Enabled = currency;
	items [ "Rate" + Side ].Enabled = currency;
	items [ "Factor" + Side ].Enabled = currency;
	level = fields.Level;
	for i = 1 to 3 do
		item = items [ "Dim" + Side + i ];
		if ( i > level ) then
			item.Enabled = false;
			item.Title = "";
		else
			item.Enabled = true;
			item.Title = dims [ i - 1 ].Presentation;
		endif;
	enddo; 

EndProcedure 

Function accountData ( Form, Side )
	
	if ( isOpeningBalances ( Form ) ) then
		return Form.AccountData;
	else
		return Form [ Side + "Data" ];
	endif; 
	
EndFunction 

Function isOpeningBalances ( Form )
	
	return Form.FormName = "Document.Balances.Form.Form";
	
EndFunction 

Procedure DisableCurrency ( Form, Side = "" ) export
	
	data = accountData ( Form, Side );
	if ( not data.Fields.Currency ) then
		return;
	endif; 
	currency = Form.TableRow [ "Currency" + Side ];
	items = Form.Items;
	if ( isOpeningBalances ( Form ) ) then
		readonly = currency = Form.LocalCurrency;
		prefix = ? ( Form.DetailsExist, "Details", "Account" );
		items [ prefix + "Rate" ].Readonly = readonly;
		items [ prefix + "Factor" ].Readonly = readonly;
		items [ prefix + "CurrencyAmount" ].Readonly = readonly;
	else
		enable = currency <> Form.LocalCurrency;
		items [ "Rate" + Side ].Enabled = enable;
		items [ "Factor" + Side ].Enabled = enable;
		items [ "CurrencyAmount" + Side ].Enabled = enable;
	endif; 
	
EndProcedure 

Procedure AccountDrOnChange ( Form ) export
	
	Form.TableRow.AccountDr = Form.AccountDr;
	readAccounts ( Form, true, false );
	adjustAnalytics ( Form, "Dr" );
	setDim1 ( Form, "Dr" );
	row = Form.TableRow;
	setAmount ( row, row.Amount, true );
	enableSide ( Form, "Dr" );
	EntryForm.DisableCurrency ( Form, "Dr" );
	
EndProcedure 

Procedure adjustAnalytics ( Form, Side )
	
	data = accountData ( Form, Side );
	fields = data.Fields;
	dims = data.Dims;
	tableRow = Form.TableRow;
	if ( not fields.Quantitative ) then
		tableRow [ "Quantity" + Side ] = null;
	endif; 
	if ( not fields.Currency ) then
		tableRow [ "Currency" + Side ] = null;
		tableRow [ "CurrencyAmount" + Side ] = null;
		tableRow [ "Rate" + Side ] = null;
		tableRow [ "Factor" + Side ] = null;
	endif; 
	dim = "Dim" + Side;
	dim1 = dim + "1";
	dim2 = dim + "2";
	dim3 = dim + "3";
	level = fields.Level;
	if ( level > 0 ) then
		tableRow [ dim1 ] = dims [ 0 ].ValueType.AdjustValue ( tableRow [ dim1 ] );
	else
		tableRow [ dim1 ] = null;
	endif; 
	if ( level > 1 ) then
		tableRow [ dim2 ] = dims [ 1 ].ValueType.AdjustValue ( tableRow [ dim2 ] );
	else
		tableRow [ dim2 ] = null;
	endif; 
	if ( level > 2 ) then
		tableRow [ dim3 ] = dims [ 2 ].ValueType.AdjustValue ( tableRow [ dim3 ] );
	else
		tableRow [ dim3 ] = null;
	endif; 
	class = Side + "Class";
	tableRow [ class ] = fields.Class;

EndProcedure 

Procedure setDim1 ( Form, Side )
	
	dim = "Dim" + Side + "1";
	row = Form.TableRow;
	if ( TypeOf ( row [ dim ] ) = Type ( "CatalogRef.PaymentLocations" ) ) then
		data = Logins.Settings ( "PaymentLocation, PaymentLocation.Owner as Company" );
		if ( data.Company = Form.Object.Company ) then
			row [ dim ] = data.PaymentLocation;
		endif;
	endif;

EndProcedure

Procedure setAmount ( TableRow, Amount, Corresponding )
	
	TableRow.Amount = Amount;
	if ( Corresponding ) then
		TableRow.AmountDr = ? ( TableRow.AccountDr.IsEmpty (), 0, Amount );
		TableRow.AmountCr = ? ( TableRow.AccountCr.IsEmpty (), 0, Amount );
	endif;

EndProcedure

Procedure DimDr1StartChoice ( Form, Item, ChoiceData, StandardProcessing ) export
	
	chooseDimension ( Form, Item, 1, "Dr", StandardProcessing );
	
EndProcedure

Procedure chooseDimension ( Form, Item, Level, Side, StandardProcessing )
	
	p = Dimensions.GetParams ();
	p.Company = Form.Object.Company;
	p.Level = Level;
	tableRow = Form.TableRow;
	p.Dim1 = tableRow [ "Dim" + Side + "1" ];
	p.Dim2 = tableRow [ "Dim" + Side + "2" ];
	p.Dim3 = tableRow [ "Dim" + Side + "3" ];
	Dimensions.Choose ( p, Item, StandardProcessing );
	
EndProcedure 

Procedure DimDr1OnChange ( Form, Item ) export
	
	applyDim1 ( Form, "Dr" );
	
EndProcedure

Procedure applyDim1 ( Form, Side )
	
	value = Form.TableRow [ "Dim" + Side + "1" ];
	type = TypeOf ( value );
	if ( type = Type ( "CatalogRef.BankAccounts" ) ) then
		applyBankAccount ( Form, Side, value );
	elsif ( type = Type ( "CatalogRef.Organizations" ) ) then
		applyOrganization ( Form, Side, value );
	endif; 
	
EndProcedure 

Procedure applyBankAccount ( Form, Side, BankAccount )
	
	data = accountData ( Form, Side );
	if ( data.Fields.Currency ) then
		Form.TableRow [ "Currency" + Side ] = DF.Pick ( BankAccount, "Currency" );
		setRate ( Form, Side );
		calcTotals ( Form, Side );
		EntryForm.DisableCurrency ( Form, Side );
	endif; 
	
EndProcedure 

Procedure setRate ( Form, Side )
	
	tableRow = Form.TableRow;
	info = CurrenciesSrv.Get ( tableRow [ "Currency" + Side ], Form.Object.Date );
	tableRow [ "Rate" + Side ] = info.Rate;
	tableRow [ "Factor" + Side ] = info.Factor;
	
EndProcedure 

Procedure calcAmount ( Form, Side )
	
	tableRow = Form.TableRow;
	amount = tableRow [ "CurrencyAmount" + Side ];
	rate = tableRow [ "Rate" + Side ];
	factor = tableRow [ "Factor" + Side ];
	recordAmount = ( amount * rate ) / Max ( factor, 1 );
	setAmount ( tableRow, recordAmount, Side <> "" );
	if ( isEntry ( Form ) ) then
		Form.Object.Amount = recordAmount;
	endif; 
	
EndProcedure 

Function isEntry ( Form )
	
	return Form.FormName = "Document.Entry.Form.Form";
	
EndFunction 

Procedure setCurrencyAmount ( Form )
	
	tableRow = Form.TableRow;
	amount = tableRow.Amount;
	localCurrency = Form.LocalCurrency;
	if ( isOpeningBalances ( Form ) ) then
		if ( Form.AccountData.Fields.Currency
			and tableRow.Currency = localCurrency ) then
			tableRow.CurrencyAmount = amount;
		endif; 
	else
		if ( Form.DrData.Fields.Currency
			and tableRow.CurrencyDr = localCurrency ) then
			tableRow.CurrencyAmountDr = amount;
		endif; 
		if ( Form.CrData.Fields.Currency
			and tableRow.CurrencyCr = localCurrency ) then
			tableRow.CurrencyAmountCr = amount;
		endif; 
	endif; 
	
EndProcedure 

Procedure calcTotals ( Form, Side )
	
	calcAmount ( Form, Side );
	setCurrencyAmount ( Form );
	
EndProcedure 

Procedure applyOrganization ( Form, Side, Organization )
	
	tableRow = Form.TableRow;
	object = Form.Object;
	account = ? ( isOpeningBalances ( Form ), object.Account, tableRow [ "Account" + Side ] );
	contract = EntryFormSrv.GetContract ( account, Organization, object.Company );
	tableRow [ "Dim" + Side + "2" ] = contract;
	applyContract ( Form, Side, contract );
	
EndProcedure 

Procedure applyContract ( Form, Side, Contract )
	
	data = accountData ( Form, Side );
	if ( data.Fields.Currency ) then
		Form.TableRow [ "Currency" + Side ] = DF.Pick ( Contract, "Currency" );
		setRate ( Form, Side );
		calcTotals ( Form, Side );
		EntryForm.DisableCurrency ( Form, Side );
	endif; 
	
EndProcedure 

Procedure DimDr2StartChoice ( Form, Item, ChoiceData, StandardProcessing ) export
	
	chooseDimension ( Form, Item, 2, "Dr", StandardProcessing );
	
EndProcedure

Procedure DimDr2OnChange ( Form, Item ) export
	
	applyDim2 ( Form, "Dr" );
	
EndProcedure

Procedure applyDim2 ( Form, Side )
	
	value = Form.TableRow [ "Dim" + Side + "2" ];
	type = TypeOf ( value );
	if ( type = Type ( "CatalogRef.Contracts" ) ) then
		applyContract ( Form, Side, value );
	elsif ( type = Type ( "CatalogRef.BankAccounts" ) ) then
		applyBankAccount ( Form, Side, value );	
	endif; 
	
EndProcedure 

Procedure DimDr3StartChoice ( Form, Item, ChoiceData, StandardProcessing ) export
	
	chooseDimension ( Form, Item, 3, "Dr", StandardProcessing );
	
EndProcedure

Procedure CurrencyDrOnChange ( Form, Item ) export
	
	setRate ( Form, "Dr" );
	calcTotals ( Form, "Dr" );
	EntryForm.DisableCurrency ( Form, "Dr" );
	
EndProcedure

Procedure RateDrOnChange ( Form, Item ) export
	
	calcTotals ( Form, "Dr" );
	
EndProcedure

Procedure FactorDrOnChange ( Form, Item ) export
	
	calcTotals ( Form, "Dr" );

EndProcedure

Procedure CurrencyAmountDrOnChange ( Form, Item ) export
	
	calcTotals ( Form, "Dr" );
	
EndProcedure

Procedure AccountCrOnChange ( Form ) export
	
	Form.TableRow.AccountCr = Form.AccountCr;
	readAccounts ( Form, false, true );
	adjustAnalytics ( Form, "Cr" );
	setDim1 ( Form, "Cr" );
	row = Form.TableRow;
	setAmount ( row, row.Amount, true );
	enableSide ( Form, "Cr" );
	EntryForm.DisableCurrency ( Form, "Cr" );
	
EndProcedure

Procedure DimCr1StartChoice ( Form, Item, ChoiceData, StandardProcessing ) export
	
	chooseDimension ( Form, Item, 1, "Cr", StandardProcessing );
	
EndProcedure

Procedure DimCr1OnChange ( Form, Item ) export
	
	applyDim1 ( Form, "Cr" );
	
EndProcedure

Procedure DimCr2StartChoice ( Form, Item, ChoiceData, StandardProcessing ) export
	
	chooseDimension ( Form, Item, 2, "Cr", StandardProcessing );
	
EndProcedure

Procedure DimCr2OnChange ( Form, Item ) export
	
	applyDim2 ( Form, "Cr" );
	
EndProcedure

Procedure DimCr3StartChoice ( Form, Item, ChoiceData, StandardProcessing ) export
	
	chooseDimension ( Form, Item, 3, "Cr", StandardProcessing );
	
EndProcedure

Procedure CurrencyCrOnChange ( Form, Item ) export
	
	setRate ( Form, "Cr" );
	calcTotals ( Form, "Cr" );
	EntryForm.DisableCurrency ( Form, "Cr" );

EndProcedure

Procedure RateCrOnChange ( Form, Item ) export
	
	calcTotals ( Form, "Cr" );
	
EndProcedure

Procedure FactorCrOnChange ( Form, Item ) export
	
	calcTotals ( Form, "Cr" );

EndProcedure

Procedure CurrencyAmountCrOnChange ( Form, Item ) export
	
	calcTotals ( Form, "Cr" );
	
EndProcedure

Procedure AmountOnChange ( Form, Item ) export
	
	setAmount ( Form.TableRow, Form.TableRow.Amount, not isOpeningBalances ( Form ) );
	setCurrencyAmount ( Form );
	setTotal ( Form );
	
EndProcedure

Procedure setTotal ( Form )
	
	object = Form.Object;
	simple = ( isEntry ( Form ) and object.Simple )
	or ( isOpeningBalances ( Form ) and not Form.DetailsExist );
	if ( simple ) then
		object.Amount = Form.TableRow.Amount;
	endif; 
	
EndProcedure 

Procedure FixAccounts ( Form ) export
	
	if ( isEntry ( Form ) ) then
		operation = Form.Operation;
	else
		operation = Form.FormOwner.Operation;
	endif; 
	account = operation.AccountDr;
	tableRow = Form.TableRow;
	if ( tableRow.AccountDr <> account
		and not account.IsEmpty () ) then
		Form.AccountDr = account;
		tableRow.AccountDr = account;
		EntryForm.AccountDrOnChange ( Form );
		tableRow.DimDr1 = operation.DimDr1;
		tableRow.DimDr2 = operation.DimDr2;
		tableRow.DimDr3 = operation.DimDr3;
	endif;
	account = Operation.AccountCr;
	if ( tableRow.AccountCr <> account
		and not account.IsEmpty () ) then
		Form.AccountCr = account;
		tableRow.AccountCr = account;
		EntryForm.AccountCrOnChange ( Form );
		tableRow.DimCr1 = operation.DimCr1;
		tableRow.DimCr2 = operation.DimCr2;
		tableRow.DimCr3 = operation.DimCr3;
	endif;
	
EndProcedure 

Procedure Dim1StartChoice ( Form, Item, ChoiceData, StandardProcessing ) export
	
	chooseDimension ( Form, Item, 1, "", StandardProcessing );
	
EndProcedure

Procedure Dim2StartChoice ( Form, Item, ChoiceData, StandardProcessing ) export
	
	chooseDimension ( Form, Item, 2, "", StandardProcessing );
	
EndProcedure

Procedure Dim3StartChoice ( Form, Item, ChoiceData, StandardProcessing ) export
	
	chooseDimension ( Form, Item, 3, "", StandardProcessing );
	
EndProcedure

Procedure Dim1OnChange ( Form, Item ) export
	
	applyDim1 ( Form, "" );
	
EndProcedure

Procedure Dim2OnChange ( Form, Item ) export
	
	applyDim2 ( Form, "" );
	
EndProcedure

Procedure CurrencyOnChange ( Form, Item ) export
	
	setRate ( Form, "" );
	calcTotals ( Form, "" );
	EntryForm.DisableCurrency ( Form );
	
EndProcedure

Procedure RateOnChange ( Form, Item ) export
	
	calcTotals ( Form, "" );
	
EndProcedure

Procedure FactorOnChange ( Form, Item ) export
	
	calcTotals ( Form, "" );

EndProcedure

Procedure CurrencyAmountOnChange ( Form, Item ) export
	
	calcTotals ( Form, "" );
	
EndProcedure
