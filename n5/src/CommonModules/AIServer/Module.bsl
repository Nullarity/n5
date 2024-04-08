Function FileDescriptor ( Name, Size, Data ) export

	return new Structure ( "Name, Size, Data", Name, Size, Data );

EndFunction

Function GetThread ( Server ) export
	
	connection = prepareConnection ( Server );
	request = new HTTPRequest ( "/assist/newThread", connection.header );
	try
		response = connection.http.Get ( request );
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
	return p;
	
EndFunction 

Procedure Chat ( Parameters ) export
	
	assistant = Parameters.Assistant;
	server = DF.Pick ( assistant, "Server" );
	connection = prepareConnection ( server );
	setSession ( connection, Parameters.Session );
	request = new HTTPRequest ( "/assist/chat", connection.header );
	p = new Structure ( "assistant, text, files, thread, user, password, resend" );
	p.assistant = InformationRegisters.Assistants.Get ( new Structure ( "Assistant", assistant ) ).ID;
	p.text = Parameters.Message;   
	p.files = Parameters.Files;
	p.thread = Parameters.Thread;
	p.user = UserName ();
	p.password = userPassword ();
	p.resend = Parameters.Resend;
	request.SetBodyFromString ( Conversion.ToJSON ( p ) );
	caller = Parameters.Result;
	try
		response = connection.http.Post ( request );
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

Function prepareConnection ( Server )
	
	data = connectionData ( Server );
	connection = new HTTPConnection ( hostname ( data.Server ), data.Port );
	header = new Map ();
	header [ "Authorization" ] = "Bearer " + data.Token;
	header [ "Content-Type" ] = "application/json";
	return new Structure ( "http, header, session", connection, header, "" );

EndFunction

Procedure setSession ( Connection, Session )

	if ( Session <> "" ) then
		Connection.session = Session;
		Connection.header [ "Cookie" ] = "session=" + Session;
	endif;

EndProcedure
	
Function connectionData ( Server )

	q = new Query ( "
	|select Access.Ref.Address as Server, Access.Ref.Port, Access.Token as Token
	|from Catalog.Servers.Access as Access
	|where Access.Tenant = &Tenant
	|and Access.Ref = &Ref
	|" );
	q.SetParameter ( "Ref", Server );
	q.SetParameter ( "Tenant", SessionParameters.Tenant );
	return Conversion.RowToStructure ( q.Execute ().Unload () );

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
	request = new HTTPRequest ( "/assist/destroy", connection.header );
	request.SetBodyFromString ( id );
	response = connection.http.Post ( request );
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
	
	connection = prepareConnection ( Parameters.Server );
	setSession ( connection, Parameters.Session );
	search = prepareDeletionSearch ( Parameters );
	removeFiles ( Parameters, search, connection );
		
EndProcedure

Function prepareDeletionSearch ( Parameters )

	search = new Query ( "
	|select Files.Login as Login
	|from InformationRegister.AIFiles as Files
	|where Files.ID = &ID
	|and Files.Server = &Server
	|" );
	search.SetParameter ( "Server", Parameters.Server );
	return search;

EndFunction

Procedure removeFiles ( Parameters, Search, Connection )
	
	server = Parameters.Server;
	me = SessionParameters.Login;
	for each file in Parameters.Files do
		BeginTransaction ();
		lockFile ( file );
		references = findFileReferences ( file, Search );
		last = true;
		for each reference in references do
			if ( reference.Login = me ) then
				removeFileReference ( file, server );
			else
				last = false;
			endif;
		enddo;
		if ( last ) then
			rewokeFile ( file, Connection );
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

Function findFileReferences ( File, Search )
	
	Search.SetParameter ( "ID", File.ID );
	return Search.Execute ().Unload ();
	
EndFunction

Procedure removeFileReference ( File, Server )
	
	r = InformationRegisters.AIFiles.CreateRecordManager ();
	r.ID = File.ID;
	r.Login = SessionParameters.Login;
	r.Server = Server;
	r.Delete ();

EndProcedure

Procedure rewokeFile ( File, Connection )

	request = new HTTPRequest ( "/assist/delete", connection.header );
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
	|	Assistants.Purpose as Purpose, Assistants.Search as Search, isnull ( Info.ID, """" ) as ID
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
	|select Instructions.Instruction as Instruction, Instructions.Instruction.FullDescription as Text
	|from Catalog.Assistants.Instructions as Instructions
	|where Instructions.Ref = &Assistant
	|order by Instructions.Ref, Instructions.LineNumber
	|;
	|// #Functions
	|select Functions.Ref as Instruction, Functions.Function as Function,
	|	Functions.Function.Authentication as Authentication, Functions.Function.Endpoint as Endpoint,
	|	Functions.Function.FullDescription as Title, Functions.Function.Name as Name,
	|	Functions.Function.Description as Description, Functions.Internal as Internal
	|from Catalog.Instructions.Functions as Functions
	|where Functions.Ref in ( select Instruction from Catalog.Assistants.Instructions where Ref = &Assistant )
	|order by Instruction, Functions.LineNumber
	|;
	|// #Arguments
	|select Arguments.Ref as Function, Arguments.Description as Description, Arguments.Mandatory as Mandatory,
	|	Arguments.Name as Name, Arguments.Type as Type, Arguments.Default as Default, Arguments.Examples as Examples,
	|	Arguments.Values as Values, Arguments.Constant as Constant
	|from Catalog.Functions.Arguments as Arguments
	|where Arguments.Ref in ( select Function from Catalog.Instructions.Functions where Ref in (
	|	select Instruction from Catalog.Assistants.Instructions where Ref = &Assistant ) )
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
				entry = new Structure ( "Description, Mandatory, Name, Type, Default, Examples, Values, Constant" );
				FillPropertyValues ( entry, agrument, , "Type" );
				entry.Type = Conversion.EnumItemToName ( agrument.Type );
				params.Add ( entry );
			enddo;
			entry = new Structure ( "Name, Title, Description, Endpoint, Authentication, Internal, Arguments" );
			FillPropertyValues ( entry, call );
			entry.Authentication = Conversion.EnumItemToName ( call.Authentication );
			entry.Arguments = params;
			methods.Add ( entry );
		enddo;
		instructions.Add ( new Structure ( "Text, Functions", instruction.Text, methods ) );
	enddo;
	return instructions;
	
EndFunction

Function getAssistantFiles ( Data )
	
	return Data.Files.UnloadColumn ( "ID" );
	
EndFunction

Function updateAssistant ( Parameters, Content )

	server = DF.Pick ( Parameters.Assistant, "Server" );
	connection = prepareConnection ( server );
	request = new HTTPRequest ( "/assist/deploy", connection.header );
	request.SetBodyFromString ( Conversion.ToJSON ( Content ) );
	response = connection.http.Post ( request );
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
	|select allowed top 1 Files.ID as ID, Files.Login = &Me as Exists
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
	table = Search.Execute ().Unload ();
	return Conversion.RowToStructure ( table );
	
EndFunction

Function sendFile ( Connection, File, Data, Error )

	Data.Write ( File );
	request = new HTTPRequest ( "/assist/upload", Connection.header );
	request.SetBodyFromString ( File );
	try
		response = Connection.http.Post ( request );
		answer = response.GetBodyAsString ();
		if ( response.StatusCode = Enum.HTTPStatusOK () ) then
			setSession ( Connection, getSession ( request ) );
			return ReadJSONValue ( answer ).id;
		endif;
	except
		error = ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
		return undefined;
	endtry;
	try
		info = ReadJSONValue ( answer );
		error = info.error.message;
	except
		error = answer;
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
	request = new HTTPRequest ( "/assist/stopRunning", connection.header );
	p = new Structure ( "thread", Thread );
	request.SetBodyFromString ( Conversion.ToJSON ( p ) );
	try
		connection.http.Post ( request );
		return true;
	except
		return false;
	endtry;
	
EndFunction
