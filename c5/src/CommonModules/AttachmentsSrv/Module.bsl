Function AddFile ( val Reference, val Name, val Size, val Count = undefined, val FolderID, val GeneratePreview ) export
	
	data = new Structure ();
	data.Insert ( "File", FileSystem.GetFileName ( Name ) );
	data.Insert ( "Size", ? ( Size = -1, getSize ( data.File, FolderID ), Size ) );
	data.Insert ( "FileSize", Conversion.BytesToSize ( data.Size ) );
	data.Insert ( "Date", CurrentSessionDate () );
	data.Insert ( "Extension", FileSystem.GetExtensionIndex ( Name ) );
	if ( Reference.IsEmpty () ) then
		data.Insert ( "ID", new UUID () );
	else
		info = getInfo ( Reference, data.File );
		data.Insert ( "ID", info.ID );
		if ( TypeOf ( Reference ) = Type ( "CatalogRef.Projects" ) ) then
			saveProjectFile ( Reference, data );
		else
			saveDocumentFile ( Reference, data );
			AttachmentsSrv.UpdateFileNames ( Reference );
		endif;
		AttachmentsSrv.CommitDownloading ( Reference, data.File );
		Count = info.Count;
		saveCount ( Reference, Count + 1 );
	endif; 
	if ( GeneratePreview ) then
		BuildPreview ( data.File, data.ID, FolderID );
	endif; 
	return data;
	
EndFunction

Function getSize ( Name, FolderID )
	
	path = CKEditorSrv.GetFolder ( FolderID ) + "\" + Name;
	file = new File ( path );
	return file.Size ();
	
EndFunction 

Function getInfo ( Reference, File )
	
	if ( TypeOf ( Reference ) = Type ( "CatalogRef.Projects" ) ) then
		s = "
		|select Files.ID as ID
		|from InformationRegister.ProjectFiles as Files
		|where Files.Project = &Reference
		|and Files.File = &File
		|;
		|select count ( * ) as Count
		|from InformationRegister.ProjectFiles as Files
		|where Files.Project = &Reference
		|and Files.File <> &File
		|";
	else
		s = "
		|select Files.ID as ID
		|from InformationRegister.Files as Files
		|where Files.Document = &Reference
		|and Files.File = &File
		|;
		|select count ( * ) as Count
		|from InformationRegister.Files as Files
		|where Files.Document = &Reference
		|and Files.File <> &File
		|";
	endif; 
	q = new Query ( s );
	q.SetParameter ( "Reference", Reference );
	q.SetParameter ( "File", File );
	data = q.ExecuteBatch ();
	id = data [ 0 ].Unload ();
	count = data [ 1 ].Unload ();
	result = new Structure ( "ID, Count" );
	if ( id.Count () = 0 ) then
		result.ID = new UUID ();
	else
		result.ID = id [ 0 ].ID;
	endif; 
	if ( count.Count () = 0 ) then
		result.Count = 0;
	else
		result.Count = count [ 0 ].Count;
	endif; 
	return result;
	
EndFunction 

Procedure saveProjectFile ( Project, Data )
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.ProjectFiles.CreateRecordManager ();
	FillPropertyValues ( r, Data );
	r.Project = Project;
	r.Write ();
	SetPrivilegedMode ( false );
	
EndProcedure 

Procedure saveDocumentFile ( Document, Data )
	
	r = InformationRegisters.Files.CreateRecordManager ();
	FillPropertyValues ( r, Data );
	r.Document = Document;
	r.Write ();
	
EndProcedure 

Procedure CommitDownloading ( val Reference, val File ) export
	
	date = CurrentSessionDate ();
	r = InformationRegisters.Downloads.CreateRecordManager ();
	r.User = SessionParameters.User;
	r.Reference = Reference;
	r.File = file;
	r.Date = date;
	r.Write ();
	
EndProcedure 

Procedure BuildPreview ( File, FileID, FolderID ) export
	
	source = CKEditorSrv.GetFolder ( FolderID ) + "\";
	sourceURL = CKEditorSrv.GetFolderURL ( FolderID ) + "/";
	ext = FileSystem.GetExtension ( File );
	env = new Structure ();
	env.Insert ( "Destination", source + FileID );
	FileSystem.ClearFolder ( env.Destination, true );
	CreateDirectory ( env.Destination );
	env.Insert ( "LogFile", env.Destination + ".log" );
	env.Insert ( "SourceFile", source + File );
	env.Insert ( "SourceURL", sourceURL + File );
	env.Insert ( "HTMLFile", env.Destination + "\index.html" );
	env.Insert ( "PDFFile", env.Destination + "\" + FileID + ".pdf" );
	env.Insert ( "Extension", ext );
	s = "." + ext + ";";
	if ( Find ( ".doc;.docx;", s ) > 0 ) then
		convertDoc ( env );
	elsif ( Find ( ".xls;.xlsx;", s ) > 0 ) then
		convertXLS ( env );
	elsif ( Find ( ".pdf;", s ) > 0 ) then
		convertPDF ( env );
	elsif ( FileSystem.PlainText ( File ) ) then
		convertText ( env );
	endif; 
	
EndProcedure 

Procedure convertDoc ( Env )
	
	app = Cloud.ConvertDocExe ();
	if ( app = "" ) then
		return;
	endif;
	if ( Env.Extension = "doc" ) then
		p = "/F9";
	elsif ( Env.Extension = "docx" ) then
		p = "/F13";
	endif; 
	command = """" + app + """ /M2 /S """ + Env.SourceFile + """ /L""" + Env.LogFile + """";
	htmlCmd = command + """ /T """ + Env.HTMLFile + """ /C4 " + p;
	pdfCmd = command + """ /T """ + Env.PDFFile + """ /C12 " + p;
	RunApp ( htmlCmd );
	RunApp ( pdfCmd );
	
EndProcedure 

Procedure convertXLS ( Env )
	
	app = Cloud.ConvertXLSExe ();
	if ( app = "" ) then
		return;
	endif;
	htmlCmd = """" + app + """ /C44 /M1 /N1-100 /F-4143 /S""" + Env.SourceFile + """ /T""" + Env.HTMLFile + """ /L""" + Env.LogFile + """";
	pdfCmd = """" + app + """ /C-1 /M1 /S""" + Env.SourceFile + """ /T""" + Env.PDFFile + """ /L""" + Env.LogFile + """";
	RunApp ( htmlCmd );
	RunApp ( pdfCmd );

EndProcedure 

Procedure convertPDF ( Env )
	
	app = Cloud.HTMLExe ();
	if ( app = "" ) then
		return;
	endif;
	command = """" + app + """ --single --src=""" + Env.SourceFile + """ --dest=""" + Env.Destination + """ --pages=""1-5""";
	RunApp ( command );
	
EndProcedure 

Procedure convertText ( Env )
	
	reader = new TextReader ( Env.SourceFile, TextEncoding.System );
	writer = new TextWriter ( Env.HTMLFile, TextEncoding.System );
	writer.WriteLine ( "<html>
	|<head>
	|<meta content=""text/html; charset=utf-8"" http-equiv=Content-Type>
	|</head>
	|<body style=""overflow-y:hidden"">
	|<textarea readonly style=""border:0px;padding:0px;margin:0px;width:100%;height:100%"">" );
	while ( true ) do
		s = reader.Read ( 1024 );
		if ( s = undefined ) then
			break;
		endif; 
		writer.Write ( s );
	enddo; 
	writer.WriteLine ( "</textarea></body></html>" );
	writer.Close ();
	
EndProcedure 

Procedure saveCount ( Reference, Count )
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.AttachmentsCount.CreateRecordManager ();
	r.Reference = Reference;
	if ( Count = 0 ) then
		r.Delete ();
	else
		r.Count = Count;
		r.Extension = getFirstExtension ( Reference );
		r.Write ();
	endif; 
	SetPrivilegedMode ( false );
	
EndProcedure 

Function getFirstExtension ( Reference )
	
	refType = TypeOf ( Reference );
	if ( refType = Type ( "CatalogRef.Projects" ) ) then
		s = "
		|select top 1 Files.Extension as Extension
		|from InformationRegister.ProjectFiles as Files
		|where Files.Project = &Reference
		|order by Files.Date
		|";
	else
		s = "
		|select top 1 Files.Extension as Extension
		|from InformationRegister.Files as Files
		|where Files.Document = &Reference
		|order by Files.Date
		|";
	endif;
	q = new Query ( s );
	q.SetParameter ( "Reference", Reference );
	return q.Execute ().Unload () [ 0 ].Extension;
	
EndFunction 

Function PreviewScript ( File, URL ) export
	
	if ( FileSystem.Picture ( File ) ) then
		webServer = Cloud.Website ();
		s = "
		|<html>
		|<head>
		|<script src='" + webServer + "/jquery-1.8.3.min.js'></script>
		|<link href='" + webServer + "/viewer/viewer.min.css' rel='stylesheet'> 
		|<script type='text/javascript' src='" + webServer + "/viewer/viewer.min.js'></script>
		|</head>
		|<body>
		|<img class='image' style='visibility:hidden;width:100%' src='" + URL + "'>
		|<script>
		|$('.image').viewer({inline:true,title:false,transition:false});
		|</script>
		|</body>
		|</html>
		|";
	elsif ( FileSystem.GoogleDoc ( File ) ) then
		s = "
		|<html>
		|<head>
		|<meta http-equiv=""x-ua-compatible"" content=""IE=11"">
		|<script type=""text/javascript"">
		|    function resize () {
		|        var frame = document.getElementById(""preview"");
		|        frame.style.height = ( window.innerHeight + ""px"" );
		|    }
		|</script>
		|</head>
		|<body style=""padding: 0px; margin: 0px;overflow-x: hidden;overflow-y: hidden"" onload=""resize ()"" onresize=""resize ()"">
		|<iframe id=""preview"" name=""preview"" style=""height:100%;width:100%"" src=""https://docs.google.com/gview?url=" + URL + "&embedded=true&output=embed""></iframe>
		|</body>
		|</html>
		|";
	elsif ( FileSystem.OfficeDoc ( File ) ) then
		s = "
		|<html>
		|<head>
		|<meta http-equiv=""x-ua-compatible"" content=""IE=11"">
		|<script type=""text/javascript"">
		|    function resize () {
		|        var frame = document.getElementById(""preview"");
		|        frame.style.height = ( window.innerHeight + ""px"" );
		|    }
		|</script>
		|</head>
		|<body style=""padding: 0px; margin: 0px;overflow-x: hidden;overflow-y: hidden"" onload=""resize ()"" onresize=""resize ()"">
		|<iframe id=""preview"" name=""preview"" style=""height:100%;width:100%"" src=""https://view.officeapps.live.com/op/view.aspx?src=" + URL + """></iframe>
		|</body>
		|</html>
		|";
	elsif ( FileSystem.HyperText ( File )
		or FileSystem.PlainText ( File ) ) then
		s = url;
	else
		s = AttachmentsSrv.PreviewNotSupported ();
	endif; 
	return s;
	
EndFunction 

Function PreviewNotSupported () export
	
	return "
	|<html>
	|<head>
	|<style>
	|	body
	|	{
	|		overflow-y: hidden;
	|		overflow-x: hidden;
	|		margin: 10px;
	|		padding: 10px;
	|		font-size: 14pt;
	|		font-family: sans-serif;
	|	}
	|</style>
	|</head>
	|<body>
	|" + Output.PreviewNotSupported () + "
	|</body>
	|</html>
	|";
		
EndFunction 

Procedure UpdateFileNames ( val Reference ) export
	
	r = InformationRegisters.FileNames.CreateRecordManager ();
	r.Document = Reference;
	r.Files = getFileNames ( Reference );
	r.Write ();
	
EndProcedure 

Function getFileNames ( Reference )
	
	s = "
	|select Files.File as File
	|from InformationRegister.Files as Files
	|where Files.Document = &Reference
	|order by Files.File
	|";
	q = new Query ( s );
	q.SetParameter ( "Reference", Reference );
	files = q.Execute ().Unload ().UnloadColumn ( "File" );
	return StrConcat ( files, ", " );
	
EndFunction 

Procedure Remove ( val Reference, val Files, val FolderID, val Count ) export
	
	folder = CKEditorSrv.GetFolder ( FolderID ) + "\";
	for each item in Files do
		DeleteFiles ( folder + item.Name );
		if ( item.ID <> "" ) then
			DeleteFiles ( folder + item.ID );
		endif; 
	enddo; 
	if ( Reference.IsEmpty () ) then
		return;
	endif; 
	refType = TypeOf ( Reference );
	if ( refType = Type ( "CatalogRef.Projects" ) ) then
		removeProjects ( Reference, Files );
	else
		removeDocuments ( Reference, Files );
	endif; 
	saveCount ( Reference, Count );
	
EndProcedure 

Procedure removeProjects ( Project, Files )
	
	for each item in Files do
		r = InformationRegisters.ProjectFiles.CreateRecordManager ();
		r.Project = Project;
		r.File = item.name;
		r.Delete ();
	enddo; 
	
EndProcedure 

Procedure removeDocuments ( Document, Files )
	
	for each item in Files do
		r = InformationRegisters.Files.CreateRecordManager ();
		r.Document = Document;
		r.File = item.name;
		r.Delete ();
	enddo; 
	AttachmentsSrv.UpdateFileNames ( Document );
	
EndProcedure 

Function Rename ( val Document, val OldName, val NewName, val FolderID ) export
	
	ext = renameFileData ( Document, OldName, NewName );
	AttachmentsSrv.UpdateFileNames ( Document );
	changeDownloading ( Document, OldName, NewName );
	renameFile ( FolderID, OldName, NewName );
	return ext;
	
EndFunction

Function renameFileData ( Document, OldName, NewName )
	
	ext = FileSystem.GetExtensionIndex ( NewName );
	if ( not Document.IsEmpty () ) then
		r = InformationRegisters.Files.CreateRecordManager ();
		r.File = OldName;
		r.Document = Document;
		r.Read ();
		r.File = NewName;
		r.Extension = ext;
		r.Write ();
	endif; 
	return ext;
	
EndFunction 

Procedure changeDownloading ( Document, OldName, NewName )
	
	r = InformationRegisters.Downloads.CreateRecordManager ();
	r.User = SessionParameters.User;
	r.Reference = Document;
	r.File = OldName;
	r.Read ();
	if ( r.Selected () ) then
		r.File = NewName;
		r.Write ();
	endif; 
	
EndProcedure 

Procedure renameFile ( FolderID, OldName, NewName )
	
	folder = CKEditorSrv.GetFolder ( FolderID ) + "\";
	oldPath = folder + OldName;
	newPath = folder + NewName;
	MoveFile ( oldPath, newPath );
	
EndProcedure 

Function URL ( val File, val FolderID, val Mailbox, val Address ) export
	
	if ( Mailbox = undefined ) then
		folder = CKEditorSrv.GetFolder ( FolderID ) + "\";
	else
		folder = EmailsSrv.GetAttachmentsFolder ( FolderID, Mailbox ) + "\";
	endif; 
	path = folder + File;
	return new Structure ( "Name, Address", file, PutToTempStorage ( new BinaryData ( path ), Address ) );
	
EndFunction 

Procedure Save ( Reference, Table ) export
	
	count = Table.Count ();
	if ( count = 0 ) then
		return;
	endif; 
	if ( TypeOf ( Reference ) = Type ( "CatalogRef.Projects" ) ) then
		for each row in Table do
			if ( row.Dirty ) then
				saveProjectFile ( Reference, row );
			endif;
		enddo; 
	else
		for each row in Table do
			if ( row.Dirty ) then
				saveDocumentFile ( Reference, row );
			endif; 
		enddo; 
	endif; 
	saveCount ( Reference, count );
	
EndProcedure 

Function UserFolder () export
	
	folder = Logins.Settings ( "Folder" ).Folder;
	if ( IsBlankString ( folder ) ) then
		return undefined;
	else
		return folder;
	endif; 
	
EndFunction

Function BuildURL ( val FolderID, val File, val Mailbox ) export
	
	encodedFile = EncodeString ( File, StringEncodingMethod.URLEncoding );
	if ( Mailbox = undefined ) then
		folder = CKEditorSrv.GetFolder ( FolderID );
		url = CKEditorSrv.GetFolderURL ( FolderID );
	else
		folder = EmailsSrv.GetAttachmentsFolder ( FolderID, Mailbox );
		url = EmailsSrv.GetAttachmentsFolderURL ( FolderID, Mailbox );
	endif; 
	path = folder + "\" + File;
	url = url + "/" + encodedFile;
	return new Structure ( "URL, Path", url, path );
	
EndFunction 

Function Timestamp ( val Reference, val File ) export
	
	result = new Structure ( "Uploaded, Downloaded" );
	if ( Reference.IsEmpty () ) then
		never = Date ( 1, 1, 1 );
		result.Uploaded = never;
		result.Downloaded = never;
	else
		data = getTimestamp ( Reference, File );
		result.Uploaded = data.Uploaded;
		result.Downloaded = data.Downloaded;
		return result;
	endif; 
	return result;
	
EndFunction 

Function getTimestamp ( Reference, File )
	
	refType = TypeOf ( Reference );
	if ( refType = Type ( "DocumentRef.Document" )
		or refType = Type ( "DocumentRef.DocumentVersion" ) ) then
		s = "
		|select Files.Date as Uploaded, isnull ( Downloads.Date, datetime ( 1, 1, 1 ) ) as Downloaded
		|from InformationRegister.Files as Files
		|";
		where = "
		|where Files.Document = &Reference
		|and Files.File = &File
		|";
	elsif ( refType = Type ( "CatalogRef.Projects" ) ) then
		s = "
		|select Files.Date as Uploaded, isnull ( Downloads.Date, datetime ( 1, 1, 1 ) ) as Downloaded
		|from InformationRegister.ProjectFiles as Files
		|";
		where = "
		|where Files.Project = &Reference
		|and Files.File = &File
		|";
	elsif ( refType = Type ( "DocumentRef.IncomingEmail" ) ) then
		s = "
		|select Attachments.Ref.Received as Uploaded, isnull ( Downloads.Date, datetime ( 1, 1, 1 ) ) as Downloaded
		|from Document.IncomingEmail.Attachments as Attachments
		|";
		where = "
		|where Attachments.Ref = &Reference
		|and Attachments.File = &File
		|";
	elsif ( refType = Type ( "DocumentRef.OutgoingEmail" ) ) then
		s = "
		|select Attachments.Date as Uploaded, isnull ( Downloads.Date, datetime ( 1, 1, 1 ) ) as Downloaded
		|from Document.OutgoingEmail.Attachments as Attachments
		|";
		where = "
		|where Attachments.Ref = &Reference
		|and Attachments.File = &File
		|";
	endif; 
	s = s + "
	|	//
	|	// Downloads
	|	//
	|	left join InformationRegister.Downloads as Downloads
	|	on Downloads.User = &User
	|	and Downloads.Reference = &Reference
	|	and Downloads.File = &File";
	s = s + where;
	q = new Query ( s );
	q.SetParameter ( "Reference", Reference );
	q.SetParameter ( "File", File );
	q.SetParameter ( "User", SessionParameters.User );
	return q.Execute ().Unload () [ 0 ];
	
EndFunction 

Function Fetch ( val Document ) export
	
	info = new Structure ();
	info.Insert ( "Table", returnFiles ( Document ) );
	info.Insert ( "FolderID", DF.Pick ( Document, "FolderID" ) );
	return info;
	
EndFunction 

Function returnFiles ( Document )
	
	s = "
	|select Files.File as File, Files.Extension as Extension
	|from InformationRegister.Files as Files
	|where Files.Document = &Ref
	|order by Files.Date
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Document );
	table = q.Execute ().Unload ();
	return Collections.DeserializeTable ( CollectionsSrv.Serialize ( table ) );
	
EndFunction 
