#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.YearClose.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	commit ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction
 
Procedure getData ( Env )
	
	sqlFields ( Env );
	sqlRecords ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select dateadd ( beginofperiod ( Documents.Date, year ), second, -1 ) as Date, Documents.Company as Company,
	|	Documents.FinancialResult as FinancialResult, Documents.ProfitLoss as ProfitLoss, Documents.Memo as Memo
	|from Document.YearClose as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlRecords ( Env )
	
	s = "
	|// #Records
	|select Records.AccountDr as AccountDr, Records.AccountCr as AccountCr,
	|	Records.CurrencyDr as CurrencyDr, Records.CurrencyAmountDr as CurrencyAmountDr, Records.RateDr as RateDr,
	|	Records.FactorDr as FactorDr, Records.QuantityDr as QuantityDr, Records.DimDr1 as DimDr1, Records.DimDr2 as DimDr2,
	|	Records.DimDr3 as DimDr3, Records.CurrencyCr as CurrencyCr,
	|	Records.CurrencyAmountCr as CurrencyAmountCr, Records.RateCr as RateCr, Records.FactorCr as FactorCr,
	|	Records.QuantityCr as QuantityCr, Records.DimCr1 as DimCr1, Records.DimCr2 as DimCr2,
	|	Records.DimCr3 as DimCr3, Records.Amount as Amount
	|from Document.YearClose.Records as Records
	|where Records.Ref = &Ref
	|order by Records.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure commit ( Env )
	
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	financialResult = fields.FinancialResult;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Registers.General;
	total = 0;
	for each row in Env.Records do
		p.AccountDr = row.AccountDr;
		p.AccountCr = row.AccountCr;
		amount = row.Amount;
		p.Amount = amount;
		p.QuantityDr = row.QuantityDr;
		p.QuantityCr = row.QuantityCr;
		p.DimDr1 = row.DimDr1;
		p.DimDr2 = row.DimDr2;
		p.DimDr3 = row.DimDr3;
		p.DimCr1 = row.DimCr1;
		p.DimCr2 = row.DimCr2;
		p.DimCr3 = row.DimCr3;
		p.CurrencyDr = row.CurrencyDr;
		p.CurrencyAmountDr = row.CurrencyAmountDr;
		p.CurrencyCr = row.CurrencyCr;
		p.CurrencyAmountCr = row.CurrencyAmountCr;
		GeneralRecords.Add ( p );
		total = total + ? ( row.AccountDr = financialResult, - amount, amount );
	enddo; 
	p.AccountDr = financialResult;
	p.AccountCr = fields.ProfitLoss;
	p.Content = fields.Memo;
	p.Amount = total;
	GeneralRecords.Add ( p );

EndProcedure 

Procedure flagRegisters ( Env )
	
	Env.Registers.General.Write = true;
	
EndProcedure

#endregion

#endif