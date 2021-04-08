#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function GetDate ( Date, Variant ) export
	
	if ( Variant = Enums.Reminder._5m ) then
		seconds = 300;
	elsif ( Variant = Enums.Reminder._15m ) then
		seconds = 900;
	elsif ( Variant = Enums.Reminder._30m ) then
		seconds = 1800;
	elsif ( Variant = Enums.Reminder._1h ) then
		seconds = 3600;
	elsif ( Variant = Enums.Reminder._1d ) then
		seconds = 86400;
	elsif ( Variant = Enums.Reminder._1w ) then
		seconds = 604800;
	endif; 
	return Date - seconds;
	
EndFunction

#endif