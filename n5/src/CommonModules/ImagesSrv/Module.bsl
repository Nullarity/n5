Function Build ( val Item, val Resize ) export
	
	s = "<html>
	|<head><style>*{font-size: 12pt;font-family: sans-serif}</style></head>
	|<body>
	|";
	if ( Item.IsEmpty () ) then
		return s + "</body></html>";
	endif; 
	data = getData ( Item );
	fields = data.Fields;
	table = data.Table;
	count = table.Count ();
	canEdit = AccessRight ( "Edit", Metadata.Catalogs.Items );
	addFoto = Output.AddPictureLink ( new Structure ( "ID, Command", fields.Code, Enum.PictureCommandsAdd () ) );
	if ( count = 0 ) then
		s = s + Output.PictureNotFound () + "<br/>";
		if ( canEdit ) then
			s = s + addFoto;
		endif; 
	else
		s = s + "<p>" + Output.PicturesCount ( new Structure ( "Count", count ) );
		if ( canEdit ) then
			s = s + " | " + addFoto;
		endif;
		s = s + "</p>";
		style = "style=""cursor:pointer;" + ? ( Resize, "width:100%;max-width:100%", "" ) + """";
		for each row in table do
			id = """" + Enum.PictureCommandsOpenGallery () + "#" + row.ID + """";
			r = InformationRegisters.Gallery.CreateRecordKey ( new Structure ( "Reference, ID", Item, row.ID ) );
			url = GetURL ( r, "Photo" );
			s = s + "<p>" + getDescription ( row ) + ":<br/><img id=" + id + " name=" + id  + " " +  style + " src=""" + url + """/></p>";
			if ( canEdit ) then
				s = s + Output.DeletePictureLink ( new Structure ( "ID, Command", row.ID, Enum.PictureCommandsDelete () ) );
			endif; 
			s = s+ "</p><hr/>";
		enddo; 
	endif; 
	s = s + "</body></html>";
	return s;
	
EndFunction

Function getData ( Item )
	
	s = "
	|// @Fields
	|select Items.Code as Code, Items.Description as Description
	|from Catalog.Items as Items
	|where Items.Ref = &Ref
	|;
	|// #Table
	|select Gallery.ID as ID, Gallery.Description as Description, Gallery.Date as Date, Gallery.User.Description as User
	|from InformationRegister.Gallery as Gallery
	|where Gallery.Reference = &Ref
	|order by Gallery.Date
	|";
	env = SQL.Create ( s );
	env.Q.SetParameter ( "Ref", Item );
	SQL.Perform ( env );
	return env;
	
EndFunction 

Function getDescription ( Row )
	
	a = new Array ();
	s = StrReplace ( Row.Description, "<", """" );
	s = StrReplace ( s, ">", """" );
	if ( s <> "" ) then
		a.Add ( s );
	endif; 
	a.Add ( Row.User );
	a.Add ( Conversion.DateToString ( Row.Date ) );
	return StrConcat ( a, ", " );
	
EndFunction 

Function Image ( ID ) export
	
	webServer = Cloud.Website ();
	record = InformationRegisters.Gallery.CreateRecordKey ( new Structure ( "Reference, ID", getProduct ( ID ), ID ) );
	url = GetURL ( record, "Photo" );
	s = "
	|<html>
	|<head>
	|<script src='" + webServer + "/jquery-1.8.3.min.js'></script>
	|<script src='" + webServer + "/jquery.elevatezoom.js'></script>
	|</head>
	|<body>
	|<img name=""zoom"" id=""zoom"" style=""width:300px"" src=""" + url + """ data-zoom-image=""" + url + """/>
	|<script>
	|$('#zoom').elevateZoom({scrollZoom : true});
	|</script>
	|</body></html>";
	return s;
	
EndFunction 

Function getProduct ( ID )
	
	s = "
	|select Gallery.Reference as Reference
	|from InformationRegister.Gallery as Gallery
	|where Gallery.ID = &ID
	|";
	q = new Query ( s );
	q.SetParameter ( "ID", ID );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Reference );
	
EndFunction 

Procedure Add ( val Code, val Picture, val Description ) export
	
	item = Catalogs.Items.FindByCode ( Code );
	if ( item.IsEmpty () ) then
		return;
	endif;
	r = InformationRegisters.Gallery.CreateRecordManager ();
	r.Reference = item;
	r.ID = new UUID ();
	r.Photo = new ValueStorage ( GetFromTempStorage ( Picture ) );
	r.Description = Description;
	r.Date = CurrentSessionDate ();
	r.User = SessionParameters.User;
	r.Write ();
	
EndProcedure 

Procedure Delete ( val ID ) export
	
	r = InformationRegisters.Gallery.CreateRecordManager ();
	r.Reference = getProduct ( ID );
	r.ID = ID;
	r.Delete ();
	
EndProcedure 
