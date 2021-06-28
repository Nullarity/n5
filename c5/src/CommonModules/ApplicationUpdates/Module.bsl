#if ( ThinClient or Server or ThickClientOrdinaryApplication ) then

&AtServer
Procedure Check ( FirstTime ) export
	
	if ( not FirstTime and noneed () ) then
		return;
	endif;
	BeginTransaction ();
	preventReenabling ();
	data = ApplicationUpdates.LastVersion ();
	if ( data = undefined ) then
		RollbackTransaction ();
		return;
	endif;
	currentVersion = CoreLibrary.VersionToNumber ( Metadata.Version );
	Constants.NewUpdates.Set ( currentVersion < data.Release );
	CommitTransaction ();

EndProcedure

&AtServer
Function noneed ()
	
	return Constants.NewUpdates.Get ();
	
EndFunction

&AtServer
Procedure preventReenabling ()
	
	lock = new DataLock ();
	item = lock.Add ( "Constant.NewUpdates" );
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	
EndProcedure

Function LastVersion ( Error = undefined ) export
	
	version = Format ( ApplicationUpdatesSrv.MyRelease (), "NG=" );
	request = new HTTPRequest ( "/ls/hs/Version/Latest?Application=" + Enum.ConstantsApplicationCode () + "&Version=" + version + "&License=" + ApplicationUpdatesSrv.License () );
	connection = new HTTPConnection ( "www.mycont.md" );
	try
		response = Connection.Get ( request );
	except
		Error = ErrorDescription ();
		ApplicationUpdatesSrv.Logging ( Error );
		return undefined;
	endtry;
	if ( not goodResponse ( response ) ) then
		Error = response.GetBodyAsString ();
		ApplicationUpdatesSrv.Logging ( Error );
		return undefined;
	endif;
	result = response.GetBodyAsString ();
	return Conversion.FromJSON ( result );
	
EndFunction

Function goodResponse ( Response )
	
	if ( Response.StatusCode = 200 ) then
		return true;
	endif;
	ApplicationUpdatesSrv.Logging ( Response.GetBodyAsString () );
	return false;
	
EndFunction

&AtClient
Function SubscriptionExpired ( License, Error ) export
	
	connection = new HTTPConnection ( "www.mycont.md" );
	request = new HTTPRequest ( "/ls/hs/License/Expired?License=" + License );
	try
		response = Connection.Get ( request );
	except
		Error = ErrorDescription ();
		ApplicationUpdatesSrv.Logging ( ErrorDescription () );
		return undefined;
	endtry;
	if ( not goodResponse ( response ) ) then
		Error = response.GetBodyAsString ();
		ApplicationUpdatesSrv.Logging ( Error );
		return undefined;
	endif;
	expired = Conversion.StringToNumber ( response.GetBodyAsString () );
	return Date ( 1, 1, 1 ) + expired;

EndFunction

#endif