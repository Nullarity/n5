#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure Enroll ( Document ) export
	
	SetPrivilegedMode ( true );
	r = CreateRecordManager ();
	r.Date = Document.Date;
	r.Document = Document.Ref;
	type = TypeOf ( Document );
	if ( type = Type ( "DocumentObject.Entry" ) ) then
		passed = enrollEntry ( r, Document );
	elsif ( type = Type ( "DocumentObject.Payment" )
		or type = Type ( "DocumentObject.Refund" )
		or type = Type ( "DocumentObject.VendorPayment" )
		or type = Type ( "DocumentObject.VendorRefund" ) ) then
		passed = enrollPayment ( r, Document );
	elsif ( type = Type ( "DocumentObject.PayEmployees" ) ) then
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

Function enrollPayment ( Record, Document )
	
	if ( not bankPayment ( Document.Method ) ) then
		return false;
	endif; 
	Record.Amount = Document.Amount;
	Record.Currency = Document.Currency;
	Record.Account = Document.BankAccount;
	if ( TypeOf ( Document ) = Type ( "DocumentObject.Payment" )
		or TypeOf ( Document ) = Type ( "DocumentObject.Refund" ) ) then
		Record.Analytics = Document.Customer;
	else
		Record.Analytics = Document.Vendor;
	endif; 
	return true;
	
EndFunction

Function bankPayment ( Method )
	
	return method = Enums.PaymentMethods.AmericanExpress
	or method = Enums.PaymentMethods.Bank
	or method = Enums.PaymentMethods.EFT
	or method = Enums.PaymentMethods.Mastercard
	or method = Enums.PaymentMethods.PayPal
	or method = Enums.PaymentMethods.Visa;
	
EndFunction 

Function enrollPayEmployees ( Record, Document )
	
	if ( not bankPayment ( Document.Method ) ) then
		return false;
	endif; 
	Record.Amount = Document.Amount;
	Record.Currency = Application.Currency ();
	Record.Account = Document.BankAccount;
	return true;
	
EndFunction

#endif

Function enrollEntry ( Record, Document )
	
	operation = DF.Pick ( Document.Operation,  "Operation" );
	if ( operation = Enums.Operations.BankReceipt ) then
		entry = "Cr";
		bank = "Dr";
	elsif ( operation = Enums.Operations.BankExpense ) then
		entry = "Dr";
		bank = "Cr";
	else
		return false;
	endif; 
	records = Document.Records;
	if ( records.Count () = 0 ) then
		return true;
	endif; 
	row = records [ 0 ];
	Record.Operation = Document.Operation;
	Record.Account = row [ "Dim" + bank + "1" ];
	analytics = row [ "Dim" + entry + "1" ];
	account = row [ "Account" + entry ];
	if ( ValueIsFilled ( analytics ) ) then
		Record.Analytics = analytics;
	else
		Record.Analytics = DF.Pick ( account, ? ( Options.Russian (), "DescriptionRu", "DescriptionRo" ) );
	endif; 
	currency = DF.Pick ( account, "Currency", false );
	if ( currency ) then
		Record.Amount = row [ "CurrencyAmount" + entry ];
		Record.Currency = row [ "Currency" + entry ];
	else
		Record.Amount = row.Amount;
		Record.Currency = Application.Currency ();
	endif; 
	return true;
	
EndFunction
