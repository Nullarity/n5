
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
	except
		WriteLogEvent ( "OpenAI.FunctionCall",
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
	folder = Application.AssistantPlugin (); 
	processor = ExternalDataProcessors.Create ( folder + "/" + p.function + ".epf", false );
	SetPrivilegedMode ( false );
	processor.Parameters = p;
	return processor.Get ();
	
EndFunction

Function InfoGet ( Request )

	return proceed ( Request );

EndFunction
