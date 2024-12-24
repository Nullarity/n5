
Function InfoPost ( Request )
	
	return proceed ( Request );

EndFunction

Function proceed ( Request )
	
	parameters = Request.GetBodyAsString ();
	try
		response = new HTTPServiceResponse ( 200 );
		response.Headers.Insert ( "content-type", "text/html" );
		result = get ( parameters );
		response.SetBodyFromString ( result );
			WriteLogEvent ( "Assist.FunctionCall",
				EventLogLevel.Information, , ,
				"Request: " + parameters
				+ Chars.LF +"Response: "
				+ result
			);
	except
		WriteLogEvent ( "Assist.FunctionCall",
			EventLogLevel.Error, , ,
			ErrorProcessing.DetailErrorDescription ( ErrorInfo () )
			+ ", request: "
			+ parameters
		);
		response = new HTTPServiceResponse ( 500 );
		response.SetBodyFromString ( Output.ProcessingError () );
	endtry;
	return response;
	
EndFunction

Function get ( Parameters )
	
	p = Conversion.FromJSON ( Parameters );
	SetPrivilegedMode ( true );
	slash = GetPathSeparator ();
	folder = Application.AssistantPlugin () + slash;
	file = p.function + ".epf";
	path = folder + Metadata.Name + slash + file;
	if ( not FileSystem.Exists ( path ) ) then
		path = folder + file;
	endif;
	processor = ExternalDataProcessors.Create ( path, false );
	SetPrivilegedMode ( false );
	processor.Parameters = p;
	result = processor.Get ();
	try
		success = Boolean ( processor.Success );
	except
		success = true;
	endtry;
	return Conversion.ToJSON ( new Structure ( "content, success", result, success ) );
	
EndFunction

Function InfoGet ( Request )

	return proceed ( Request );

EndFunction
