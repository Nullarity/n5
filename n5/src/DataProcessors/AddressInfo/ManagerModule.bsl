#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Get ( String, Alien = false ) export
	
	obj = Create ();
	obj.String = String;
	obj.Alien = Alien;
	return obj.Get ();
	
EndFunction

#endif