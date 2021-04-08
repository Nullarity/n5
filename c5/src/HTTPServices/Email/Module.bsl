
Function BodyGet ( Request )
	
	SetPrivilegedMode ( true );
	p = getParams ();
	fetchParams ( p, Request );
	html = getHTML ( p );
	response = new HTTPServiceResponse ( 200 );
	response.SetBodyFromString ( html );
	return response;
	
EndFunction

Function getParams ()
	
	p = new Structure ();
	p.Insert ( "ID" );
	p.Insert ( "Incoming" );
	return p;
	
EndFunction 

Procedure fetchParams ( Params, Request )
	
	p = Conversion.MapToStruct ( Request.QueryOptions );
	FillPropertyValues ( Params, p );
	
EndProcedure 

Function getHTML ( Params )
	
	id = new UUID ( Params.ID );
	document = ? ( Params.Incoming = "1", Documents.IncomingEmail, Documents.OutgoingEmail );
	email = document.GetRef ( id );
	fields = DF.Values ( email, "MessageID, Mailbox" );
	return EmailsSrv.GetHTML ( email, fields.MessageID, fields.Mailbox, , true );

EndFunction 
