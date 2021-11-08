#region InitEmail

Procedure InitEmail ( Element, Object, Content, ReadOnly = false, Focus = false ) export

	functions = getFunctions ( true, createEmailScript ( Object ), ReadOnly, , Focus );
	Element = getEditorHTML ( Object.MessageID, functions, Content );

EndProcedure 

Function getEditorHTML ( ID, Functions, Content )
	
	externalFile = not Environment.WebClient ();
	s = "<html>
	|<head>";
	if ( externalFile ) then
		s = s + "
		|<meta http-equiv=""cache-control"" content=""max-age=0"" />
		|<meta http-equiv=""cache-control"" content=""no-cache"" />
		|<meta http-equiv=""expires"" content=""0"" />
		|<meta http-equiv=""expires"" content=""Tue, 01 Jan 1980 1:00:00 GMT"" />
		|<meta http-equiv=""pragma"" content=""no-cache"" />
		|";
	endif; 
	s = s + "
	|	<script src=""" + Cloud.EditorURL () + """></script>
	|	<script type=""text/javascript"">" + Functions + "</script>
	|</head>
	|<body style=""overflow-y: hidden;overflow-x: hidden;margin: 0px;padding: 0px;"">
	|	<a name=""%save"" id=""%save"" style=""visibility:hidden"" href=""%save""></a>
	|	<a name=""%saveAndClose"" id=""%saveAndClose"" style=""visibility:hidden"" href=""%saveAndClose""></a>
	|	<a name=""%files"" id=""%files"" style=""visibility:hidden"" href=""%files""></a>
	|	<a name=""%cancel"" id=""%cancel"" style=""visibility:hidden"" href=""%cancel""></a>
	|	<div style=""height:100%"">
	|	<textarea class=""ckeditor"" id=""editor1"" name=""editor1"">
	|		" + Content + "
	|	</textarea>
	|	</div>
	|</body>
	|</html>";
	insertActions ( s );
	if ( externalFile ) then
		return htmlFile ( s, ID );
	else
		return s;
	endif;
	
EndFunction 

Function createEmailScript ( Object )
	
	folder = getEmailFolder ( Object );
	folderURL = EmailsSrv.GetFolderURL ( Object.MessageID, Object.Mailbox ) + "/" + Cloud.EmailAttachmentsFolder ();
	script = getUploadingScript ( folder, folderURL );
	writer = new TextWriter ( getUploadingFile ( Object.MessageID ) );
	writer.Write ( script );
	writer.Close ();
	return getUploadingURL ( Object.MessageID );

EndFunction

Function getEmailFolder ( Object )
	
	folder = EmailsSrv.GetAttachmentsFolder ( Object.MessageID, Object.Mailbox );
	if ( not FileSystem.Exists ( folder ) ) then
		CreateDirectory ( folder );
	endif; 
	return folder;

EndFunction

Function getUploadingScript ( Folder, FolderURL )
	
	s = "
	|<%@ Page Language=""C#"" Strict=""true""%>
	|<script runat=""server"">
	|protected void  Page_Load(object sender, EventArgs e)
	|{
	|	Response.Write(processUpload());
	|}
	|
	|private String processUpload()
	|{
	|    String basePath = """ + csharp ( Folder ) + """;
	|    String baseUrl = """ + FolderURL + "/"";
	|    String CKEditor = HttpContext.Current.Request[""CKEditor""] ;
	|    String funcNum = HttpContext.Current.Request[""CKEditorFuncNum""] ;
	|    String langCode = HttpContext.Current.Request[""langCode""] ;
	|   	int total;
	|	try
	|	{
	|		total = HttpContext.Current.Request.Files.Count;
	|	}
	|	catch (Exception e)
	|	{
	|		return  sendError(""Error uploading the file"");
	|	}
	|	if (total==0)
	|		return sendError(""No file has been sent"");
	|	if (!System.IO.Directory.Exists(basePath))
	|		return sendError(""basePath folder doesn't exists"");
	|	HttpPostedFile theFile = HttpContext.Current.Request.Files[0];
	|	String strFileName = theFile.FileName;
	|	if (strFileName=="""")
	|		return sendError(""File name is empty"");
	|	String sFileName = System.IO.Path.GetFileName(strFileName);
	|	String name = System.IO.Path.Combine(basePath, sFileName);
	|	theFile.SaveAs(name);
	|	String url = baseUrl + sFileName.Replace(""'"", ""\'"");
	|	return ""<scr"" + ""ipt type='text/javascript'> window.parent.CKEDITOR.tools.callFunction("" + funcNum + "", '"" + url + ""', '')</scr"" + ""ipt>"";
	|}
	|
	|private String sendError(String msg)
	|{
	|	String funcNum = HttpContext.Current.Request[""CKEditorFuncNum""] ;
	|	return ""<scr"" + ""ipt type='text/javascript'> window.parent.CKEDITOR.tools.callFunction("" + funcNum + "", '', '"" + msg + ""')</scr"" + ""ipt>"";
	|}
	|</script>
	|";
	return s;
	
EndFunction 

Function csharp ( Code )
	
	return StrReplace ( Code, "\", "\\" );
	
EndFunction 

Function getUploadingFile ( ID )
	
	return Cloud.UploadsFolder () + "\" + ID + ".aspx";
	
EndFunction 

Function getFunctions ( Email, UploadingPage, ReadOnly, Uploading = true, Focus = false )
	
	s = "
	|var IsDirty = false;
	|var EditorIsReady = false;
	|var Files = new Array ();
	|var FileName;
	|var FileSize;
	|var Content;
	|CKEDITOR.style.includeReadonly = true;
	|CKEDITOR.config.allowedContent = true;
	|CKEDITOR.config.disableNativeSpellChecker = false;
	|CKEDITOR.config.filebrowserBrowseUrl = '" + UploadingPage + "?type=Files';
	|CKEDITOR.config.filebrowserUploadUrl = '" + UploadingPage + "?type=Files';
	|CKEDITOR.config.startupFocus = " + ? ( Focus, "true", "false" ) + ";
	|";
	if ( Environment.WebClient () ) then
		s = s + "CKEDITOR.config.codeSnippet_languages = {
		|	'1C': '1C',
		|	sql: 'SQL',
		|	html: 'HTML',
		|	css: 'CSS',
		|	javascript: 'JavaScript',
		|	xhtml: 'XHTML',
		|	xml: 'XML',
		|	json: 'JSON',
		|	ini: 'INI',
		|	bash: 'Bash'
		|};";
	endif; 
	s = s + "
	|CKEDITOR.config.removeButtons = 'Strike,Subscript,Superscript,Cut,Copy,Paste,Image,Undo,Redo";
	if ( Email ) then
		s = s + ",Iframe,CodeSnippet";
	endif; 
	if ( not Uploading ) then
		s = s + ",addFile";
	endif; 
	s = s + "';
	|CKEDITOR.on('instanceReady', function(E) {
	|	E.editor.on('simpleuploads.endUpload', function (E) {
	|		if(E.data.OldIE) {
	|			if(!E.data.ok || !E.data.File) return;
	|			Files.push ( {Name : E.data.name, Size : -1, Inserted : false} );
	|			document.getElementById ('%files').click();
	|			return;
	|		} else if(!E.data.ok
	|				|| E.data.data == undefined
	|				|| E.data.data.file.type == undefined
	|				|| (!E.data.data.forceLink && E.data.data.file.type.indexOf('image') == 0)) return;
	|		Files.push ( {Name : E.data.name, Size : E.data.data.file.size, Inserted : false} );
	|		document.getElementById ('%files').click();
  	|	});";
	if ( ReadOnly ) then
		s = s + "
		|E.editor.setReadOnly(true);";
	endif; 
	s = s + "
	|	EditorIsReady = true;
	|});
	|
	|CKEDITOR.on('instanceCreated', function(E) {
	|	E.editor.on('key', function(E) {
	|		if(E.data.keyCode == CKEDITOR.CTRL + 83) {
	|			E.cancel();
	|			document.getElementById('%save').click();
	|		} else if(E.data.keyCode == CKEDITOR.CTRL + 13) {
	|			E.cancel();
	|			document.getElementById('%saveAndClose').click();
	|		} else if(E.data.keyCode == 27) {
	|			E.cancel();
	|			document.getElementById('%cancel').click();
	|		}
	|	});
	|});
	|
	|function isFile(E){
	|	if(E.filePickerForceLink) return E.ok;
	|	if(!E.data.ok) return false;
	|	if(E.filePickerForceLink) return true;
	|	return !(E.data.data == undefined || E.data.data.file.type == undefined || (!E.data.data.forceLink && E.data.data.file.type.indexOf('image') == 0));
	|}
	|
	|function Focus(){
	|	var editor = CKEDITOR.instances.editor1;
	|	editor.focus();
	|}
	|
	|function GetFile(){
	|	var data = Files.splice(-1, 1)[0];
	|	FileName = data.Name;
	|	FileSize = data.Size;
	|}
	|
	|function AddFiles(){
	|	var editor = CKEDITOR.instances.editor1;
	|	editor.execCommand('addFile');
	|}
	|
	|function InsertHTML(Text){
	|	var editor = CKEDITOR.instances.editor1;
	|	editor.insertHtml(Text);
	|}
	|
	|function SetContent(Text) {
	|	var editor = CKEDITOR.instances.editor1;
	|	editor.setData(Text);
	|}
	|
	|function GetContent() {
	|	var editor = CKEDITOR.instances.editor1;
	|	Content = editor.getData();
	|}
	|
	|function CheckDirty(){
	|	var editor = CKEDITOR.instances.editor1;
	|	IsDirty = editor.checkDirty();
	|}
	|
	|function ResetDirty () {
	|	var editor = CKEDITOR.instances.editor1;
	|	editor.resetDirty();
	|}
	|
	|function EnableEditor () {
	|	var editor = CKEDITOR.instances.editor1;
	|	editor.setReadOnly(false);
	|}
	|";
	return s;
	
EndFunction 

Function getUploadingURL ( ID )
	
	return Cloud.UploadsWebsite () + "/" + ID + ".aspx";
	
EndFunction 

Procedure insertActions ( HTML )
	
	p = new Structure ();
	p.Insert ( "save", Enum.EditorActionSave () );
	p.Insert ( "saveAndClose", Enum.EditorActionSaveAndClose () );
	p.Insert ( "cancel", Enum.EditorActionCancel () );
	p.Insert ( "files", Enum.EditorActionFiles () );
	HTML = Output.FormatStr ( HTML, p );
	
EndProcedure

Function htmlFile ( HTML, ID )
	
	path = Cloud.UploadsFolder () + "\" + ID + ".html";
	url = Cloud.UploadsWebsite () + "/" + ID + ".html";
	writer = new TextWriter ( path );
	writer.Write ( HTML );
	writer.Close ();
	return url;
	
EndFunction 

#endregion

#region Init

Procedure Init ( Element, FolderID, Content = undefined, ReadOnly = false, Uploading = true, Focus = false ) export

	functions = getFunctions ( false, createScript ( FolderID ), ReadOnly, Uploading, Focus );
	html = ? ( Content = undefined, CKEditorSrv.GetHTML ( FolderID ), Content );
	Element = getEditorHTML ( FolderID, functions, html );

EndProcedure 

Function createScript ( FolderID )
	
	folder = createFolder ( FolderID );
	folderURL = CKEditorSrv.GetFolderURL ( FolderID );
	script = getUploadingScript ( folder, folderURL );
	writer = new TextWriter ( getUploadingFile ( FolderID ) );
	writer.Write ( script );
	writer.Close ();
	return getUploadingURL ( FolderID );

EndFunction

Function createFolder ( FolderID )
	
	folder = CKEditorSrv.GetFolder ( FolderID );
	if ( not FileSystem.Exists ( folder ) ) then
		CreateDirectory ( folder );
	endif; 
	return folder;

EndFunction

#endregion

Function GetHTML ( FolderID, Complete = false ) export
	
	file = CKEditorSrv.GetFolder ( FolderID ) + "\" + FolderID;
	if ( not FileSystem.Exists ( file ) ) then
		return "";
	endif; 
	reader = new TextReader ( file, "utf-8" );
	body = "";
	while ( true ) do
		s = reader.Read ( 1024 );
		if ( s = undefined ) then
			break;
		endif; 
		body = body + s;
	enddo; 
	if ( Complete ) then
		plugin = Cloud.EditorRootURL () + "/plugins/codesnippet/lib/highlight";
		html = "<html>
		|<head>
		|<base href=""./"">
		|<meta content=""text/html; charset=utf-8"" http-equiv=Content-Type>";
		if ( not Environment.WebClient () ) then
			html = html + "<meta http-equiv=""x-ua-compatible"" content=""IE=9"">";
		endif; 
		html = html + "
		|<link href=""" + Cloud.EditorStyleURL () + """ type=""text/css"" rel=""Stylesheet"" />
		|<link href=""" + plugin + "/styles/default.css"" rel=""stylesheet"" />
		|<script src=""" + plugin + "/highlight.pack.js""></script>
		|<script>hljs.initHighlightingOnLoad();</script>
		|</head>
		|" + body + "
		|</html>
		|";
		return html;
	else
		return body;
	endif; 
	
EndFunction 

Function GetFolder ( FolderID, ShouldExist = true ) export
	
	folder = Cloud.GetFolders ();
	if ( folder = "" ) then
		if ( ShouldExist ) then
			if ( Logins.Sysadmin () ) then
				raise Enum.ExceptionsUndefinedFilesFolder ();
			else
				raise Output.UndefinedFilesFolder ();
			endif;
		else
			return undefined;
		endif;
	endif;
	separator = GetPathSeparator ();
	return folder + separator + Cloud.GetTenantCode () + separator + FolderID;

EndFunction 

Function GetFolderURL ( FolderID ) export
	
	url = Cloud.GetFoldersURL ();
	tenant = Cloud.GetTenantCode ();
	return Lower ( url + "/" + tenant + "/" + FolderID );
	
EndFunction 

Procedure Clean ( val FolderID ) export
	
	folder = CKEditorSrv.GetFolder ( FolderID, false );
	if ( folder <> undefined ) then
		DeleteFiles ( folder );
	endif;
	
EndProcedure 

Procedure RemoveScript ( val ID ) export
	
	name = Cloud.UploadsFolder () + "\" + ID;
	DeleteFiles ( name + ".html" );
	DeleteFiles ( name + ".aspx" );
	
EndProcedure 

Function GetText ( HTML ) export
	
	extractor = CoreLibrary.Chilkat ( "HtmlToText" );
	return extractor.ToText ( HTML );
	
EndFunction

Procedure Store ( FolderID, HTML ) export
	
	if ( HTML = undefined ) then
		return;
	endif; 
	path = CKEditorSrv.GetFolder ( FolderID ) + "\" + FolderID;
	writer = new TextWriter ( path );
	writer.Write ( HTML );
	writer.Close ();
	
EndProcedure

Procedure Copy ( CopyingValue, FolderID ) export
	
	CKEditorSrv.CopyDocument ( CopyingValue.FolderID, FolderID );

EndProcedure 

Procedure CopyDocument ( FolderFrom, FolderTo ) export
	
	folder = CKEditorSrv.GetFolder ( FolderFrom );
	folder2 = CKEditorSrv.GetFolder ( FolderTo );
	FileSystem.CopyFolder ( folder, folder2, true );

EndProcedure
