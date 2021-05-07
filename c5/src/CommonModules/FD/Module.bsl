Function GetHTML ( Document ) export
	
	html = "";
	pictures = new Structure ();
	Document.GetHTML ( html, pictures );
	list = sortedKeys ( pictures );
	for each id in list do
		picture = pictures [ id ];
		image = Base64String ( picture.GetBinaryData () );
		html = Regexp.Replace ( html, "(<img (.+)?src=)((.+)?" + id + ")", "$1""data:image/png;base64," + image );
	enddo;
	return html;
	
EndFunction

Function sortedKeys ( Pictures )
	
	table = new ValueTable ();
	columns = table.Columns;
	columns.Add ( "Id" );
	columns.Add ( "Size" );
	for each item in Pictures do
		id = item.Key;
		row = table.Add ();
		row.Id = id;
		row.Size = StrLen ( id );
	enddo;
	table.Sort ( "Size desc" );
	return table.UnloadColumn ( "Id" );
	
EndFunction
