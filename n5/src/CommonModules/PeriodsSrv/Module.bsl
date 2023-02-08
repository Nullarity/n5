Function GetCurrentSessionDate () export
	
	return CurrentSessionDate ();
	
EndFunction 

Function CurrentUserDate ( val User ) export
	
	return ToLocalTime ( CurrentUniversalDate (), DF.Pick ( User, "TimeZone" ) );
	
EndFunction