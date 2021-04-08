Function MobileClient () export
	
	return isClient ( "MobileClient" );
	
EndFunction

Function isClient ( Type )
	
	return GetFunctionalOption ( Type, new Structure ( "Session", SessionParameters.Session ) );
	
EndFunction

Function WebClient () export
	
	return isClient ( "WebClient" );
	
EndFunction
