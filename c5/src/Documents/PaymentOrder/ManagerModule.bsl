
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.PaymentOrder.Synonym + " #" + Data.Number + " " + Format ( Data.Date, "DLF=D" );
	
EndProcedure

Function RemoveInadmissibleSymbols ( String ) export
	
	s = StrReplace ( String, """", "'" );
	s = StrReplace ( s, "~", "" );
	s = StrReplace ( s, "!", "" );
	s = StrReplace ( s, "@", "" );
	s = StrReplace ( s, "#", "№" );
	s = StrReplace ( s, "$", "" );
	s = StrReplace ( s, "%", " prc." );
	s = StrReplace ( s, "^", "" );
	s = StrReplace ( s, "&", " şi " );
	s = StrReplace ( s, "*", "" );
	s = StrReplace ( s, "|", "" );
	s = StrReplace ( s, "<", "(" );
	s = StrReplace ( s, ">", ")" );
	return s;
	
EndFunction

Function NumberWithoutPrefix ( DocumentNumber, DocumentPrefix ) export
	
	number = TrimAll ( DocumentNumber );
	prefix = "";
	px = Application.Prefix ();
	if ( px <> "" ) then
		prefix = px;
	endif;
	prefix = prefix + DocumentPrefix;
	if ( Find ( number, prefix ) = 1 ) then
		number = Mid ( number, StrLen ( prefix ) + 1 );
	endif;
	while ( Left ( number, 1 ) = "0" ) do 
		number = Mid ( number, 2 );
	enddo;
	return number;
		
EndFunction

#if ( Server ) then

#region Printing

Function Print ( Params, Env ) export
	
	printOk = true;
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getPrintData ( Params, Env );
	if ( addPrintParameters ( Params, Env ) ) then
		putMain ( Params, Env );
	else
		printOk = false;
	endif;
	return printOk;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	Params.TabDoc.PageOrientation = PageOrientation.Portrait;
	Params.TabDoc.FitToPage = true;
	
EndProcedure 

Procedure getPrintData ( Params, Env )
	
	sqlPrintData ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlPrintData ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as DocumentDate, Documents.Number as DocumentNumber, Documents.IncomeTaxRate as IncomeTaxRate, Documents.Amount as Sum, Documents.IncomeTax as IncomeTax,
	|	Documents.Division as Division, Documents.Division.Cutam as Cutam, Documents.Company.Alien as Alien,
	|	Documents.Company.CodeFiscal as CodeFiscal, Documents.Recipient.CodeFiscal as RecipientCodeFiscal, Documents.BankAccount.Bank.Description as BankDescription, 
	|	Documents.RecipientPresentation as RecipientPresentation, Documents.RecipientBankAccount.AccountNumber as RecipientAccountNumber,
	|	Documents.RecipientBankAccount.Bank.Description as RecipientBankDescription, Documents.BankAccount.Bank.Code as BankCode, Documents.Company.Prefix as Prefix,
	|	Documents.RecipientBankAccount.Bank.Code as RecipientBankCode, Documents.BankAccount.AccountNumber as AccountNumber,
	|	Documents.Company.FullDescription as Company, Documents.Urgent as Urgent, Documents.Trezorerial as Trezorerial
	|from Document.PaymentOrder as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Function addPrintParameters ( Params, Env )

	paramsAdded = true;
	Env.Insert ( "object", Params.Reference.GetObject () );
	Env.Insert (  "PrintParams", new Structure () );
	Env.PrintParams.Insert ( "paymentContentStr", Env.object.GetPrintPaymentContent () );
	Env.PrintParams.Insert ( "paymentContentArray", Conversion.StringToArray ( Env.PrintParams.paymentContentStr, Chars.LF ) );
	if ( paymentContentOk ( Env ) ) then
		fillPrintParameters ( Params, Env );
	else
		paramsAdded = false;
	endif;
	return paramsAdded;

EndFunction

Function paymentContentOk ( Env )

	contentOk = true;
	if ( StrLen ( Env.PrintParams.paymentContentStr ) > 210 ) then
		OutputCont.SymbolCountInPaymentContentError ( , "PaymentContent" );
		contentOk = false;
	endif;
	if ( Env.PrintParams.paymentContentArray.Count () > 5 ) then
		OutputCont.RowCountInPaymentContentError ( , "PaymentContent" );
		contentOk = false;
	endif;
	return contentOk;

EndFunction

Procedure fillPrintParameters ( Params, Env )

	printParams = Env.PrintParams;
	fields = Env.Fields;
	fillSumPayment ( printParams, fields );
	fillSumInWords ( printParams );
	fillFiscalCode ( printParams, fields );	
	fillCompany ( printParams, fields, Env );
	fillBankPresentation ( printParams, fields, Env );
	fillRecipient ( printParams, fields, Env );
	fillRecipientBankPresentation ( printParams, fields, Env );
	fillPaymentContent ( printParams );
	printParams.Insert ( "DocumentDate", fields.DocumentDate );
	printParams.Insert ( "DocumentNumber", NumberWithoutPrefix ( Fields.DocumentNumber, Fields.Prefix ) );
	printParams.Insert ( "Sum", printParams.sumPayment );
	printParams.Insert ( "BankCode", fields.BankCode );
	printParams.Insert ( "BankAccount", Left ( fields.AccountNumber, 24 ) );
	//parameters.Insert ( "OrganizationTreasuryCode", 	TrimAll ( OrganizationBankAccount.TreasuryCode )); решаем
	printParams.Insert ( "RecipientCodeFiscal", TrimAll ( fields.RecipientCodeFiscal ) );
	printParams.Insert ( "RecipientBankCode", TrimAll ( fields.RecipientBankCode ) );
	printParams.Insert ( "RecipientBankAccount", Left ( TrimAll ( fields.RecipientAccountNumber ), 24 ) );
	//parameters.Insert ( "ContractorTreasuryCode", TrimAll ( ContractorBankAccount.TreasuryCode )	);
	printParams.Insert ( "TransferType", ? ( fields.Urgent, "U", "N" ) );
	printParams.Insert ( "TransferCode", ? ( fields.Trezorerial, "101", "001" ) );

EndProcedure

Procedure fillSumPayment ( PrintParams, Fields )

	if ( Fields.IncomeTaxRate = 0 ) then
		sumPayment = Fields.Sum;
	else	
		sumPayment = Fields.Sum - Fields.IncomeTax;
	endif;
	PrintParams.Insert ( "sumPayment", sumPayment );

EndProcedure

Procedure fillSumInWords ( PrintParams )

	sumInWordsStr = Conversion.AmountToWords ( PrintParams.sumPayment );
	sumInWordsArray = stringToLines ( sumInWordsStr, " ", 53 );
	PrintParams.Insert ( "SumInWords1", ? ( sumInWordsArray.Count () > 0, sumInWordsArray [ 0 ], "" ) );
	PrintParams.Insert ( "SumInWords2", ? ( sumInWordsArray.Count () > 1, sumInWordsArray [ 1 ], "" ) );

EndProcedure

Function stringToLines ( String, Separator, StringLength )
	
	wordsArray = Conversion.StringToArray ( String, Separator );	
	resultArray = new Array ();	
	resultString = "";
	for i = 0 to wordsArray.Count () - 1 do
		curWord = wordsArray [ i ];
		if ( StrLen ( resultString + curWord ) > StringLength ) then			
			resultArray.Add ( TrimAll ( resultString ) );
			resultString = curWord;
		else
			resultString = resultString + Separator + curWord;			
		endif;
	enddo;
	resultArray.Add ( TrimAll ( resultString ) );
	return resultArray;
	
EndFunction

Procedure fillFiscalCode ( PrintParams, Fields )

	if ( ValueIsFilled ( Fields.Division ) ) then
		fiscalCode = TrimAll ( Fields.CodeFiscal ) + " / " + TrimAll ( Fields.Cutam );
	else	
		fiscalCode = TrimAll ( Fields.CodeFiscal );
	endif;
	PrintParams.Insert ( "CodeFiscal", fiscalCode );

EndProcedure

Procedure fillCompany ( PrintParams, Fields, Env )

	companyStr = TrimAll ( ? ( fields.Alien, "(N) ", "(R) " ) + RemoveInadmissibleSymbols ( fields.Company ) );
	companyArray = Env.object.StringToLines ( companyStr, 35, 50 );
	printParams.Insert ( "Company1", ? ( companyArray.Count () > 0, companyArray [ 0 ], "" ) );
	printParams.Insert ( "Company2", ? ( companyArray.Count () > 1, companyArray [ 1 ], "" ) );
	printParams.Insert ( "Company3", ? ( companyArray.Count () > 2, companyArray [ 2 ], "" ) );
	printParams.Insert ( "Company4", ? ( companyArray.Count () > 3, companyArray [ 3 ], "" ) );

EndProcedure

Procedure fillBankPresentation ( PrintParams, Fields, Env )

	bankStr = TrimAll ( Documents.PaymentOrder.RemoveInadmissibleSymbols ( Fields.BankDescription ) );
	bankArray = Env.object.StringToLines ( bankStr, 60, 70 );
	printParams.Insert ( "BankPresentation1", ? ( bankArray.Count () > 0, bankArray [ 0 ], "" ) );
	printParams.Insert ( "BankPresentation2", ? ( bankArray.Count () > 1, bankArray [ 1 ], "" ) );

EndProcedure

Procedure fillRecipient ( PrintParams, Fields, Env )

	recipientStr = TrimAll ( Documents.PaymentOrder.RemoveInadmissibleSymbols ( Fields.RecipientPresentation ) );
	recipientArray = Env.object.StringToLines ( recipientStr, 35, 50 );
	PrintParams.Insert ( "Recipient1", ? ( recipientArray.Count () > 0, recipientArray [ 0 ], "" ) );
	PrintParams.Insert ( "Recipient2", ? ( recipientArray.Count () > 1, recipientArray [ 1 ], "" ) );
	PrintParams.Insert ( "Recipient3", ? ( recipientArray.Count () > 2, recipientArray [ 2 ], "" ) );
	PrintParams.Insert ( "Recipient4", ? ( recipientArray.Count () > 3, recipientArray [ 3 ], "" ) );

EndProcedure

Procedure fillRecipientBankPresentation ( PrintParams, Fields, Env )
	
	recipientBankStr = TrimAll ( Documents.PaymentOrder.RemoveInadmissibleSymbols ( Fields.RecipientBankDescription ) );
	recipientBankArray = Env.object.StringToLines ( recipientBankStr, 60, 70 );
	PrintParams.Insert ( "RecipientBankPresentation1", ? ( recipientBankArray.Count () > 0, recipientBankArray [ 0 ], "" ) );
	PrintParams.Insert ( "RecipientBankPresentation2", ? ( recipientBankArray.Count () > 1, recipientBankArray [ 1 ], "" ) );

EndProcedure

Procedure fillPaymentContent ( PrintParams )

	paymentContentArray = PrintParams.paymentContentArray;
	PrintParams.Insert ( "PaymentContent1", ? ( paymentContentArray.Count () > 0, paymentContentArray [ 0 ], "" ) );
	PrintParams.Insert ( "PaymentContent2", ? ( paymentContentArray.Count () > 1, paymentContentArray [ 1 ], "" ) );
	PrintParams.Insert ( "PaymentContent3", ? ( paymentContentArray.Count () > 2, paymentContentArray [ 2 ], "" ) );
	PrintParams.Insert ( "PaymentContent4", ? ( paymentContentArray.Count () > 3, paymentContentArray [ 3 ], "" ) );
	PrintParams.Insert ( "PaymentContent5", ? ( paymentContentArray.Count () > 4, paymentContentArray [ 4 ], "" ) );
	
EndProcedure

Procedure putMain ( Params, Env )

	area = Env.T.GetArea ( "Main" );
	area.Parameters.Fill ( Env.PrintParams );
	Params.TabDoc.Put ( area );
	if ( Params.Key = "PaymentOrder2" ) then
		emptyArea = Env.T.GetArea ( "EmptyRow" );	
		Params.TabDoc.Put ( emptyArea );
		Params.TabDoc.Put ( area );
	endif;	

EndProcedure
 
#endregion

#endif
