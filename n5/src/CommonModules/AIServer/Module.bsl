Function FileDescriptor ( Name, Size, Data ) export

	return new Structure ( "Name, Size, Data", Name, Size, Data );

EndFunction

Function GetThread ( Server ) export
	
	connection = prepareConnection ( Server );
	request = new HTTPRequest ( "/assist/newThread", connection.Header );
	try
		response = connection.Http.Get ( request );
	except
		raise ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
	endtry;
	status = response.StatusCode;
	if ( status = Enum.HTTPStatusOK () ) then
		return response.GetBodyAsString ();
	endif;
	raise Output.ThreadCreationError ( new Structure ( "Code", status ) );
	
EndFunction

Function ChatParams () export
	
	p = new Structure ();
	p.Insert ( "Result" );
	p.Insert ( "Assistant" );
	p.Insert ( "Session" );
	p.Insert ( "Thread" );
	p.Insert ( "Message", "" );
	p.Insert ( "Files" );
	p.Insert ( "Resend", false );
	p.Insert ( "Temperature", 0 );
	return p;
	
EndFunction 

Procedure Chat ( Parameters ) export
	
	assistant = Parameters.Assistant;
	data = DF.Values ( assistant, "Server, Model.Tokens as Tokens" );
	server = data.Server;
	connection = prepareConnection ( server );
	setSession ( connection, Parameters.Session );
	request = new HTTPRequest ( "/assist/chat", connection.Header );
	p = new Structure ( "assistant, text, files, thread, user, password, resend, temperature, tokens" );
	p.assistant = InformationRegisters.Assistants.Get ( new Structure ( "Assistant", assistant ) ).ID;
	p.text = Parameters.Message;   
	p.files = Parameters.Files;
	p.thread = Parameters.Thread;
	p.user = UserName ();
	p.password = userPassword ();
	p.resend = Parameters.Resend;
	p.tokens = data.Tokens;
	p.temperature = Parameters.Temperature;
	request.SetBodyFromString ( Conversion.ToJSON ( p ) );
	caller = Parameters.Result;
	try
		response = connection.Http.Post ( request );
	except
		saveResult ( caller, true, "",
			ErrorProcessing.BriefErrorDescription ( ErrorInfo () ) );
		return;
	endtry;
	error = response.StatusCode <> Enum.HTTPStatusOK ();
	if ( not error ) then
		session = getSession ( response );
	endif;
	saveResult ( caller, error, session, response.GetBodyAsString () );
		
EndProcedure

Function prepareConnection ( Source = undefined )
	
	SetPrivilegedMode ( true );
	return AICache.PrepareConnection ( Source );
	
EndFunction

Procedure setSession ( Connection, Session )

	if ( Session <> "" ) then
		Connection.session = Session;
		Connection.Header [ "Cookie" ] = "session=" + Session;
	endif;

EndProcedure
	
Function getSession ( Response )
	
	cookies = Conversion.StringToMap ( Response.Headers [ "Set-Cookie" ], "=", ";" );
	return cookies [ "session" ];
	
EndFunction

Function userPassword ()
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.Passwords.CreateRecordManager ();
	r.User = SessionParameters.User;
	r.Read ();
	return r.Password;
	
EndFunction

Procedure saveResult ( Caller, Error, Session, Message )

	result = new Structure ( "Error, Message, Session", Error, Conversion.XMLToStandard ( Message ), Session );
	PutToTempStorage ( Conversion.ToJSON ( result ), Caller );
	
EndProcedure

Function DeleteAssistantParams () export
	
	p = new Structure ();
	p.Insert ( "Assistant" );
	return p;
	
EndFunction 

Procedure DeleteAssistant ( Parameters ) export
	
	assistant = getAssistantManager ( Parameters );
	destroyAssistant ( assistant, Parameters );
	assistant.Delete ();
		
EndProcedure

Function getAssistantManager ( Parameters )
	
	assistant = InformationRegisters.Assistants.CreateRecordManager ();
	assistant.Assistant = Parameters.Assistant;
	assistant.Read ();
	return assistant;
	
EndFunction

Procedure destroyAssistant ( Assistant, Parameters )

	id = Assistant.ID;
	if ( id = "" ) then
		return;
	endif;
	server = DF.Pick ( Parameters.Assistant, "Server" );
	connection = prepareConnection ( server );
	request = new HTTPRequest ( "/assist/destroy", connection.Header );
	request.SetBodyFromString ( id );
	response = connection.Http.Post ( request );
	if ( response.StatusCode <> Enum.HTTPStatusOK () ) then
		raise response.GetBodyAsString ();
	endif;
	
EndProcedure

Function DropFilesParams () export
	
	p = new Structure ();
	p.Insert ( "Files" );
	p.Insert ( "Server" );
	p.Insert ( "Session" );
	return p;
	
EndFunction 

Procedure DropFiles ( Parameters ) export
	
	SetPrivilegedMode ( true );
	removeReferences ( Parameters );
	removeFiles ( Parameters );
		
EndProcedure

Procedure removeReferences ( Parameters )
	
	server = Parameters.Server;
	BeginTransaction ();
	for each file in Parameters.Files do
		r = InformationRegisters.AIFiles.CreateRecordManager ();
		r.ID = file.ID;
		r.Login = file.Login;
		r.Server = server;
		r.Delete ();
	enddo;
	CommitTransaction ();
	
EndProcedure

Procedure removeFiles ( Parameters )
	
	connection = undefined;
	keep = filesInUse ( Parameters );
	for each file in Parameters.Files do
		if ( keep.Find ( file.ID ) <> undefined ) then
			continue;
		endif;
		if ( connection = undefined ) then
			connection = prepareConnection ( Parameters.Server );
			setSession ( connection, Parameters.Session );
		endif;
		rewokeFile ( file, Connection );
	enddo;
	
EndProcedure

Function filesInUse ( Parameters )

	q = new Query ( "
	|select distinct Files.ID as ID
	|from InformationRegister.AIFiles as Files
	|where Files.ID in ( &Files )
	|and Files.Server = &Server
	|" );
	q.SetParameter ( "Files", filesID ( Parameters ) );
	q.SetParameter ( "Server", Parameters.Server );
	return q.Execute ().Unload ().UnloadColumn ( "ID" );

EndFunction

Function filesID ( Parameters )
	
	list = new Array ();
	for each file in Parameters.Files do
		list.Add ( file.ID );
	enddo;
	return list;
	
EndFunction

Procedure rewokeFile ( File, Connection )

	request = new HTTPRequest ( "/assist/delete", connection.Header );
	request.SetBodyFromString ( File.ID );
	try
		response = Connection.http.Post ( request );
		if ( response.StatusCode = Enum.HTTPStatusOK () ) then
			setSession ( Connection, getSession ( response ) );
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

Function DeployAssistantParams () export
	
	p = new Structure ();
	p.Insert ( "Assistant" );
	return p;
	
EndFunction 

Procedure DeployAssistant ( Parameters ) export
	
	data = getAssistantData ( Parameters );
	content = prepareAssistantContent ( data );
	code = updateAssistant ( Parameters, content );
	saveAssistantCode ( Parameters, code );
		
EndProcedure

Function getAssistantData ( Parameters )
	
	q = new Query ( "
	|// @Assistant
	|select Assistants.Description as Name, Assistants.Model.Description as Model,
	|	Assistants.FullDescription as Description, Assistants.CodeInterpreter as CodeInterpreter,
	|	Assistants.Retrieval as Retrieval, Assistants.Language as Language,
	|	Assistants.Purpose as Purpose, Assistants.Search as Search, isnull ( Info.ID, """" ) as ID,
	|	Assistants.Provider as Provider, Assistants.Temperature as Temperature,
	|	Assistants.Model.Tokens as Tokens
	|from Catalog.Assistants as Assistants
	|	//
	|	// Assistants
	|	//
	|	left join InformationRegister.Assistants as Info
	|	on Info.Assistant = Assistants.Ref
	|where Assistants.Ref = &Assistant
	|;
	|// #Files
	|select Files.ID as ID
	|from Catalog.Assistants.Files as Files
	|where Files.Ref = &Assistant
	|order by Files.LineNumber
	|;
	|// #Instructions
	|select Instructions.Instruction as Instruction, Instructions.Instruction.FullDescription as Text,
	|	Instructions.System as System
	|from Catalog.Assistants.Instructions as Instructions
	|where Instructions.Ref = &Assistant
	|and not Instructions.Ref.DeletionMark
	|order by Instructions.Ref, Instructions.LineNumber
	|;
	|// #Functions
	|select Functions.Ref as Instruction, Functions.Function as Function,
	|	Functions.Function.Authentication as Authentication, Functions.Function.Endpoint as Endpoint,
	|	Functions.Function.FullDescription as Title, Functions.Function.Name as Name,
	|	Functions.Function.Description as Description
	|from Catalog.Instructions.Functions as Functions
	|where Functions.Ref in ( select Instruction from Catalog.Assistants.Instructions where Ref = &Assistant )
	|and not Functions.Function.DeletionMark
	|order by Instruction, Functions.LineNumber
	|;
	|// #Arguments
	|select Arguments.Ref as Function, Arguments.Description as Description, Arguments.Mandatory as Mandatory,
	|	Arguments.Name as Name, Arguments.Type as Type, Arguments.Default as Default, Arguments.Examples as Examples,
	|	Arguments.Values as Values, Arguments.Constant as Constant, Arguments.Include as Include,
	|	Arguments.AllowEmpty as AllowEmpty
	|from Catalog.Functions.Arguments as Arguments
	|where Arguments.Ref in ( select Function from Catalog.Instructions.Functions where Ref in (
	|	select Instruction from Catalog.Assistants.Instructions where Ref = &Assistant ) )
	|and not Arguments.Ref.DeletionMark
	|order by Function, Arguments.LineNumber
	|"
	);
	q.SetParameter ( "Assistant", Parameters.Assistant );
	return SQL.Exec ( q );
	
EndFunction

Function prepareAssistantContent ( Data )
	
	p = new Structure ();
	p.Insert ( "Assistant", getAssistant ( Data ) );
	p.Insert ( "Instructions", getAssistantInstructions ( Data ) );
	p.Insert ( "Files", getAssistantFiles ( Data ) );
	return p
	
EndFunction

Function getAssistant ( Data )
	
	entry = Data.Assistant;
	entry.Search = Conversion.EnumItemToName ( entry.Search );
	entry.Provider = Conversion.EnumItemToName ( entry.Provider );
	return entry;
	
EndFunction

Function getAssistantInstructions ( Data )
	
	instructions = new Array ();
	for each instruction in Data.Instructions do
		methods = new Array ();
		functions = Data.Functions.FindRows ( new Structure ( "Instruction", instruction.Instruction ) );
		for each call in functions do
			params = new Array ();
			arguments = Data.Arguments.FindRows ( new Structure ( "Function", call.Function ) );
			for each agrument in arguments do
				entry = new Structure ( "Description, Mandatory, Name, Type, Default, Examples, Values, Constant, Include, AllowEmpty" );
				FillPropertyValues ( entry, agrument, , "Type" );
				entry.Type = Conversion.EnumItemToName ( agrument.Type );
				params.Add ( entry );
			enddo;
			entry = new Structure ( "Name, Title, Description, Endpoint, Authentication, Arguments" );
			FillPropertyValues ( entry, call );
			entry.Authentication = Conversion.EnumItemToName ( call.Authentication );
			entry.Arguments = params;
			methods.Add ( entry );
		enddo;
		instructions.Add ( new Structure ( "Text, System, Functions",
			instruction.Text, instruction.System, methods ) );
	enddo;
	return instructions;
	
EndFunction

Function getAssistantFiles ( Data )
	
	return Data.Files.UnloadColumn ( "ID" );
	
EndFunction

Function updateAssistant ( Parameters, Content )

	server = DF.Pick ( Parameters.Assistant, "Server" );
	connection = prepareConnection ( server );
	request = new HTTPRequest ( "/assist/deploy", connection.Header );
	request.SetBodyFromString ( Conversion.ToJSON ( Content ) );
	response = connection.Http.Post ( request );
	result = response.GetBodyAsString ();
	if ( response.StatusCode = Enum.HTTPStatusOK () ) then
		return result;
	endif;
	raise result;
	
EndFunction

Procedure saveAssistantCode ( Parameters, Code )

	r = InformationRegisters.Assistants.CreateRecordManager ();
	r.Assistant = Parameters.Assistant;
	r.ID = Code;
	r.Synced = true;
	r.Write ();
	
EndProcedure

Function UploadFilesParams () export
	
	p = new Structure ();
	p.Insert ( "Result" );
	p.Insert ( "Files" );
	p.Insert ( "Server" );
	p.Insert ( "Session" );
	return p;
	
EndFunction 

Procedure UploadFiles ( Parameters ) export
	
	connection = prepareConnection ( Parameters.Server );
	setSession ( connection, Parameters.Session );
	files = uploadToServer ( Parameters, connection );
	saveUploadResult ( Parameters, connection, files );
		
EndProcedure

Function prepareUploadingSearch ( Parameters )

	search = new Query ( "
	|select top 1 Files.ID as ID, Files.Login = &Me as Exists
	|from InformationRegister.AIFiles as Files
	|where Files.Hash = &Hash
	|and Files.Server = &Server
	|order by Exists desc
	|" );
	search.SetParameter ( "Me", SessionParameters.Login );
	search.SetParameter ( "Server", Parameters.Server );
	return search;

EndFunction

Function uploadToServer ( Parameters, Connection )
	
	search = prepareUploadingSearch ( Parameters );
	folder = GetTempFileName ();
	directory = folder + GetPathSeparator ();
	CreateDirectory ( folder );
	files = new Array ();
	for each file in Parameters.Files do
		data = file.Data;
		hash = AttachmentsSrv.GetChecksum ( data );
		info = uploadingFileInfo ( search, hash );
		error = "";
		id = info.ID;
		if ( id = undefined ) then
			id = sendFile ( Connection, directory + file.Name, data, error );
			add = true;
		else
			id = info.ID;
			add = not info.Exists;
		endif;
		if ( add
			and id <> undefined ) then
			registerUploadedFile ( Parameters, file, hash, id );
		endif;
		files.Add ( new Structure ( "File, ID, Error", file, id, error ) );
	enddo;
	DeleteFiles ( folder );
	return files;
	
EndFunction

Function uploadingFileInfo ( Search, Hash )
	
	Search.SetParameter ( "Hash", Hash );
	SetPrivilegedMode ( true );
	table = Search.Execute ().Unload ();
	return Conversion.RowToStructure ( table );
	
EndFunction

Function sendFile ( Connection, File, Data, Error )

	Data.Write ( File );
	request = new HTTPRequest ( "/assist/upload", Connection.Header );
	request.SetBodyFromString ( File );
	try
		response = Connection.http.Post ( request );
		answer = response.GetBodyAsString ();
		if ( response.StatusCode = Enum.HTTPStatusOK () ) then
			setSession ( Connection, getSession ( request ) );
			return ReadJSONValue ( answer ).id;
		endif;
	except
		Error = ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
		return undefined;
	endtry;
	try
		info = ReadJSONValue ( answer );
		Error = info.error.message;
	except
		Error = answer;
	endtry;

EndFunction

Procedure registerUploadedFile ( Parameters, File, Hash, ID )
	
	r = InformationRegisters.AIFiles.CreateRecordManager ();
	r.Hash = Hash;
	r.ID = ID;
	r.Created = CurrentSessionDate ();
	r.Login = SessionParameters.Login;
	r.Server = Parameters.Server;
	r.Extension = FileSystem.GetExtensionIndex ( File.Name );
	size = File.Size;
	r.Size = size;
	r.FileSize = Conversion.BytesToSize ( size );
	r.Name = File.Name;
	r.Write ();

EndProcedure

Procedure saveUploadResult ( Parameters, Connection, Files )
	
	result = new Structure ( "Files, Session", Files, Connection.session );
	PutToTempStorage ( result, Parameters.Result );
	
EndProcedure

Function StopRunning ( val Server, val Thread, val Session ) export

	connection = prepareConnection ( Server );
	setSession ( connection, Session );
	request = new HTTPRequest ( "/assist/stopRunning", connection.Header );
	p = new Structure ( "thread", Thread );
	request.SetBodyFromString ( Conversion.ToJSON ( p ) );
	try
		connection.Http.Post ( request );
		return true;
	except
		return false;
	endtry;
	
EndFunction

Function DownloadParams () export
	
	p = new Structure ();
	p.Insert ( "Result" );
	p.Insert ( "File" );
	p.Insert ( "Server" );
	p.Insert ( "Session" );
	return p;
	
EndFunction 

Function Download ( Parameters ) export
	
	data = fetchFile ( Parameters );
	content = Base64Value ( data.Content );
	return new Structure ( "File, Address", data.File, PutToTempStorage ( content ) );
	
EndFunction

Function fetchFile ( Parameters )
	
	connection = prepareConnection ( Parameters.Server );
	setSession ( connection, Parameters.Session );
	request = new HTTPRequest ( "/assist/download", connection.Header );
	request.SetBodyFromString ( Parameters.File );
	try
		response = connection.Http.Post ( request );
		answer = response.GetBodyAsString ();
		status = response.StatusCode;
		if ( status = Enum.HTTPStatusOK () ) then
			setSession ( Connection, getSession ( request ) );
			return ReadJSONValue ( answer );
		else
			raise Output.ServerReturnedError ( new Structure ( "Code", status ) );
		endif;
	except
		raise ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
	endtry;
	
EndFunction

Function Post ( Connection, Request ) export
	
	try
		response = Connection.Http.Post ( Request );
		answer = response.GetBodyAsString ();
		status = response.StatusCode;
		if ( status = Enum.HTTPStatusOK () ) then
			try
				return Conversion.FromJSON ( answer );
			except
				return answer;
			endtry;
		else
			raise Output.ServerReturnedError ( new Structure ( "Code", status ) );
		endif;
	except
		raise ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
	endtry;

EndFunction

Function Ask ( Params, ReturnJSON = true ) export
	
	connection = prepareConnection ();
	request = new HTTPRequest ( "/assist/ask", connection.header );
	provider = provider ( Params.Model );
	p = new Structure (
		"provider, returnJSON, model, temperature, tokens, user, system",
		Conversion.EnumItemToName ( provider ), ReturnJSON );
	FillPropertyValues ( p, Params );
	request.SetBodyFromString ( Conversion.ToJSON ( p ) );
	try
		result = AIServer.Post ( connection, request );
		if ( provider = Enums.AIProviders.Anthropic ) then
			content = result.content [ 0 ].text;
		else
			content = result.choices [ 0 ].message.content;
		endif;
		return ? ( ReturnJSON, ReadJSONValue ( content ), content );
	except
		WriteLogEvent ( "AIServer.Ask",
			EventLogLevel.Error, , ,
			ErrorProcessing.DetailErrorDescription ( ErrorInfo () )
		);
	endtry;
	
EndFunction

Function provider ( Model )
	
	if ( StrStartsWith ( Model, "claude" ) ) then
		return Enums.AIProviders.Anthropic;
	else
		return Enums.AIProviders.OpenAI;
	endif;
	
EndFunction

Function QuestionParams ( User, System = "", Tokens = 400 ) export
	
	p = new Structure ();
	p.Insert ( "Model", "claude-3-5-sonnet-latest" );
	p.Insert ( "Temperature", 0 );
	p.Insert ( "Tokens", Tokens );
	p.Insert ( "System", System );
	p.Insert ( "User", User );
	return p;
	
EndFunction

Procedure CreateTable ( Name, WithTenant ) export

	connection = prepareConnection ();
	request = new HTTPRequest ( "/assist/table/create", connection.header );
	params = new Structure ( "name, size, withTenant",
		Name, 1536, WithTenant );
	request.SetBodyFromString ( Conversion.ToJSON ( params ) );
	AIServer.Post ( connection, request );

EndProcedure

Procedure DropTable ( Name ) export

	connection = prepareConnection ();
	request = new HTTPRequest ( "/assist/table/drop", connection.header );
	params = new Structure ( "name", name );
	request.SetBodyFromString ( Conversion.ToJSON ( params ) );
	AIServer.Post ( connection, request );

EndProcedure

Function GetVectors ( Text, TextRu = "", Table = "", Cache = false ) export
	
	connection = prepareConnection ();
	request = new HTTPRequest ( "/assist/embedding/get", connection.header );
	params = new Structure ( "text, textRu, table, cache",
		Text, TextRu, Table, cache );
	request.SetBodyFromString ( Conversion.ToJSON ( params ) );
	return AIServer.Post ( connection, request );
	
EndFunction

Function GetCachedVector ( Text ) export
	
	connection = prepareConnection ();
	request = new HTTPRequest ( "/assist/embedding/getCached", connection.header );
	request.SetBodyFromString ( Text );
	return AIServer.Post ( connection, request );
	
EndFunction

Function FindRows ( Table, Vector, Column, Limit = 10 ) export
	
	connection = prepareConnection ();
	request = new HTTPRequest ( "/assist/table/find", connection.header );
	params = new Structure ( "tenant, table, name, value, limit",
		AICache.TenantID (), Table, Column, Vector, Limit );
	request.SetBodyFromString ( Conversion.ToJSON ( params ) );
	return AIServer.Post ( connection, request ).data;
	
EndFunction

Procedure AddToSearch ( Table, ID, Embeddings ) export

	connection = prepareConnection ();
	request = new HTTPRequest ( "/assist/table/add", connection.header );
	params = new Structure ( "table, rows", Table, new Array () );
	params.rows.Add ( new Structure ( "tenant, id, vector, vectorRu",
		AICache.TenantID (), ID, Embeddings.vector, Embeddings.vectorRu ) );
	request.SetBodyFromString ( Conversion.ToJSON ( params ) );
	AIServer.Post ( connection, request );

EndProcedure
