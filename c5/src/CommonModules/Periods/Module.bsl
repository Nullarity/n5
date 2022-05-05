Function GetBalanceDate ( Object ) export
	
	if ( Object.Date = Date ( 1, 1, 1 ) ) then
		return undefined;
	elsif ( Object.Ref.IsEmpty () ) then
		#if ( Client ) then
			date = CurrentDate ();
		#else
			date = CurrentSessionDate ();
		#endif
		if ( BegOfDay ( Object.Date ) = BegOfDay ( date ) ) then
			return undefined;
		else
			return Object.Date;
		endif; 
	else
		return Object.Date;
	endif; 
	
EndFunction

Function GetDocumentDate ( Object ) export
	
	if ( Object.Date = Date ( 1, 1, 1 ) ) then
		return PeriodsSrv.GetCurrentSessionDate ();
	elsif ( Object.Ref.IsEmpty () ) then
		date = PeriodsSrv.GetCurrentSessionDate ();
		if ( BegOfDay ( Object.Date ) = BegOfDay ( date ) ) then
			return date;
		else
			return Object.Date;
		endif; 
	else
		return Object.Date;
	endif; 
	
EndFunction

&AtServer
Function GetOperationalDate ( Date ) export
	
	today = CurrentSessionDate ();
	if ( BegOfDay ( today ) = BegOfDay ( Date ) ) then
		return undefined;
	else
		return Date;
	endif; 

EndFunction

&AtServer
Function Ok ( DateStart, DateEnd ) export
	
	if ( DateStart = Date ( 1, 1, 1 ) ) or ( DateEnd = Date ( 1, 1, 1 ) ) then
		return true;
	endif; 
	if ( DateStart <= DateEnd ) then
		return true;
	endif; 
	return false;
	
EndFunction

// Used in DC templates
&AtServer
Function DateDiff ( DateStart, DateEnd ) export
	
	different = DateEnd - DateStart;
	if ( different = 0 ) then
		return "";
	endif; 
	days = Int ( different / 86400 );
	hours = Int ( ( different - days * 86400 ) / 3600 );
	if ( days = 0 ) then
		return "" + hours + Output.ShortHour ();
	else
		return "" + days + Output.ShortDay () + " " + hours + Output.ShortHour ();
	endif; 
	
EndFunction 