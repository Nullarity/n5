#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function GetParams () export
	
	p = new Structure ();
	p.Insert ( "Result" );
	p.Insert ( "Assistant" );
	p.Insert ( "Session" );
	p.Insert ( "Thread" );
	p.Insert ( "Message" );
	p.Insert ( "Files" );
	return p;
	
EndFunction 

Procedure Exec ( Params, JobKey ) export
	
	obj = Create ();
	obj.Parameters = Params;
	obj.JobKey = JobKey;
	obj.Exec ();
	
EndProcedure 

Function PrepareConnection ( Assistant, Session ) export
	
	data = DF.Values ( Assistant, "Description, Server, Port, Token" );
	connection = new HTTPConnection ( data.Server, data.Port );
	header = new Map ();
	header [ "Authorization" ] = "Bearer " + data.Token;
	header [ "Content-Type" ] = "application/json";
	if ( Session <> "" ) then
		header [ "Cookie" ] = "session=" + Session;
	endif;
	return new Structure ( "http, header, assistant",
		connection, header, data.Description );

EndFunction

Procedure SetSession ( Response, Session ) export
	
	cookies = Conversion.StringToMap ( Response.Headers [ "Set-Cookie" ], "=", ";" );
	Session = cookies [ "session" ];
	
EndProcedure

#endif