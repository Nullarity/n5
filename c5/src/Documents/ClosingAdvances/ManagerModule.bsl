#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.ClosingAdvances.Synonym + " #" + Data.Number + " " + Format ( Data.Date, "DLF=D" );
	
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
	sqlAdvances ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company, Documents.VATAccount as VATAccount, 
	|	Documents.ReceivablesVATAccount as ReceivablesVATAccount, Documents.VATExport as VATExport,
	|	Documents.VATAdvance as VATAdvance
	|from Document.ClosingAdvances as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlAdvances ( Env )
	
	s = "
	|// #Advances
	|select Advances.Amount as Amount, Advances.CloseAdvance as CloseAdvance, Advances.Contract as Contract, Advances.Currency as Currency, 
	|	Advances.CurrencyAmount as CurrencyAmount, Advances.Customer as Customer, Advances.CustomerAccount as CustomerAccount, 
	|	Advances.CustomerAccount.Currency as Export, Advances.AdvanceAccount as AdvanceAccount, Advances.VAT as VAT, Advances.VATAmount as VATAmount
	|from Document.ClosingAdvances.Advances as Advances
	|where Advances.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure commitRecords ( Env )
	
	closeAdvances = OutputCont.CloseAdvances ();
	receiptAdvances = OutputCont.ReceiptAdvances ();
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Registers.General;
	for each row in Env.Advances do
		if ( row.CloseAdvance ) then
			customerType = "Cr";
			advanceType = "Dr";
			p.Content = closeAdvances;
		else
			customerType = "Dr";
			advanceType = "Cr";
			p.Content = receiptAdvances;
		endif;
		p [ "Account" + customerType ] = row.CustomerAccount;
		p [ "Account" + advanceType ] = row.AdvanceAccount;
		customer = row.Customer;
		contract = row.Contract;
		currency = row.Currency;
		currencyAmount = row.CurrencyAmount;
		p.DimDr1 = customer;
		p.DimCr1 = customer;
		p.DimDr2 = contract;
		p.DimCr2 = contract;
		p.CurrencyDr = currency;
		p.CurrencyCr = currency;
		p.CurrencyAmountDr = currencyAmount;
		p.CurrencyAmountCr = currencyAmount;
		p.Amount = row.Amount;
		GeneralRecords.Add ( p );
		if ( not row.Export ) then
			commitVAT ( p, row, fields );
		endif;
	enddo; 

EndProcedure

Procedure commitVAT ( Record, Row, Fields )
	
	Record.AccountDr = Fields.ReceivablesVATAccount;
	Record.AccountCr = Fields.VATAccount;
	Record.DimDr1 = Row.Customer;
	Record.DimDr2 = Row.Contract;
	Record.Amount = Row.VATAmount;
	if ( Row.CloseAdvance ) then
		Record.Content = OutputCont.CloseAdvancesVAT ();
	else
		Record.Content = OutputCont.ReceiptAdvancesVAT ();
	endif;
	GeneralRecords.Add ( Record );

EndProcedure

Procedure flagRegisters ( Env )
	
	Env.Registers.General.Write = true;
	
EndProcedure

#endregion

#endif