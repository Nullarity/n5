
Function Convert ( Amount, Currency1, Currency2, Date = undefined, Rate1 = undefined, Factor1 = undefined, Rate2 = undefined, Factor2 = undefined, Round = undefined ) export
	
	if ( Amount = 0
		or Currency1 = Currency2
		or Currency2.IsEmpty ()
		or ( Factor2 = 0
			and Rate2 = 0 ) ) then
		return Amount;
	endif; 
	if ( Rate1 = undefined ) then
		info1 = CurrenciesSrv.Get ( Currency1, Date );
	else
		info1 = new Structure ( "Rate, Factor", Rate1, Factor1 );
	endif; 
	if ( Rate2 = undefined ) then
		info2 = CurrenciesSrv.Get ( Currency2, Date );
	else
		info2 = new Structure ( "Rate, Factor", Rate2, Factor2 );
	endif; 
	result = ( Amount * info1.Rate / info1.Factor ) / info2.Rate * info2.Factor;
	return ? ( Round = undefined, result, Round ( result, Round ) );
	
EndFunction 