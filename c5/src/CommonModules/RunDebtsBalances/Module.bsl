Function Post ( Env ) export
	
	getData ( Env );
	PaymentDetails.Init ( Env );
	makeDebts ( Env );
	commitDebts ( Env );
	flagRegisters ( Env );
	PaymentDetails.Save ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	setContext ( Env );
	sqlFields ( Env );
	sqlDebts ( Env );
	getTables ( Env );
	
EndProcedure

Procedure setContext ( Env ) 

	if ( TypeOf ( Env.Ref ) = Type ( "DocumentRef.Debts" ) ) then
		table = "Debts";
		isDebts = true;
	else
		table = "VendorDebts";
		isDebts = false;
	endif;
	Env.Insert ( "Table", table );
	Env.Insert ( "IsDebts", isDebts );

EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select dateadd ( Documents.Date, second, - 1 ) as Date, Documents.Company as Company,
	|	Documents.Account as Account,";
	if ( Env.IsDebts ) then
		s = s + "
		|	case when Documents.Account.Type = value ( AccountType.Active ) then false else true end as Advances";
	else
		s = s + "
		|	case when Documents.Account.Type = value ( AccountType.Active ) then true else false end as Advances";
	endif;
	s = s + "
	|from Document." + Env.Table + " as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlDebts ( Env )
	
	if ( Env.IsDebts ) then
		organization = "Debts.Customer as Customer";
	else
		organization = "Debts.Vendor as Vendor";
	endif;
	s = "
	|// Debts
	|select Debts.Contract as Contract, Debts.Amount as Amount, Debts.ContractAmount as ContractAmount,
	|	case when Debts.Date = datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Debts.Date end as Date, Debts.Document as Document,
	|	Debts.Option as Option, Debts.Advance as Advance, Debts.ContractAdvance as ContractAdvance,	Debts.Contract.Currency as ContractCurrency,
	|	case when Debts.Contract.Currency = Constants.Currency then true else false end as IsLocalCurrency, " + organization + "
	|into Debts
	|from Document." + Env.Table + ".Debts as Debts
	|	//
	|	//	Constants
	|	//
	|	left join Constants as Constants
	|	on true
	|where Debts.Ref = &Ref
	|;
	|// #Debts
	|select Debts.Contract as Contract, Debts.Amount as Amount, " + organization + ",
	|	case when Debts.IsLocalCurrency then Debts.Amount else Debts.ContractAmount end as ContractAmount,
	|	case when Debts.IsLocalCurrency then Debts.Advance else Debts.ContractAdvance end as ContractAdvance,
	|	Debts.Date as Date, Debts.Option as Option, Debts.Advance as Advance,
	|	Debts.ContractCurrency as ContractCurrency, Debts.Document as Document, Details.PaymentKey as PaymentKey
	|from Debts as Debts
	|	//
	|	//	Payment PaymentDetails
	|	//
	|	left join InformationRegister.PaymentDetails as Details
	|	on Details.Option = Debts.Option
	|	and Details.Date = Debts.Date
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure makeDebts ( Env ) 

	if ( Env.IsDebts ) then
		recordset = Env.Registers.Debts;
	else
		recordset = Env.Registers.VendorDebts;
	endif;
	fields = Env.Fields;
	date = fields.Date;
	advances = fields.Advances;
	ref = Env.Ref;
	for each row in Env.Debts do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		movement.Contract = row.Contract;
		movement.PaymentKey = getPaymentKey ( Env, row );
		document = row.Document;
		if ( document.IsEmpty () ) then
			movement.Document = ref;
		else
			movement.Document = document;
			movement.Detail = ref;
		endif;	
		if ( advances ) then
			movement.Overpayment = row.ContractAdvance;
		else
			amount = row.ContractAmount;
			movement.Amount = amount;
			movement.Payment = amount;
		endif;
	enddo;
	
EndProcedure

Function getPaymentKey ( Env, Row )
	
	paymentKey = Row.PaymentKey;
	if ( paymentKey = null ) then
		details = Env.PaymentDetails;
		details.Option = Row.Option;
		details.Date = Row.Date;
		return PaymentDetails.GetKey ( Env );
	else
		return paymentKey;
	endif; 
		
EndFunction 

Procedure commitDebts ( Env ) 

	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Content = Output.OpeningBalances ();
	p.Recordset = Env.Registers.General;
	advances = fields.Advances;
	isDebts = Env.IsDebts;
	zeroAccount = ChartsOfAccounts.General._0;
	if ( isDebts ) then
		if ( advances ) then
			contractors = "Cr";
			p.AccountDr = zeroAccount;
		else
			contractors = "Dr";
			p.AccountCr = zeroAccount;
		endif;
	else
		if ( advances ) then
			contractors = "Dr";
			p.AccountCr = zeroAccount;
		else
			contractors = "Cr";
			p.AccountDr = zeroAccount;
		endif;
	endif;
	p [ "Account" + contractors ] = fields.Account;
	for each row in Env.Debts do
		if ( advances ) then
			p.Amount = row.Advance;
			p [ "CurrencyAmount" + contractors ] = row.ContractAdvance;
		else
			p.Amount = row.Amount;
			p [ "CurrencyAmount" + contractors ] = row.ContractAmount;
		endif;
		p [ "Dim" + contractors + "1" ] = ? ( isDebts, row.Customer, row.Vendor );
		p [ "Dim" + contractors + "2" ] = row.Contract;
		p [ "Currency" + contractors ] = row.ContractCurrency;
		GeneralRecords.Add ( p );
	enddo;

EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	if ( Env.IsDebts ) then
		registers.Debts.Write = true;
	else
		registers.VendorDebts.Write = true;
	endif;
	
EndProcedure
