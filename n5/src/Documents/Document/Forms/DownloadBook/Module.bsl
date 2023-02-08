&AtClient
var Count;
&AtClient
var Books;
&AtClient
var Folders;
&AtClient
var LastBook;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	applyParams ();
	
EndProcedure

&AtServer
Procedure applyParams ()
	
	Book = Parameters.Book;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	setWarning ();
	
EndProcedure

&AtClient
Procedure setWarning ()
	
	#if ( WebClient ) then
	 	Items.Warning.Visible = true;
	#else
	 	Items.Warning.Visible = false;
	#endif
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure FolderStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	LocalFiles.SelectFolder ( Item );
	
EndProcedure

&AtClient
Procedure Unload ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif; 
	LocalFiles.Prepare ( new NotifyDescription ( "Download", ThisObject ) );
	
EndProcedure

&AtClient
Procedure Download ( Result, Params ) export
	
	Books = Collections.DeserializeTable ( getBooks ( Book, Hierarchy ) );
	if ( Books.Count () = 0 ) then
		return;
	endif; 
	LastBook = Books.Count ();
	Count = 0;
	Folders = new Map ();
	for each row in Books do
		dir = getFolder ( row.Ref, row.Name );
		p = new Structure ( "Book, Folder, Name", row.Ref, dir, row.Name );
		BeginCreatingDirectory ( new NotifyDescription ( "FolderCreated", ThisObject, p ), dir );
	enddo; 

EndProcedure 

&AtServerNoContext
Function getBooks ( val Book, val Hierarchy )
	
	s = "
	|select allowed Books.Ref as Ref, Books.Description as Name
	|from Catalog.Books as Books
	|where not Books.DeletionMark
	|";
	if ( Hierarchy ) then
		s = s + "and Books.Ref in hierarchy ( &Book )";
	else
		s = s + "and Books.Ref = &Book";
	endif; 
	s = s + "
	|order by Books.Ref hierarchy
	|";
	q = new Query ( s );
	q.SetParameter ( "Book", Book );
	table = q.Execute ().Unload ();
	for each row in table do
		fixName ( row.Name );
	enddo; 
	return CollectionsSrv.Serialize ( table );
	
EndFunction 

&AtServerNoContext
Procedure fixName ( Name )
	
	pattern = "[\\/:*?<>|]+";
	matches = Regexp.Select ( Name, pattern );
	//@skip-warning
	for each match in matches do
		Name = Regexp.Replace ( Name, pattern, "" );
	enddo; 
	
EndProcedure

&AtClient
Function getFolder ( Ref, Name )
	
	if ( Folders [ Ref ] = undefined ) then
		if ( Ref = Book ) then
			dir = Folder;
			if ( CreateFolder ) then
				s = String ( Book );
				fixName ( s );
				dir = dir + "\" + s;
			endif; 
		else
			data = getParent ( Ref );
			if ( data.Parent.IsEmpty () ) then
				dir = Folders [ Book ] + "\" + Name;
			else
				dir = getFolder ( data.Parent, data.Description ) + "\" + Name;
			endif; 
		endif; 
		Folders [ Ref ] = dir;
	endif; 
	return Folders [ Ref ];
	
EndFunction 

&AtServerNoContext
Function getParent ( val Ref )
	
	data = DF.Values ( Ref, "Parent, Description" );
	fixName ( data.Description );
	return data;
	
EndFunction 

&AtClient
Procedure FolderCreated ( Result, Params ) export
	
	urls = getUrls ( Params.Book, UUID );
	Output.BookDownloaded ( new Structure ( "Name, Files", Params.Name, urls ) );
	if ( urls.Count () > 0 ) then
		BeginGetFilesFromServer ( new NotifyDescription ( "FilesDownloaded", ThisObject, urls ), transfer ( urls ), Params.Folder );
	else
		LastBook = LastBook - 1;
		checkFinish ();
	endif; 
	
EndProcedure 

&AtServerNoContext
Function getUrls ( val Book, val FormID ) export
	
	files = getTable ( Book );
	i = files.Count () - 1;
	urls = new Array ();
	while ( i >= 0 ) do
		row = files [ i ];
		name = row.Name;
		folder = CKEditorSrv.GetFolder ( row.FolderID ) + "\";
		file = folder + name;
		document = row.Document;
		id = row.ID;
		files.Delete ( i );
		if ( files.Find ( name, "Name" ) <> undefined ) then
			ext = FileSystem.GetExtension ( name );
			baseName = FileSystem.GetBaseName ( name );
			name = baseName + "_" + id + ? ( ext = "", "", "." + ext );
		endif; 
		data = new Structure ( "Name, Address, Document" );
		data.Name = name;
		data.Address = PutToTempStorage ( new BinaryData ( file ), FormID );
		data.Document = document;
		urls.Add ( data );
		i = i - 1;
	enddo; 
	return urls;
	
EndFunction 

&AtServerNoContext
Function getTable ( Book )
	
	s = "
	|select allowed Files.Document as Document, Files.File as Name, Files.ID as ID, Document.FolderID as FolderID
	|from InformationRegister.Files as Files
	|where Files.Document in ( select Ref from Document.Document where Book = &Book and not DeletionMark )
	|";
	q = new Query ( s );
	q.SetParameter ( "Book", Book );
	return q.Execute ().Unload ();
	
EndFunction 

&AtClient
Function transfer ( URLs )
	
	links = new Array ();
	for each item in URLs do
		links.Add ( new TransferableFileDescription ( item.Name, item.Address ) );
	enddo; 
	return links;
	
EndFunction

&AtClient
Procedure FilesDownloaded ( List, Files ) export
	
	LastBook = LastBook - 1;
	Count = Count + List.Count ();
	commitDownloading ( Files );
	checkFinish ();
	
EndProcedure 

&AtServerNoContext
Procedure commitDownloading ( val Files )

	date = CurrentSessionDate ();
	for each file in Files do
		r = InformationRegisters.Downloads.CreateRecordManager ();
		r.User = SessionParameters.User;
		r.Reference = file.Document;
		r.File = file.Name;
		r.Date = date;
		r.Write ();
	enddo; 

EndProcedure 

&AtClient
Procedure checkFinish ()
	
	if ( LastBook = 0 ) then
		Output.DocumentsDownloadingCompleted ( ThisObject, , new Structure ( "Count", Format ( Count, "NZ=" ) ) );
	endif; 

EndProcedure 

&AtClient
Procedure DocumentsDownloadingCompleted ( Params ) export
	
	Close ();
	
EndProcedure 
