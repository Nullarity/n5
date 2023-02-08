Function UploadFiles ( val Files, val Reference, val FolderID, val Mailbox = undefined,
	val GeneratePreview = false ) export
	
	separator = GetPathSeparator ();
	if ( Mailbox = undefined ) then
		folder = CKEditorSrv.GetFolder ( FolderID ) + separator;
	else
		folder = EmailsSrv.GetAttachmentsFolder ( FolderID, Mailbox ) + separator;
	endif; 
	result = new Array ();
	for each file in Files do
		data = GetFromTempStorage ( file.Address );
		fileName = file.Name;
		data.Write ( folder + fileName );
		record = AttachmentsSrv.AddFile ( Reference, fileName, file.Size, FolderID );
		result.Add ( record );
	enddo;
	return result;
	
EndFunction

Function AddFile ( val Reference, val Name, val Size, val FolderID ) export
	
	data = new Structure ();
	data.Insert ( "File", Name );
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
		|select count ( Files.ID ) as Count
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
		|select count ( Files.ID ) as Count
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

Function PreviewScript ( File, Address ) export
	
	if ( FileSystem.Picture ( File ) ) then
		s = "
		|<html>
		|<body>
		|<img src='" + Attachments.GetLink ( Address ) + "'>
		|</body>
		|</html>
		|";
	elsif ( FileSystem.HyperText ( File )
		or FileSystem.PlainText ( File ) ) then
		data = GetFromTempStorage ( Address );
		reader = new TextReader ( data.OpenStreamForRead () );
		s = "
		|<html>
		|<body>
		|<pre>" + reader.Read () + "</pre>
		|</body>
		|</html>
		|";
	elsif ( FileSystem.GoogleDoc ( File ) ) then
		s = Attachments.GetLink ( Address );
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
		|<iframe id=""preview"" name=""preview"" style=""height:100%;width:100%"" src=""https://view.officeapps.live.com/op/view.aspx?src="
		+ Attachments.GetLink ( Address ) + """></iframe>
		|</body>
		|</html>
		|";
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

Function GetFile ( val FolderID, val File, val Mailbox, val FormUUID ) export
	
	if ( Mailbox = undefined ) then
		folder = CKEditorSrv.GetFolder ( FolderID );
	else
		folder = EmailsSrv.GetAttachmentsFolder ( FolderID, Mailbox );
	endif; 
	path = folder + GetPathSeparator () + File;
	data = new BinaryData ( path );
	return PutToTempStorage ( data, FormUUID );
	
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
