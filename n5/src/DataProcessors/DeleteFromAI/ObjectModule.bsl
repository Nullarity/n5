#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var Session;
var Request;
var Connection;
var Search;
var Me;

Procedure Exec () export
	
	init ();
	removeFiles ();
		
EndProcedure

Procedure init ()
	
	Connection = DataProcessors.Chat.PrepareConnection ( Parameters.Assistant, Parameters.Session );
	Request = new HTTPRequest ( "/assist/delete", Connection.header );
	Me = SessionParameters.User;
	initSearch ();
	
EndProcedure

Procedure initSearch ()

	Search = new Query ( "
	|select Files.Creator as Creator
	|from InformationRegister.AIFiles as Files
	|where Files.ID = &ID
	|" );

EndProcedure

Procedure removeFiles ()
	
	for each file in Parameters.Files do
		BeginTransaction ();
		lockFile ( file );
		references = findReferences ( file );
		last = true;
		for each reference in references do
			if ( reference.Creator = me ) then
				removeReference ( file );
			else
				last = false;
			endif;
		enddo;
		if ( last ) then
			rewoke ( file );
		endif;
		CommitTransaction ();
	enddo;
	
EndProcedure

Procedure lockFile ( File )
	
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.AIFiles" );
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "ID", File.ID );
	lock.Lock ();
	
EndProcedure

Function findReferences ( File )
	
	Search.SetParameter ( "ID", File.ID );
	return Search.Execute ().Unload ();
	
EndFunction

Procedure removeReference ( File )
	
	r = InformationRegisters.AIFiles.CreateRecordManager ();
	r.ID = File.ID;
	r.Creator = Me;
	r.Delete ();

EndProcedure

Procedure rewoke ( File )

	if ( Session <> "" ) then
		Connection.Header [ "Cookie" ] = "session=" + Session;
	endif;
	Request.SetBodyFromString ( File.ID );
	try
		response = Connection.http.Post ( Request );
		if ( response.StatusCode = 200 ) then
			DataProcessors.Chat.SetSession ( response, Session );
			return;
		endif;
		answer = response.GetBodyAsString ();
		try
			info = ReadJSONValue ( answer );
			error = info.error.message;
		except
			error = answer;
		endtry;
	except
		error = ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
	endtry;
	raise Output.AIFileDeletionError ( new Structure ( "File, Error", File.Name, error ) );

EndProcedure

#endif