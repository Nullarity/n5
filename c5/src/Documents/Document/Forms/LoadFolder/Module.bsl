&AtClient
var Count;
&AtClient
var Folders;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	applyParams ();
	
EndProcedure

&AtServer
Procedure applyParams ()
	
	Book = Parameters.Book;
	directory = Parameters.Folder;
	if ( directory <> "" ) then
		Folder = directory;
	endif; 

EndProcedure 

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer ( Settings )
	
	directory = Parameters.Folder;
	if ( directory <> "" ) then
		Settings [ "Folder" ] = directory;
	endif; 
	
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
	LocalFiles.Prepare ( new NotifyDescription ( "OpenDialog", ThisObject ) );
	
EndProcedure

&AtClient
Procedure OpenDialog ( Result, Params ) export
	
	dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
	dialog.Show ( new NotifyDescription ( "SelectFolder", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure SelectFolder ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	Folder = Result [ 0 ];
	
EndProcedure 

&AtClient
Procedure Load ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif; 
	resetVars ();
	p = new Structure ( "Current, Parent" );
	if ( CreateBook ) then
		p.Current = newBook ( FileSystem.GetFileName ( Folder ), Book );
	else
		p.Current = Book;
	endif; 
	loadFolder ( Folder, p );
	
EndProcedure

&AtClient
Procedure resetVars ()
	
	Count = 0;
	Folders = new Map ();
	
EndProcedure 

&AtServerNoContext
Function newBook ( val Name, val CurrentBook ) export
	
	specialAccess = CurrentBook.IsEmpty ();
	book = Catalogs.Books.CreateItem ();
	book.Description = Name;
	book.Creator = SessionParameters.User;
	book.Sorting = Catalogs.Books.GetSorting ();
	book.CreationDate = CurrentSessionDate ();
	if ( specialAccess ) then
		book.SpecialAccess = true;
	else
		book.Parent = CurrentBook;
	endif; 
	book.Write ();
	if ( specialAccess ) then
		setBookAccess ( book );
	endif; 
	return book.Ref;
	
EndFunction 

&AtServerNoContext
Procedure setBookAccess ( Book )
	
	r = InformationRegisters.UsersAccessBooks.CreateRecordManager ();
	r.User = Book.Creator;
	r.Book = Book.Ref;
	r.Read = true;
	r.Write = true;
	r.Write ();
	r = InformationRegisters.GroupsAccessBooks.CreateRecordManager ();
	r.UserGroup = Catalogs.UserGroupsDocuments.Everybody;
	r.Book = Book.Ref;
	r.Read = true;
	r.Write ();
		
EndProcedure 

&AtClient
Procedure loadFolder ( Path, Books )
	
	BeginFindingFiles ( new NotifyDescription ( "BeginLoading", ThisObject, Books ), Path, "*" );
	
EndProcedure 

&AtClient
Procedure BeginLoading ( Files, Books ) export
	
	p = new Structure ();
	p.Insert ( "Parent", Books.Parent );
	p.Insert ( "Files", Files );
	p.Insert ( "Count", Files.Count () );
	p.Insert ( "Index", 0 );
	Folders [ Books.Current ] = p;
	loadingLoop ( Books );

EndProcedure 

&AtClient
Procedure loadingLoop ( Books )
	
	files = Folders [ Books.Current ];
	index = files.Index;
	if ( index = files.Count ) then
		p = new Structure ();
		if ( Books.Parent = undefined ) then
			p.Insert ( "Count", Format ( Count, "NZ=" ) );
			Output.DocumentsLoadingCompleted ( ThisObject, Books.Current, p );
		else
			p.Insert ( "Current", Books.Parent );
			p.Insert ( "Parent", Folders [ Books.Parent ].Parent );
			loadingLoop ( p );
		endif; 
	else
		file = files.Files [ index ];
		files.Index = index + 1;
		p = new Structure ();
		p.Insert ( "Current", Books.Current );
		p.Insert ( "Parent", Books.Parent );
		p.Insert ( "Name", file.BaseName );
		p.Insert ( "File", file.Name );
		p.Insert ( "Path", file.FullName );
		file.BeginCheckingIsDirectory ( new NotifyDescription ( "CheckingFolder", ThisObject, p ) );
	endif; 
	
EndProcedure 

&AtClient
Procedure CheckingFolder ( IsFolder, Params ) export
	
	if ( IsFolder ) then
		books = new Structure ( "Current, Parent" );
		books.Parent = Params.Current;
		books.Current = newBook ( Params.File, Params.Current );
		loadFolder ( Params.Path, books );
	else
		loadFile ( Params );
	endif; 
	
EndProcedure 

&AtClient
Procedure loadFile ( File )
	
	files = new Array ();
	files.Add ( new TransferableFileDescription ( File.Path ) );
	p = new Structure ();
	p.Insert ( "Name", File.Name );
	p.Insert ( "File", File.File );
	p.Insert ( "Current", File.Current );
	p.Insert ( "Parent", File.Parent );
	BeginPuttingFiles ( new NotifyDescription ( "Loading", ThisObject, p ), files, , false );
	
EndProcedure 

&AtClient
Procedure Loading ( Result, Params ) export
	
	newDocument ( Result [ 0 ].Location, Params.Name, Params.File, Params.Current, Parameters.EmbeddedIn );
	Count = Count + 1;
	Output.DocumentLoaded ( new Structure ( "Name", Params.Name ) );
	books = new Structure ();
	books.Insert ( "Current", Params.Current );
	books.Insert ( "Parent", Params.Parent );
	loadingLoop ( books );
	
EndProcedure 

&AtServerNoContext
Procedure newDocument ( val Address, val Name, val File, val CurrentBook, val EmbeddedIn )
	
	Documents.Document.Create ( Address, Name, File, CurrentBook, EmbeddedIn );
	
EndProcedure 

&AtClient
Procedure DocumentsLoadingCompleted ( CurrentBook ) export
	
	NotifyChanged ( Type ( "CatalogRef.Books" ) );
	NotifyChanged ( Type ( "DocumentRef.Document" ) );
	Notify ( Enum.BooksActivate (), CurrentBook, FormOwner );
	Close ();
	
EndProcedure 
