
Function Get ( val Currency, val Date = undefined ) export
	
	actualDate = ? ( Date = undefined or Date = Date ( 1, 1, 1 ), undefined, Date );
	info = InformationRegisters.ExchangeRates.GetLast ( actualDate, new Structure ( "Currency", Currency ) );
	info.Insert ( "Currency", Currency );
	info.Insert ( "Date", Date );
	if ( info.Rate = 0 ) then
		info.Rate = 1;
	endif; 
	if ( info.Factor = 0 ) then
		info.Factor = 1;
	endif; 
	return info;
	
EndFunction
