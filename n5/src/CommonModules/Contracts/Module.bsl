Function Get ( val Query, val Params ) export
	
	result = new Structure ();
	attributes = new Array ();
	fields = Conversion.StringToArray ( Query );
	for each field in fields do
		if ( field = "TaxGroup" ) then
			attributes.Add ( field );
		elsif ( field = "CustomerPrices"
			or field = "VendorPrices" ) then
			attributes.Add ( field + " as Prices" );
		elsif ( field = "Currency" ) then
			setCurrency ( result, Params );
		endif; 
	enddo; 
	if ( attributes.Count () > 0 ) then
		setAttributes ( result, Params, attributes );
	endif; 
	return result;
	
EndFunction 

Procedure setCurrency ( Result, Params )
	
	currency = DF.Pick ( Params.Contract, "Currency" );
	data = CurrenciesSrv.Get ( currency, Params.Date );
	Result.Insert ( "Currency", currency );
	Result.Insert ( "Rate", data.Rate );
	Result.Insert ( "Acceleration", data.Factor );
	
EndProcedure 

Procedure setAttributes ( Result, Params, Attributes )
	
	s = StrConcat ( Attributes, "," );
	data = DF.Values ( Params.Contract, s );
	for each item in data do
		Result.Insert ( item.Key, item.Value );
	enddo; 
	
EndProcedure 