#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.ClosingAdvancesGiven.Synonym + " #" + Data.Number + " " + Format ( Data.Date, "DLF=D" );
	
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
	|select Documents.Date as Date, Documents.Company as Company
	|from Document.ClosingAdvancesGiven as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlAdvances ( Env )
	
	s = "
	|// #Advances
	|select Advances.Amount as Amount, Advances.CloseAdvance as CloseAdvance, Advances.Contract as Contract, Advances.Currency as Currency, 
	|	Advances.CurrencyAmount as CurrencyAmount, Advances.Vendor as Vendor, Advances.VendorAccount as VendorAccount, 
	|	Advances.VendorAccount.Currency as Import, Advances.AdvanceAccount as AdvanceAccount
	|from Document.ClosingAdvancesGiven.Advances as Advances
	|where Advances.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure commitRecords ( Env )
	
	closeAdvances = Output.CloseAdvancesGiven ();
	givenAdvances = Output.GivenAdvances ();
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Registers.General;
	for each row in Env.Advances do
		if ( row.CloseAdvance ) then
			vendorType = "Dr";
			advanceType = "Cr";
			p.Content = closeAdvances;
		else
			vendorType = "Cr";
			advanceType = "Dr";
			p.Content = givenAdvances;
		endif;
		p [ "Account" + vendorType ] = row.VendorAccount;
		p [ "Account" + advanceType ] = row.AdvanceAccount;
		vendor = row.Vendor;
		contract = row.Contract;
		currency = row.Currency;
		currencyAmount = row.CurrencyAmount;
		p.DimDr1 = vendor;
		p.DimCr1 = vendor;
		p.DimDr2 = contract;
		p.DimCr2 = contract;
		p.CurrencyDr = currency;
		p.CurrencyCr = currency;
		p.CurrencyAmountDr = currencyAmount;
		p.CurrencyAmountCr = currencyAmount;
		p.Amount = row.Amount;
		GeneralRecords.Add ( p );
	enddo; 

EndProcedure

Procedure flagRegisters ( Env )
	
	Env.Registers.General.Write = true;
	
EndProcedure

#endregion

#endif
