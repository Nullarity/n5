#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var Session;
var Request;
var Connection;
var Search;
var UploadedFiles;
var Folder;
var Separator;

Procedure Exec () export
	
	init ();
	uploadFiles ();
	saveResult ();
		
EndProcedure

Procedure init ()
	
	Connection = DataProcessors.Chat.PrepareConnection ( Parameters.Assistant, Parameters.Session );
	Request = new HTTPRequest ( "/assist/upload", Connection.header );
	initSearch ();
	UploadedFiles = new Array ();
	Folder = GetTempFileName ();
	Separator = GetPathSeparator ();
	
EndProcedure

Procedure initSearch ()

	Search = new Query ( "
	|select allowed top 1 Files.ID as ID, Files.Creator = &Me as Exists
	|from InformationRegister.AIFiles as Files
	|where Files.Hash = &Hash
	|order by Exists desc
	|" );
	Search.SetParameter ( "Me", SessionParameters.User );

EndProcedure

Procedure uploadFiles ()
	
	CreateDirectory ( folder );
	for each file in Parameters.Files do
		data = file.Data;
		hash = AttachmentsSrv.GetChecksum ( data );
		info = fileInfo ( hash );
		error = "";
		id = info.ID;
		if ( id = undefined ) then
			id = sendFile ( file, data, error );
			add = true;
		else
			id = info.ID;
			add = not info.Exists;
		endif;
		if ( add
			and id <> undefined ) then
			register ( file, hash, id );
		endif;
		commit ( file, id, error );
	enddo;
	DeleteFiles ( folder );
	
EndProcedure

Function fileInfo ( Hash )
	
	Search.SetParameter ( "Hash", Hash );
	table = Search.Execute ().Unload ();
	return Conversion.RowToStructure ( table );
	
EndFunction

Function sendFile ( File, Data, Error )

	path = Folder + Separator + File.Name;
	Data.Write ( path );
	if ( Session <> "" ) then
		Connection.Header [ "Cookie" ] = "session=" + Session;
	endif;
	Request.SetBodyFromString ( path );
	try
		response = Connection.http.Post ( Request );
		answer = response.GetBodyAsString ();
		if ( response.StatusCode = 200 ) then
			DataProcessors.Chat.SetSession ( response, Session );
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

Procedure register ( File, Hash, ID )
	
	r = InformationRegisters.AIFiles.CreateRecordManager ();
	r.Hash = Hash;
	r.ID = ID;
	r.Created = CurrentSessionDate ();
	r.Creator = SessionParameters.User;
	r.Extension = FileSystem.GetExtensionIndex ( File.Name );
	size = File.Size;
	r.Size = size;
	r.FileSize = Conversion.BytesToSize ( size );
	r.Name = File.Name;
	r.Write ();

EndProcedure

Procedure commit ( File, ID, Error )

	UploadedFiles.Add ( new Structure ( "File, ID, Error", File, ID, Error ) );
	
EndProcedure

Procedure saveResult ()
	
	result = new Structure ( "Session, Files", Session, UploadedFiles );
	PutToTempStorage ( result, Parameters.Result );
	
EndProcedure

#endif