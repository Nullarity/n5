
Procedure Compile ( HTML, Document ) export
	
	dictionary = getDictionary ( Document );
	replaceTemplates ( HTML, Document, dictionary, undefined );
	
EndProcedure 

Procedure replaceTemplates ( HTML, Document, Dictionary, Passed )
	
	if ( Passed = undefined ) then
		Passed = new Map ();
	endif; 
	replaced = false;
	matches = findTemplates ( HTML );
	for each match in matches do
		expression = match.SubMatches ( 0 );
		if ( Passed [ expression ] = undefined ) then
			Passed [ expression ] = true;
		else
			continue;
		endif; 
		template = match.SubMatches ( 1 );
		if ( StrStartsWith ( expression, "~" )
			and StrEndsWith ( expression, "~" ) ) then
			text = tagsToHTML ( template, Document );
		else
			text = askDistionary ( Dictionary, template );
		endif;
		if ( text = undefined ) then
			HTML = Regexp.Replace ( HTML, expression, "<font color='red'>" + expression + "</font>" );
			Output.DictionaryTemplateNotFound ( new Structure ( "Template", template ) );
		else
			HTML = Regexp.Replace ( HTML, expression, text );
			replaced = true;
		endif; 
	enddo; 
	if ( replaced ) then
		replaceTemplates ( HTML, Document, Dictionary, Passed );
	endif; 
	
EndProcedure 

Function findTemplates ( HTML )
	
	pattern = "[^A-Za-zА-Яа-я0-9]([~#]([A-Za-zА-Яа-я]+?)[~#])";
	matches = Regexp.Select ( HTML, pattern );
	result = new ValueTable ();
	result.Columns.Add ( "Length", new TypeDescription ( "String" ) );
	result.Columns.Add ( "Match" );
	for each match in matches do
		row = result.Add ();
		row.Length = StrLen ( String ( match.Value ) );
		row.Match = match;
	enddo;
	result.Sort ( "Length DESC" );
	return result.UnloadColumn ( "Match" );
	
EndFunction 

Function getDictionary ( Reference )
	
	SetPrivilegedMode ( true );
	s = "
	|select Dictionary.ID as ID, Dictionary.Text as Text
	|from Catalog.Books.Dictionary as Dictionary
	|where Dictionary.Ref = &Ref
	|";
	q = new Query ( s );
	ref = DF.Pick ( Reference, "Book" );
	table = new ValueTable ();
	columns = table.Columns;
	string = new TypeDescription ( "String" );
	columns.Add ( "ID", string );
	columns.Add ( "Text", string );
	while ( not ref.IsEmpty () ) do
		q.SetParameter ( "Ref", ref );
		CollectionsSrv.Join ( table, q.Execute ().Unload () );
		ref = DF.Pick ( ref, "Parent" );
	enddo; 
	return table;
	
EndFunction 

Function tagsToHTML ( TagsString, Document )
	
	table = findDocuments ( TagsString, Document );
	if ( table.Count () = 0 ) then
		return undefined;
	endif;
	parts = new Array ();
	parts.Add ( "<ul>" );
	for each row in table do
		parts.Add ( linkAddress ( row.Document, row.Link, row.Subject ) );
	enddo;
	parts.Add ( "</ul>" );
	return StrConcat ( parts );

EndFunction

Function findDocuments ( TagsString, Document )
	
	s = "
	|select allowed distinct Tags.Document.Book.Sorting as Sorting, Tags.Document.Link as Link,
	|	Tags.Document.Subject as Subject, Tags.Document as Document
	|from InformationRegister.Tags as Tags
	|where Tags.Tag in ( select Ref from Catalog.Tags where Description in ( &Tags ) )
	|and Tags.Document.Link <> """"
	|and Tags.Document.Ref <> &Itself
	|order by Tags.Document.Book.Sorting, Tags.Document.Subject
	|";
	q = new Query ( s );
	q.SetParameter ( "Itself", Document );
	q.SetParameter ( "Tags", Conversion.StringToArray ( TagsString ) );
	return q.Execute ().Unload ();
	
EndFunction

Function linkAddress ( Ref, Link, Text )
	
	if ( SessionParameters.UserClass = Enums.Users.HelpAgent ) then
		address = Cloud.Manual () + "/" + UserName () + "/hs/Document?Link=" + Link;
	else
		address = GetURL ( Ref );
	endif;
	return "<li><a href=""" + address + """>" + Text + "</a></li>";
	
EndFunction

Function askDistionary ( Distionary, Template )
	
	result = Distionary.Find ( Template, "ID" );
	return ? ( result = undefined, undefined, result.Text );
	
EndFunction
