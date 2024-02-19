
Function InfoPost ( Request )
	
	return proceed ( Request );
	
EndFunction

Function proceed ( Request )
	
	p = Conversion.FromJSON ( Request.GetBodyAsString () );
	SetPrivilegedMode ( true );
	folder = Application.AssistantPlugin (); 
	obj = ExternalDataProcessors.Create ( folder + "/" + p.function + ".epf", false );
	SetPrivilegedMode ( false );
	response = new HTTPServiceResponse ( 200 );
	response.Headers.Insert ( "content-type", "text/html" );
	obj.Parameters = p;
	response.SetBodyFromString ( obj.Get () );
	return response;
	
EndFunction

Function InfoGet ( Request )

	return proceed ( Request );

EndFunction
