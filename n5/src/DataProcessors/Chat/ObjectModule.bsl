#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var Session;

Procedure Exec () export
	
	connection = DataProcessors.Chat.PrepareConnection ( Parameters.Assistant, Parameters.Session );
	request = new HTTPRequest ( "/assist/chat", connection.header );
	p = new Structure ( "assistant, text, files, thread, user, password" );
	p.assistant = connection.assistant;
	p.text = Parameters.Message;
	p.files = Parameters.Files;
	p.thread = Parameters.Thread;
	p.user = UserName ();
	p.password = "";
	request.SetBodyFromString ( Conversion.ToJSON ( p ) );
	try
		response = connection.http.Post ( request );
	except
		saveResult ( true, ErrorProcessing.BriefErrorDescription ( ErrorInfo () ) );
		return;
	endtry;
	error = response.StatusCode <> 200;
	if ( not error ) then
		DataProcessors.Chat.SetSession ( response, Session );
	endif;
	saveResult ( error, response.GetBodyAsString () );
		
EndProcedure

Procedure saveResult ( Error, Message )

	result = new Structure ( "Error, Message, Session", Error, Message, Session );
	PutToTempStorage ( Conversion.ToJSON ( result ), Parameters.Result );
	
EndProcedure

#endif