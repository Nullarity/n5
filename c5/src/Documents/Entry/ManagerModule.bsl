#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.IncomingFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.IncomingPresentation ( Metadata.Documents.Entry.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	if ( not checkErrors ( Env ) ) then
		return false;
	endif;
	commit ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction
 
Procedure getData ( Env )
	
	sqlFields ( Env );
	sqlRecords ( Env );
	sqlBalance ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company
	|from Document.Entry as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlRecords ( Env )
	
	s = "
	|// #Records
	|select
	|	case
	|		when Records.AccountDr = value ( ChartOfAccounts.General.EmptyRef )
	|			and not Records.AccountCr.OffBalance then
	|			value ( ChartOfAccounts.General._0 )
	|		else
	|			Records.AccountDr
	|	end as AccountDr,
	|	case
	|		when Records.AccountCr = value ( ChartOfAccounts.General.EmptyRef )
	|			and not Records.AccountDr.OffBalance then
	|			value ( ChartOfAccounts.General._0 )
	|		else
	|			Records.AccountCr
	|	end as AccountCr,
	|	Records.CurrencyDr as CurrencyDr, Records.CurrencyAmountDr as CurrencyAmountDr, Records.RateDr as RateDr,
	|	Records.FactorDr as FactorDr, Records.QuantityDr as QuantityDr, Records.DimDr1 as DimDr1, Records.DimDr2 as DimDr2,
	|	Records.DimDr3 as DimDr3, Records.CurrencyCr as CurrencyCr,
	|	Records.CurrencyAmountCr as CurrencyAmountCr, Records.RateCr as RateCr, Records.FactorCr as FactorCr,
	|	Records.QuantityCr as QuantityCr, Records.DimCr1 as DimCr1, Records.DimCr2 as DimCr2,
	|	Records.DimCr3 as DimCr3, Records.Content as Content, Records.Amount as Amount
	|from Document.Entry.Records as Records
	|where Records.Ref = &Ref
	|order by Records.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlBalance ( Env )
	
	s = "
	|// @Error
	|select 1
	|from Document.Entry.Records as Records
	|where Records.Ref = &Ref
	|and not Records.AccountDr.OffBalance
	|and not Records.AccountCr.OffBalance
	|having sum ( Records.AmountDr ) <> sum ( Records.AmountCr )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Function checkErrors ( Env )
	
	if ( Env.Error = undefined ) then
		return true;
	endif;
	Output.UnbalancedEntry ( , , Env.Ref );
	return false;
	
EndFunction

Procedure commit ( Env )
	
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Registers.General;
	for each row in Env.Records do
		p.AccountDr = row.AccountDr;
		p.AccountCr = row.AccountCr;
		p.Amount = row.Amount;
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
		p.Content = row.Content;
		GeneralRecords.Add ( p );
	enddo; 

EndProcedure 

Procedure flagRegisters ( Env )
	
	Env.Registers.General.Write = true;
	
EndProcedure

#endregion

#endif