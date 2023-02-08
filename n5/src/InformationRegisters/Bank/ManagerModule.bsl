#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure Enroll ( Document ) export
	
	SetPrivilegedMode ( true );
	type = TypeOf ( Document );
	if ( type = Type ( "DocumentObject.Entry" ) ) then
		enrollEntry ( Document );
		return;
	endif;
	r = CreateRecordManager ();
	r.Date = Document.Date;
	r.Document = Document.Ref;
	if ( type = Type ( "DocumentObject.Payment" )
		or type = Type ( "DocumentObject.Refund" )
		or type = Type ( "DocumentObject.VendorPayment" )
		or type = Type ( "DocumentObject.VendorRefund" ) ) then
		passed = enrollPayment ( r, Document );
	elsif ( type = Type ( "DocumentObject.PayEmployees" )
		or type = Type ( "DocumentObject.PayAdvances" ) ) then
		passed = enrollPayEmployees ( r, Document );
	endif; 
	if ( not passed ) then
		r.Delete ();
		return;
	endif; 
	r.Memo = Document.Memo;
	r.Number = Document.Number;
	r.Company = Document.Company;
	r.Posted = Document.Posted;
	r.DeletionMark = Document.DeletionMark;
	r.Reference = Document.Reference;
	r.ReferenceDate = Document.ReferenceDate;
	r.Write ();
	
EndProcedure

Procedure enrollEntry ( Document )
	
	unrollEntry ( Document );
	records = Document.Records;
	if ( records.Count () = 0 ) then
		commitEntry ( Document, 0, undefined, undefined, undefined, 0, undefined, true, "" );
	else
		id = 0;
		for each row in records do
			if ( row.DrClass = Enums.Accounts.Bank ) then
				commitEntry ( Document, id, row.DimDr1, row.AccountDr, row.DimCr1, row.Amount, row.CurrencyCr, true,
					? ( row.Content = "", Document.Memo, row.Content ) );
				id = id + 1;
			endif;
			if ( row.CrClass = Enums.Accounts.Bank ) then
				commitEntry ( Document, id, row.DimCr1, row.AccountCr, row.DimDr1, row.Amount, row.CurrencyDr, false,
					? ( row.Content = "", Document.Memo, row.Content ) );
				id = id + 1;
			endif;
		enddo;
	endif;
	
EndProcedure

Procedure unrollEntry ( Document )
	
	s = "select Record from InformationRegister.Bank where Document = &Ref";
	q = new Query ( s );
	ref = Document.Ref;
	q.SetParameter ( "Ref", ref );
	list = q.Execute ().Unload ().UnloadColumn ( "Record" );
	for each id in list do
		r = CreateRecordManager ();
		r.Document = ref;
		r.Record = id;
		r.Delete ();
	enddo;
	
EndProcedure

Procedure commitEntry ( Document, ID, BankAccount, Account, Dimension, Amount, Currency, Dr, Memo )
	
	r = CreateRecordManager ();
	r.Date = Document.Date;
	r.Document = Document.Ref;
	r.Record = ID;
	r.Operation = Document.Operation;
	r.Dr = Dr;
	r.Memo = Memo;
	r.Number = Document.Number;
	r.Company = Document.Company;
	r.Posted = Document.Posted;
	r.DeletionMark = Document.DeletionMark;
	r.Reference = Document.Reference;
	r.ReferenceDate = Document.ReferenceDate;
	r.AccountCode = Account;
	r.Account = BankAccount;
	accountDefined = ValueIsFilled ( Account );
	if ( ValueIsFilled ( Dimension ) ) then
		r.Analytics = Dimension;
	elsif ( accountDefined ) then
		r.Analytics = DF.Pick ( Account, "Description" );
	endif; 
	if ( accountDefined ) then
		isCurrency = DF.Pick ( Account, "Currency", false );
		if ( isCurrency ) then
			r.Amount = Amount;
			r.Currency = Currency;
		else
			r.Amount = Amount;
			r.Currency = Application.Currency ();
		endif; 
	else
		r.Amount = 0;
		r.Currency = undefined;
	endif;
	r.Write ();
	
EndProcedure

Function enrollPayment ( Record, Document )
	
	if ( not bankPayment ( Document.Method ) ) then
		return false;
	endif; 
	Record.Amount = Document.Amount;
	Record.Currency = Document.Currency;
	Record.Account = Document.BankAccount;
	type = TypeOf ( Document );
	if ( type = Type ( "DocumentObject.Payment" )
		or type = Type ( "DocumentObject.Refund" ) ) then
		Record.Analytics = Document.Customer;
	else
		Record.Analytics = Document.Vendor;
	endif; 
	Record.Dr = ( type = Type ( "DocumentObject.Payment" )
	or type = Type ( "DocumentObject.VendorRefund" ) );
	return true;
	
EndFunction

Function bankPayment ( Method )
	
	return method = Enums.PaymentMethods.AmericanExpress
	or method = Enums.PaymentMethods.Check
	or method = Enums.PaymentMethods.Bank
	or method = Enums.PaymentMethods.EFT
	or method = Enums.PaymentMethods.Mastercard
	or method = Enums.PaymentMethods.PayPal
	or method = Enums.PaymentMethods.Visa
	or method = Enums.PaymentMethods.Card;
	
EndFunction 

Function enrollPayEmployees ( Record, Document )
	
	if ( not bankPayment ( Document.Method ) ) then
		return false;
	endif; 
	Record.Dr = false;
	Record.Amount = Document.Amount;
	Record.Currency = Application.Currency ();
	Record.Account = Document.BankAccount;
	Record.AccountCode = Document.Account;
	return true;
	
EndFunction

#endif
