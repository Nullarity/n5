#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.CalculationRatesDifferences.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	adjustDebts ( Env );
	commitRecords ( Env );
	makeExpenses ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction
 
Procedure getData ( Env )
	
	sqlFields ( Env );
	getFields ( Env );
	sqlRecords ( Env );
	getRecords ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company, Documents.AccountNegative as AccountNegative, Documents.Dim1 as Dim1,
	|	Documents.AccountPositive as AccountPositive, Documents.CashFlow as CashFlow, Documents.Dim2 as Dim2, Documents.Dim3 as Dim3
	|from Document.CalculationRatesDifferences as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env ) 

	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );

EndProcedure

Procedure sqlRecords ( Env )
	
	s = "
	|select case Rates.Rate when 0 then 1 else Rates.Rate end as Rate,
	|	case Rates.Factor when 0 then 1 else Rates.Factor end as Factor,
	|	Rates.Currency as Currency
	|into Rates
	|from InformationRegister.ExchangeRates.SliceLast ( &Date ) as Rates
	|;
	|select Records.Account as Account, Records.Dim1 as Dim1, Records.Currency as Currency, 
	|	Records.Difference < 0 as Expense,
	|	case when Records.Difference < 0 then - Records.Difference else Records.Difference end as Difference
	|into Records
	|from ( 
	|	select Records.Account as Account, Records.ExtDimension1 as Dim1, Records.Currency as Currency,
	|		cast ( CurrencyAmountBalance / isnull ( Rates.Factor, 1 ) * isnull ( Rates.Rate, 1 ) - AmountBalance
	|			as Number ( 15, 2 ) ) as Difference 
	|	from AccountingRegister.General.Balance ( &Date, Account.Currency, , Company = &Company ) as Records
	|		//
	|		// Rates
	|		//
	|		left join Rates as Rates
	|		on Rates.Currency = Records.Currency 
	|	) as Records
	|where Records.Difference <> 0
	|and Records.Account not in (
	|	select distinct Account from Document.CalculationRatesDifferences.Accounts where Ref = &Ref
	|)
	|;
	|// #Records
	|select Records.Account as Account, Records.Dim1 as Dim1, Records.Currency as Currency, 
	|	Records.Expense as Expense, Records.Difference as Difference
	|from Records as Records
	|;
	|// #Debts
	|select Debts.Customer as Customer, Debts.Contract as Contract, Debts.Document as Document,
	|	Debts.Detail as Detail, Debts.PaymentKey as PaymentKey,
	|	Debts.AmountDifference as Accounting, Debts.AdvanceDifference as Advance
	|from (
	|	select true as Customer, Debts.Contract as Contract, Debts.Document as Document,
	|		Debts.Detail as Detail, Debts.PaymentKey as PaymentKey,
	|		cast ( AmountBalance / isnull ( Rates.Factor, 1 ) * isnull ( Rates.Rate, 1 ) - AccountingBalance
	|			as Number ( 15, 2 ) ) as AmountDifference,
	|		cast ( OverpaymentBalance / isnull ( Rates.Factor, 1 ) * isnull ( Rates.Rate, 1 ) - AdvanceBalance
	|			as Number ( 15, 2 ) ) as AdvanceDifference
	|	from AccumulationRegister.Debts.Balance ( &Date, Contract.Owner in ( select Dim1 from Records ) ) as Debts
	|		//
	|		// Rates
	|		//
	|		left join Rates as Rates
	|		on Rates.Currency = Debts.Contract.Currency 
	|	union all
	|	select false, Debts.Contract, Debts.Document, Debts.Detail, Debts.PaymentKey,
	|		cast ( AmountBalance / isnull ( Rates.Factor, 1 ) * isnull ( Rates.Rate, 1 ) - AccountingBalance
	|			as Number ( 15, 2 ) ),
	|		cast ( OverpaymentBalance / isnull ( Rates.Factor, 1 ) * isnull ( Rates.Rate, 1 ) - AdvanceBalance
	|			as Number ( 15, 2 ) )
	|	from AccumulationRegister.VendorDebts.Balance ( &Date, Contract.Owner in ( select Dim1 from Records ) ) as Debts
	|		//
	|		// Rates
	|		//
	|		left join Rates as Rates
	|		on Rates.Currency = Debts.Contract.Currency
	|	) as Debts
	|where Debts.AmountDifference <> 0
	|or Debts.AdvanceDifference <> 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getRecords ( Env ) 

	q = Env.Q;
	fields = Env.Fields;
	q.SetParameter ( "Date", fields.Date );
	q.SetParameter ( "Company", fields.Company );
	SQL.Perform ( Env );

EndProcedure

Procedure adjustDebts ( Env )
	
	date = Env.Fields.Date;
	registers = Env.Registers;
	debts = registers.Debts;
	vendorDebts = registers.VendorDebts;
	for each row in Env.Debts do
		r = ? ( row.Customer, debts.Add (), vendorDebts.Add () );
		FillPropertyValues ( r, row );
		r.Period = date;
	enddo;

EndProcedure 

Procedure commitRecords ( Env )
	
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Registers.General;
	accountNegative = fields.AccountNegative;
	accountPositive = fields.AccountPositive;
	cashFlow = fields.CashFlow;
	dim1 = fields.Dim1;
	dim2 = fields.Dim2;
	dim3 = fields.Dim3;
	operations = Enums.Operations;
	positiveDifference = operations.PositiveCurrencyDifference;
	negativeDifference = operations.NegativeCurrencyDifference;
	for each row in Env.Records do
		if ( row.Expense ) then
			account = "Cr";
			p.AccountDr = accountNegative;
			p.DimDr1 = dim1;
			p.DimDr2 = dim2;
			p.DimDr3 = dim3;
			p.Content = negativeDifference;
		else
			account = "Dr";
			p.AccountCr = accountPositive;
			p.Content = positiveDifference;
		endif;
		p.Amount = row.Difference;
		p [ "Account" + account ] = row.Account;
		p [ "Dim" + account + "1" ] = row.Dim1;
		p [ "Dim" + account + "2" ] = cashFlow;
		p [ "Currency" + account ] = row.Currency;
		GeneralRecords.Add ( p );
	enddo; 

EndProcedure 

Procedure makeExpenses ( Env )
	
	amount = Env.Records.Copy ( new Structure ( "Expense", true ) ).Total ( "Difference" );
	if ( amount = 0 ) then
		return;
	endif;
	fields = Env.Fields;
	movement = Env.Registers.Expenses.Add ();
	movement.Period = fields.Date;
	movement.Document = Env.Ref;
	movement.Account = fields.AccountNegative;
	value = fields.Dim1;
	if ( TypeOf ( value ) = Type ( "CatalogRef.Expenses" ) ) then
		movement.Expense = value
	endif;
	value = fields.Dim2;
	if ( TypeOf ( value ) = Type ( "CatalogRef.Departments" ) ) then
		movement.Department = value
	endif;
	movement.AmountDr = amount;
	
EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	registers.Expenses.Write = true;
	registers.Debts.Write = true;
	registers.VendorDebts.Write = true;
	
EndProcedure

#endregion

#endif