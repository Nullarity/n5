#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Balances.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	commitRecords ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction
 
Procedure getData ( Env )
	
	sqlFields ( Env );
	sqlDetails ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select dateadd ( Documents.Date, second, - 1 ) as Date, Documents.Company as Company,
	|	Documents.Account as Account, Documents.Account.OffBalance as OffBalance, Documents.Account.Type as Type
	|from Document.Balances as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlDetails ( Env )
	
	s = "
	|// #Details
	|select Details.Amount as Amount, Details.Currency as Currency, Details.CurrencyAmount as CurrencyAmount,
	|	Details.Dim1 as Dim1, Details.Dim2 as Dim2, Details.Dim3 as Dim3, Details.Quantity as Quantity
	|from Document.Balances.Details as Details
	|where Details.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure commitRecords ( Env )
	
	fields = Env.Fields;
	account = fields.Account;
	balance = not fields.Offbalance;
	passive = fields.Type = AccountType.Passive;
	zero = ChartsOfAccounts.General._0;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Content = Output.OpeningBalances ();
	p.Recordset = Env.Registers.General;
	if ( passive ) then
		p.AccountCr = account;
		if ( balance ) then
			p.AccountDr = zero;
		endif; 
	else
		p.AccountDr = account;
		if ( balance ) then
			p.AccountCr = zero;
		endif; 
	endif;
	for each row in Env.Details do
		if ( passive ) then
			p.DimCr1 = row.Dim1;
			p.DimCr2 = row.Dim2;
			p.DimCr3 = row.Dim3;
			p.QuantityCr = row.Quantity;
			p.CurrencyCr = row.Currency;
			p.CurrencyAmountCr = row.CurrencyAmount;
		else
			p.DimDr1 = row.Dim1;
			p.DimDr2 = row.Dim2;
			p.DimDr3 = row.Dim3;
			p.QuantityDr = row.Quantity;
			p.CurrencyDr = row.Currency;
			p.CurrencyAmountDr = row.CurrencyAmount;
		endif; 
		p.Amount = row.Amount;
		GeneralRecords.Add ( p );
	enddo; 

EndProcedure 

Procedure flagRegisters ( Env )
	
	Env.Registers.General.Write = true;
	
EndProcedure

#endregion

#endif