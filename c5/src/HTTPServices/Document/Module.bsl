
Function BodyGet ( Request )
	
	p = getParams ();
	fetchParams ( p, Request );
	info = userInfo ( Request );
	html = getHTML ( p, info );
	response = new HTTPServiceResponse ( 200 );
	response.Headers.Insert ( "content-type", "text/html" );
	response.SetBodyFromString ( html );
	return response;
	
EndFunction

Function getParams ()
	
	p = new Structure ();
	p.Insert ( "Link" );
	p.Insert ( "Object" );
	p.Insert ( "Embedded", "0" );
	return p;
	
EndFunction 

Procedure fetchParams ( Params, Request )
	
	p = Conversion.MapToStruct ( Request.QueryOptions );
	FillPropertyValues ( Params, p );
	if ( Params.Link = undefined ) then
		Params.Link = Mid ( Request.RelativeURL, 2 );
	endif; 
	link = Params.Link;
	Params.Insert ( "Object", Left ( link, StrFind ( link, ".", , , 3 ) - 1 ) );
	
EndProcedure 

Function userInfo ( Request )
	
	return "" + Request.Headers.Get ( "Host" ) + ", " + Request.Headers.Get ( "User-Agent" );
	
EndFunction 

Function getHTML ( Params, UserInfo )
	
	data = getData ( Params );
	htmlOnly = Params.Embedded = "2";
	if ( data = undefined ) then
		caption = Output.DocumentNotFound ();
		if ( htmlOnly ) then
			return "<p>" + caption + "</p>";;
		endif; 
		link = Cloud.Website () + "/" + UserName ();
		html = "<html>
		|<head>
		|<meta content=""text/html; charset=utf-8"" http-equiv=Content-Type>
		|<link href=""" + Cloud.EditorStyleURL () + """ type=""text/css"" rel=""Stylesheet"" />
		|</head>
		|<body>
		|<p>" + caption + "</p>
		|</body>
		|</html>
		|";
	else
		ref = data.Ref;
		InformationRegisters.ReadingLog.Add ( ref, UserInfo );
		html = CKEditorSrv.GetHTML ( data.FolderID, not htmlOnly );
		DocumentPresenter.Compile ( html, ref );
		if ( htmlOnly ) then
			return html;
		endif;
		caption = "" + ref;
		link = Cloud.Manual () + "/" + UserName () + "/#" + GetURL ( ref );
	endif;
	document = Conversion.HTMLToDocument ( html );
	title = HTMLDoc.GetNode ( document, document.DocumentElement, "title" );
	title.TextContent = caption;
	if ( Params.Embedded = "1" ) then
		body = HTMLDoc.GetNode ( document, document.DocumentElement, "body" );
		header = Conversion.HTMLToDocument ( redirector ( link ) );
		headerBody = HTMLDoc.GetNode ( header, header.DocumentElement, "div" );
		import = document.ImportNode ( headerBody, true );
		body.InsertBefore ( import, body.FirstChild );	
	endif; 
	return Conversion.DocumentToHTML ( document );
	
EndFunction 

Function getData ( Params )
	
	link = Params.Link;
	if ( link = "" ) then
		return undefined;
	endif; 
	s = "
	|select allowed 0 as Priority, Documents.FolderID as FolderID, Documents.Ref as Ref
	|from Document.Document as Documents
	|where Documents.Link = &Link
	|";
	if ( Params.Object <> "" ) then
		s = s + "
		|union all
		|select 1, Documents.FolderID, Documents.Ref
		|from Document.Document as Documents
		|where Documents.Link = &Object
		|";
	endif; 
	s = s + "
	|order by Priority
	|";
	q = new Query ( s );
	q.SetParameter ( "Link", Params.Link );
	q.SetParameter ( "Object", Params.Object );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction 

Function redirector ( Link )
	
	s = "<div style='background:#FFFF99;border:1px solid #ccc;display:inline-block;margin:0px;padding:5px 10px;'>
	|<a href='" + link + "' target=_blank style='color: royalblue;text-decoration: none'>
	|" + Output.HelpPageHeader () + "
	|</a></div>";
	return s;
	
EndFunction 
