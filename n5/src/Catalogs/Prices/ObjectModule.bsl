#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	addToCheckPercentFields ( CheckedAttributes );
	
EndProcedure

Procedure addToCheckPercentFields ( CheckedAttributes )
	
	if ( Pricing <> Enums.Pricing.Base
		and Pricing <> Enums.Pricing.Cost
		and Pricing <> Enums.Pricing.Purchase ) then
		CheckedAttributes.Add ( "BasePrices" );
		CheckedAttributes.Add ( "RoundMethod" );
	endif; 
	if ( Pricing = Enums.Pricing.Percent ) then
		CheckedAttributes.Add ( "Percent" );
	endif; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( existRecursion () ) then
		Cancel = true;
	endif; 
	if ( calculationMethodChangeError () ) then
		Cancel = true;
	endif; 
	if ( detailChangeError () ) then
		Cancel = true;
	endif; 
	
EndProcedure

Function existRecursion ()
	
	currentBasePrice = BasePrices;
	while ( true ) do
		if ( currentBasePrice.IsEmpty () ) then
			return false;
		endif; 
		if ( currentBasePrice <> Ref ) then
			currentBasePrice = DF.Pick ( currentBasePrice, "BasePrices" );
		endif; 
		if ( not currentBasePrice.IsEmpty () )
			and ( currentBasePrice = BasePrices or currentBasePrice = Ref ) then
			Output.ExistPriceRecursion ( , "BasePrices" );
			return true;
		endif; 
	enddo; 
	
EndFunction 

Function calculationMethodChangeError ()
	
	if ( IsNew () ) then
		return false;
	endif; 
	if ( Ref.Pricing = Pricing ) then
		return false;
	endif;
	error = existRecordsWithThisPrices ();
	if ( error ) then
		Output.PriceCalculationMethodChangeError ( , "Pricing" );
	endif; 
	return error;
	
EndFunction 

Function existRecordsWithThisPrices ()
	
	s = "
	|select top 1 null
	|from InformationRegister.";
	if ( Ref.Pricing = Enums.Pricing.Group ) then
		s = s + "PriceGroups";
	else
		s = s + "Prices";
	endif; 
	s = s + " as Pricing
	|where Pricing.Prices = &Prices
	|";
	q = new Query ( s );
	q.SetParameter ( "Prices", Ref );
	return q.Execute ().Select ().Next ();
	
EndFunction 

Function detailChangeError ()
	
	if ( IsNew () ) then
		return false;
	endif; 
	if ( Ref.Detail = Detail ) or ( detailCanChange () ) then
		return false;
	endif;
	error = existRecordsWithThisPrices ();
	if ( error ) then
		Output.PriceDetailChangeError ( , "Detail" );
	endif; 
	return error;
	
EndFunction 

Function detailCanChange ()
	
	return Ref.Detail = Enums.PriceDetails.Item;

EndFunction 

#endif