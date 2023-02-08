#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.CashTransfer.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	commitAccounts ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction
 
Procedure getData ( Env )
	
	sqlFields ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select top 1 Documents.Date as Date, Documents.Company as Company, Documents.Amount as Amount, Documents.Currency as Currency,
	|	Documents.Sender as Sender, Documents.Account as Account, Documents.Receiver as Receiver, Documents.AccountTo as AccountTo,
	|	Documents.Rate as Rate, Documents.Factor as Factor, Constants.Currency as LocalCurrency, Documents.Memo as Memo
	|from Document.CashTransfer as Documents
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on true
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure commitAccounts ( Env )
	
	fields = Env.Fields;
	currency = fields.Currency;
	amount = fields.Amount;
	date = fields.Date;
	p = GeneralRecords.GetParams ();
	p.Date = date;
	p.Company = fields.Company;
	p.Recordset = Env.Registers.General;
	p.CurrencyDr = currency;
	p.CurrencyCr = currency;
	p.Amount = Currencies.Convert ( amount, currency, fields.LocalCurrency, date, fields.Rate, fields.Factor );
	p.CurrencyAmountDr = amount;
	p.CurrencyAmountCr = amount;
	p.AccountDr = fields.AccountTo;
	p.AccountCr = fields.Account;
	p.DimDr1 = fields.Receiver;
	p.DimCr1 = fields.Sender;
	p.Content = fields.Memo;
	GeneralRecords.Add ( p );

EndProcedure 

Procedure flagRegisters ( Env )
	
	Env.Registers.General.Write = true;
	
EndProcedure

#endregion

#endif