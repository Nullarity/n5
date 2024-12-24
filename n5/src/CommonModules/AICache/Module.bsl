
Function PrepareConnection ( Server = undefined ) export
	
	stopIfNotPrivileged ();
	data = connectionData ( Server );
	connection = new HTTPConnection ( hostname ( data.Server ), data.Port );
	header = new Map ();
	header [ "Authorization" ] = "Bearer " + data.Token;
	header [ "Content-Type" ] = "application/json";
	return new Structure ( "Http, Header, Session", connection, header, "" );

EndFunction

Procedure stopIfNotPrivileged ()
		
		stop = SessionParameters.SystemCall;
		
EndProcedure

Function connectionData ( Server = undefined )

	q = new Query ();
	s = "
	|select Access.Ref.Address as Server, Access.Ref.Port as Port, Access.Token as Token
	|from Catalog.Servers.Access as Access
	|";
	if ( Server = undefined ) then
		s = s + "where Access.Ref in ( select AIServer from Constants )";
	else
		s = s + "
		|where Access.Tenant = &Tenant
		|and Access.Ref = &Ref
		|";
		q.SetParameter ( "Ref", Server );
		q.SetParameter ( "Tenant", SessionParameters.Tenant );
	endif;
	q.Text = s;
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );

EndFunction

Function hostname ( Address )
	
	splitter = "://";
	i = StrFind ( Address, splitter );
	if ( i = 0 ) then
		return Address;
	else
		return Mid ( Address, i + StrLen ( splitter ) );
	endif;
	
EndFunction

Function TenantID () export
	
	return DF.Pick ( SessionParameters.Tenant, "ID" );
	
EndFunction
