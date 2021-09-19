
Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( ToCompany ) then
		contractIndex = CheckedAttributes.Find ( "Contract" );
		if ( contractIndex <> Undefined ) then
			CheckedAttributes.Delete ( contractIndex );
		endif;
	endif;
	
EndProcedure

Function StringToLines ( Str, FirstRow, OverRows ) export
	
	separator = " ";
	wordsArray = Conversion.StringToArray ( Str, separator );	
	resultArray = new Array ();	
	resultString = "";
	for i = 0 to wordsArray.Count () - 1 do
		curWord = wordsArray [ i ];
		strLen = ? ( resultArray.Count () = 0, FirstRow, OverRows );
		if ( StrLen ( resultString + curWord ) > strLen ) then			
			resultArray.Add ( TrimAll ( resultString ) );
			resultString = curWord;
		else
			resultString = resultString + separator + curWord;			
		endif;
	enddo;
	resultArray.Add ( TrimAll ( resultString ) );
	return ( resultArray );
	
EndFunction

Function GetPrintPaymentContent () export
	
	taxStr = getTaxString ();
	paymentContentArray = Conversion.StringToArray ( PaymentContent, Chars.LF );
	deleteEmptyRows ( paymentContentArray );
	finalyArray = getFinalyArray ( paymentContentArray );
	includeTaxStr ( finalyArray, taxStr );
	return Documents.PaymentOrder.RemoveInadmissibleSymbols ( getStringFromArray ( finalyArray, Chars.LF ) );
	
EndFunction

Function getTaxString ()

	taxStr = "";
	vATRateFilled = ( VATRate <> 0 );
	incomTaxRateFilled = ( IncomeTaxRate <> 0 );
	if ( not ( ExcludeTaxes or Salary ) ) then
		if ( vATRateFilled and incomTaxRateFilled ) then		
			taxStr = "Impozit " + String ( IncomeTaxRate ) + " prc. " + Format ( IncomeTax, "ND='15';NFD='2';NDS='-';NG=0" ) + " lei, inclusiv TVA " + Format ( VATRate, "NZ=" ) + " prc. " + Format ( VAT, "ND='15'; NFD='2';NDS='-';NG=0" ) + " lei.";
		elsif ( vATRateFilled ) and ( not incomTaxRateFilled ) then
			taxStr = "Inclusiv TVA " + Format ( VATRate, "NZ=" ) + " prc. " + Format ( VAT, "ND='15';NFD='2';NDS='-';NG=0" ) + " lei.";
		elsif ( not vATRateFilled ) and ( incomTaxRateFilled ) then
			taxStr = "Impozit " + String ( IncomeTaxRate ) + " prc. " + Format ( IncomeTax, "ND='15';NFD='2';NDS='-';NG=0" ) + " lei.";
		endif;	
	endif;
	return taxStr;

EndFunction

Procedure deleteEmptyRows ( Array )

	i = 0;
	while ( i < Array.Count () ) do
		if ( IsBlankString ( Array [ i ] ) ) then
			Array.Delete ( i );
		else
			i = i + 1;
		endif;
	enddo;

EndProcedure

Function getFinalyArray ( PaymentContentArray )

	strArray = new Array ();
	for each rowArray in PaymentContentArray do
		for each rowResult in StringToLines ( rowArray, 45, 64 ) do
			strArray.Add ( rowResult );
		enddo;	
	enddo;
	return strArray;

EndFunction

Procedure includeTaxStr ( FinalyArray, TaxStr )

	firstRow = ? ( FinalyArray.Count () = 0, 45, 64 );
	if ( not IsBlankString ( TaxStr ) ) then
		if ( StrLen ( TaxStr ) > firstRow ) then			
			for each strRow in StringToLines ( TaxStr, firstRow, 64 ) do
				FinalyArray.Add ( strRow );	
			enddo;			
		else
			FinalyArray.Add ( TaxStr );
		endif;
	endif;

EndProcedure

Function getStringFromArray ( ItemsArray, Separator )
	
	resultStr = "";
	for each item in ItemsArray do
		resultStr = resultStr + "" + item + Separator;
	enddo; 
	resultStr = Left ( resultStr, StrLen ( resultStr ) - StrLen ( Separator ) );
	return resultStr;
	
EndFunction


