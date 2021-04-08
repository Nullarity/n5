Function Post ( Env ) export
	
	getData ( Env );
	expenseDebts ( Env, Env.Adjustments, Env.IsCustomer );
	fields = Env.Fields;
	if ( fields.UseReceiver ) then
		expenseDebts ( Env, Env.ReceiverDebts, fields.IsCustomer );
		makeReceiverGeneral ( Env );
		makeDifference ( Env );
	else
		makeGeneral ( Env );
		makeExpenses ( Env );
	endif;
	RunPayments.FixCash ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	setContext ( Env );
	sqlFields ( Env );
	getFields ( Env );
	sqlAdjustments ( Env );
	if ( Env.Fields.UseReceiver ) then
		sqlReceiverDebts ( Env );
	endif;
	SQL.Perform ( Env );
	
EndProcedure

Procedure setContext ( Env )
	
	if ( Env.Type = Type ( "DocumentRef.AdjustDebts" ) ) then
		Env.Insert ( "IsCustomer", true );
		Env.Insert ( "Table", "AdjustDebts" );
	else
		Env.Insert ( "IsCustomer", false );
		Env.Insert ( "Table", "AdjustVendorDebts" );
	endif; 
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company, Documents.Contract as Contract,";
	if ( Env.IsCustomer ) then
		s = s + "
		|Documents.CustomerAccount as OrganizationAccount, Documents.Customer as Organization,";
	else
		s = s + "
		|Documents.VendorAccount as OrganizationAccount, Documents.Vendor as Organization,";
	endif;
	s = s + "
	|	case when Documents.Type = value ( Enum.TypesAdjustDebts.Debt ) then true else false end as IsDebt,
	|	Documents.Amount as Amount, Documents.ContractAmount as ContractAmount, Documents.Rate as Rate,
	|	Documents.Factor as Factor, Documents.Account as Account, Documents.Dim1 as Dim1, Documents.Dim2 as Dim2, Documents.Dim3 as Dim3, 
	|	Documents.ContractCurrency as ContractCurrency, Documents.Currency as Currency, Constants.Currency as LocalCurrency,
	|	Documents.ContractRate as ContractRate, Documents.ContractFactor as ContractFactor,  
	|	case 
	|		when Documents.Option = value ( Enum.AdjustmentOptions.Expenses ) 
	|			or Documents.Account.Class in ( value ( Enum.Accounts.Expenses ), value ( Enum.Accounts.OtherExpenses ), value ( Enum.Accounts.CostOfGoodsSold ) ) then
	|			true
	|		else
	|			false
	|	end as IsExpense, Documents.Receiver as Receiver, Documents.ReceiverAccount as ReceiverAccount, Documents.ReceiverContract as ReceiverContract, 
	|	case 
	|		when Documents.Option in ( value ( Enum.AdjustmentOptions.Customer ), value ( Enum.AdjustmentOptions.Vendor ) ) then true
	|		else false
	|	end as UseReceiver,
	|	case 
	|		when Documents.Option = value ( Enum.AdjustmentOptions.Customer ) then true
	|		else false
	|	end as IsCustomer, Documents.Reversal as Reversal,
	|	case when Documents.TypeReceiver = value ( Enum.TypesAdjustDebts.Debt ) then true else false end as IsReceiverDebt, Documents.Option as Option
	|from Document." + Env.Table + " as Documents
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
	
	s = "
	|// Adjustments
	|select Adjustments.Contract.Owner as Organization, Adjustments.Contract as Contract, Adjustments.Document as Document,
	|	Adjustments.Amount as Amount, Adjustments.Payment as Payment, Adjustments.Overpayment as Overpayment,
	|	Adjustments.Debt as Debt, Adjustments.Bill as Bill, Adjustments.Detail as Detail, Adjustments.PaymentKey as PaymentKey,
	|	case 
	|		when ( Adjustments.Debt = 0 
	|			and Adjustments.Overpayment > 0 )
	|			or Adjustments.Debt > 0 then Adjustments.Amount
	|		else -Adjustments.Amount
	|	end as AmountDebts
	|into Adjustments
	|from Document." + Env.Table + ".Adjustments as Adjustments
	|where Adjustments.Ref = &Ref
	|;
	|// #Adjustments
	|select Adjustments.Organization as Organization, Adjustments.Contract as Contract, Adjustments.Document as Document,
	|	Adjustments.Amount as Amount, Adjustments.Payment as Payment, Adjustments.Overpayment as Overpayment, Adjustments.AmountDebts as AmountDebts,
	|	Adjustments.Debt as Debt, Adjustments.Bill as Bill, Adjustments.Detail as Detail, Adjustments.PaymentKey as PaymentKey
	|from Adjustments as Adjustments
	|;
	|// #AdjustmentsRecords
	|select Adjustments.Organization as Organization, Adjustments.Contract as Contract,	sum ( Adjustments.Amount ) as Amount
	|from Adjustments as Adjustments
	|group by Adjustments.Organization, Adjustments.Contract
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlReceiverDebts ( Env )
	
	s = "
	|// Debts
	|select Debts.Contract.Owner as Receiver, Debts.Contract as Contract, Debts.Document as Document,
	|	Debts.Applied as Amount, Debts.Payment as Payment, Debts.Overpayment as Overpayment,
	|	Debts.Debt as Debt, Debts.Bill as Bill, Debts.Detail as Detail, Debts.PaymentKey as PaymentKey,
	|	case 
	|		when ( Debts.Debt = 0 
	|			and Debts.Overpayment > 0 )
	|			or Debts.Debt > 0 then Debts.Applied
	|		else -Debts.Applied
	|	end as AmountDebts, Debts.Difference as Difference
	|into Debts
	|from Document." + Env.Table + ".ReceiverDebts as Debts
	|where Debts.Ref = &Ref
	|;
	|// #ReceiverDebts
	|select Debts.Receiver as Receiver, Debts.Contract as Contract, Debts.Document as Document,
	|	Debts.Amount as Amount, Debts.Payment as Payment, Debts.Overpayment as Overpayment, Debts.AmountDebts as AmountDebts,
	|	Debts.Debt as Debt, Debts.Bill as Bill, Debts.Detail as Detail, Debts.PaymentKey as PaymentKey
	|from Debts as Debts
	|;
	|// #ReceiverDebtsRecords
	|select Debts.Receiver as Receiver, Debts.Contract as Contract, sum ( Debts.Amount ) as Amount, sum ( Debts.Difference ) as Difference
	|from Debts as Debts
	|group by Debts.Receiver, Debts.Contract
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure expenseDebts ( Env, Table, IsCustomer )
	
	if ( IsCustomer ) then
		regiter = Env.Registers.Debts;
	else
		regiter = Env.Registers.VendorDebts;
	endif;
	fields = Env.Fields;
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
		movement.Contract = row.Contract;
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

Procedure makeReceiverGeneral ( Env ) 

	Env.Insert ( "Buffer", GeneralRecords.Frame () );
	receiverDebtsRecords = Env.ReceiverDebtsRecords.Copy ();
	receiverRecordsEmpty = false;
	for each row in Env.AdjustmentsRecords do
		amount = row.Amount;
		if ( not receiverRecordsEmpty ) then
			i = receiverDebtsRecords.Count ();
			while ( i > 0 ) do
				if ( amount = 0 ) then
					break;
				endif;
				i = i - 1;
				rowReceiver = receiverDebtsRecords [ i ];
				amountReceiver = rowReceiver.Amount;
				applied = Min ( amountReceiver, amount );
				rowReceiver.Amount = amountReceiver - applied;
				commitReceiverDebt ( Env, row, applied, rowReceiver );
				if ( rowReceiver.Amount = 0 ) then
					receiverDebtsRecords.Delete ( i );	
				endif;
				amount = amount - applied;
			enddo;
		endif;
		if ( amount > 0 ) then
			receiverRecordsEmpty = true;
			commitReceiverDebt ( Env, row, amount );
		endif;
	enddo;

EndProcedure

Procedure commitReceiverDebt ( Env, Row, Amount, RowReceiver = undefined )
	
	if ( samePosting ( Env, Row, RowReceiver ) ) then
		return;
	endif;
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	date = fields.Date;
	p.Date = date;
	p.Company = fields.Company;
	data = getAccountData ( Env );
	organization = data.Organization;
	receiver = data.Receiver;
	p.Operation = data.Operation;
	reversal = fields.Reversal;
	if ( reversal ) then
		temp = organization;
		organization = receiver;
		receiver = temp;
		coef = -1;
	else
		coef = 1;
	endif;
	p.Insert ( "Account" + organization, fields.OrganizationAccount );
	currency = fields.Currency;
	p.Insert ( "Currency" + organization, currency );
	contractRate = fields.ContractRate;
	contractFactor = fields.ContractFactor;
	contractCurrency = fields.ContractCurrency;
	currencyAmount = coef * Currencies.Convert ( Amount, contractCurrency, currency, date, contractRate, contractFactor, fields.Rate, fields.Factor );
	p.Insert ( "CurrencyAmount" + organization, currencyAmount );
	p.Insert ( "Dim" + organization + "1", Row.Organization );
	p.Insert ( "Dim" + organization + "2", Row.Contract );
	p.Insert ( "Account" + receiver, fields.ReceiverAccount );
	p.Insert ( "Currency" + receiver, currency );
	if ( RowReceiver = undefined ) then
		p.Insert ( "Dim" + receiver + "1", fields.Receiver );
		p.Insert ( "Dim" + receiver + "2", fields.ReceiverContract );
	else
		p.Insert ( "Dim" + receiver + "1", RowReceiver.Receiver );
		p.Insert ( "Dim" + receiver + "2", RowReceiver.Contract );
	endif;
	p.Insert ( "CurrencyAmount" + receiver, currencyAmount );
	p.Amount = coef * Currencies.Convert ( Amount, contractCurrency, fields.LocalCurrency, date, contractRate, contractFactor );
	p.Recordset = Env.Buffer;
	GeneralRecords.Add ( p );
	
EndProcedure

Function samePosting ( Env, Row, RowReceiver ) 

	fields = Env.Fields;
	if ( fields.OrganizationAccount <> fields.ReceiverAccount ) then
		return false;
	endif;
	if ( RowReceiver = undefined ) then
		receiver = fields.Receiver;
		receiverContract = fields.ReceiverContract;
	else
		receiver = RowReceiver.Receiver;
		receiverContract = RowReceiver.Contract;
	endif;
	if ( Row.Organization = receiver
		and Row.Contract = receiverContract ) then
		return true;
	endif;
	return false;

EndFunction

Function getAccountData ( Env )

	if ( Env.Fields.IsDebt ) then
		if ( Env.IsCustomer ) then
			organization = "Cr";
			receiver = "Dr";
			operation = Enums.Operations.AdjustDebts;
		else
			organization = "Dr";
			receiver = "Cr";
			operation = Enums.Operations.AdjustVendorDebts;
		endif;
	else
		if ( Env.IsCustomer ) then
			organization = "Dr";
			receiver = "Cr";
			operation = Enums.Operations.AdjustAdvances;
		else
			organization = "Cr";
			receiver = "Dr";
			operation = Enums.Operations.AdjustVendorAdvances;
		endif;
	endif;
	return new Structure ( "Organization, Receiver, Operation", organization, receiver, operation );

EndFunction

Procedure makeDifference ( Env ) 

	receiverDebtsRecords = Env.ReceiverDebtsRecords;
	if ( receiverDebtsRecords.Count () = 0 ) then
		difference = Env.AdjustmentsRecords.Total ( "Amount" );
	else
		difference = receiverDebtsRecords.Total ( "Difference" );
	endif;
	if ( difference > 0 ) then
		receiptDebts ( Env, difference );
	endif;

EndProcedure

Procedure receiptDebts ( Env, Amount )
	
	if ( Env.Fields.IsCustomer ) then
		movement = Env.Registers.Debts.AddReceipt ();
	else
		movement = Env.Registers.VendorDebts.AddReceipt ();
	endif;
	fields = Env.Fields;
	movement.Period = fields.Date;
	movement.Contract = fields.ReceiverContract;
	movement.Document = Env.Ref;
	if ( fields.IsReceiverDebt ) then
		movement.Overpayment = Amount;
	else
		movement.Amount = Amount;
	endif;
	
EndProcedure

Procedure makeGeneral ( Env ) 

	Env.Insert ( "Buffer", GeneralRecords.Frame () );
	for each row in Env.AdjustmentsRecords do
		commitDebt ( Env, row );
	enddo;

EndProcedure

Procedure commitDebt ( Env, Row )
	
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	date = fields.Date;
	p.Date = date;
	p.Company = fields.Company;
	data = getAccountData ( Env );
	organization = data.Organization;
	account = data.Receiver;
	p.Operation = data.Operation;
	p.Insert ( "Account" + organization, fields.OrganizationAccount );
	currency = fields.Currency;
	p.Insert ( "Currency" + organization, currency );
	amount = Row.Amount;
	contractRate = fields.ContractRate;
	contractFactor = fields.ContractFactor;
	contractCurrency = fields.ContractCurrency;
	currencyAmount = Currencies.Convert ( amount, contractCurrency, currency, date, contractRate, contractFactor, fields.Rate, fields.Factor );
	p.Insert ( "CurrencyAmount" + organization, currencyAmount );
	p.Insert ( "Dim" + organization + "1", Row.Organization );
	p.Insert ( "Dim" + organization + "2", Row.Contract );
	p.Insert ( "Account" + account, fields.Account );
	p.Insert ( "Currency" + account, currency );
	p.Insert ( "Dim" + account + "1", fields.Dim1 );
	p.Insert ( "Dim" + account + "2", fields.Dim2 );
	p.Insert ( "Dim" + account + "3", fields.Dim3 );
	p.Insert ( "CurrencyAmount" + account, currencyAmount );
	p.Amount = Currencies.Convert ( amount, contractCurrency, fields.LocalCurrency, date, contractRate, contractFactor );
	p.Recordset = Env.Buffer;
	GeneralRecords.Add ( p );
	
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
	GeneralRecords.Flush ( registers.General, Env.Buffer );
	registers.General.Write = true;
	registers.Debts.Write = true;
	registers.VendorDebts.Write = true;
	registers.Expenses.Write = true;
	
EndProcedure
