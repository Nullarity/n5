&AtClient
var DocumentsRow;
&AtClient
var BooksRow;
&AtClient
var FilesCount;
&AtClient
var FoldersCount;
&AtClient
var FilesIndex;
&AtClient
var FilesTotal;
&AtClient
var FilesList;
&AtClient
var FilesBook;
&AtClient
var CurrentFile;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( not SessionParameters.TenantUse ) then
		Cancel = true;
		return;
	endif;
	if ( Forms.InsideMobileHomePage ( ThisObject ) ) then
		Cancel = true;
		return;
	endif;
	definePurpose ();
	setQuery ();
	UserTasks.InitList ( DocumentsList );
	loadShowBooks ();
	initListFixedSettings ();
	restoreShowRemoved ();
	restoreShowFiles ();
	restoreShowTags ();
	restoreSortByBooks ();
	restoreBooksManualSort ();
	restoreCurrentBook ();
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|BooksGroup FindBook FindBook1 MoveDocumentUp MoveDocumentDown MoveDocumentUp1 MoveDocumentDown1 show ShowBooks;
	|ShowBooks ShowBooks1 press ShowBooks;
	|ShowRemoved ShowRemoved1 press ShowRemoved;
	|ShowFiles DocumentsListContextMenuShowFiles press ShowFiles;
	|ShowTags DocumentsListContextMenuShowTags press ShowTags;
	|SortByBooks DocumentsListContextMenuSortByBooks press SortByBooks and ShowBooks;
	|SortByBooks DocumentsListContextMenuSortByBooks show ShowBooks;
	|Files show ShowFiles;
	|Tags show ShowTags;
	|BooksManualSort press BooksManualSort;
	|MoveUp MoveDown MoveUp1 MoveDown1 show BooksManualSort;
	|Book show not SortByBooks;
	|CurrentBook show ShowBooks and not SortByBooks;
	|AttachObject show filled ( EmbeddedIn )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure definePurpose ()
	
	Parameters.Filter.Property ( "Object", EmbeddedIn );
	if ( EmbeddedIn = undefined ) then
		PurposeKey = "Regular";
	else
		PurposeKey = EmbeddedIn.Metadata ().FullName ();
	endif; 
	PurposeUseKey = PurposeKey;
	
EndProcedure 

&AtServer
Procedure setQuery ()
	
	//
	// Instead of DocumentList query, this query is used to avoid "Parameter Sniffing" effect for a big databases
	//
	s = "
	|select allowed Documents.Ref, Documents.DeletionMark, Documents.Number, Documents.Date, Documents.Posted, Documents.Book,
	|	Documents.Content, Documents.CreationDate, Documents.Creator, Documents.FolderID, Documents.IsEmpty, Documents.Subject,
	|	Documents.Versioning, Documents.PointInTime, SuperTags.Tags as Tags, Documents.Link as Link, Documents.Object as Object,
	|	case when Documents.DeletionMark then 77 else isnull ( AttachmentsCount.Extension, -1 ) end as ExtentionPicture,
	|	case when History.Date is null then
	|			case when datediff ( Documents.Date, &Today, month ) > 12 then false else true end
	|		when History.Date > Documents.Date then false
	|		else true
	|	end New,
	|	case when DocumentStatuses.Status = value ( Enum.DocumentStatuses.Published ) then 0 else 1 end DocumentStatus,
	|	DocumentsSorting.Sorting as Sorting, DocumentStatuses.Status as Status, FileNames.Files as Files,
	|	TasksList.Progress as TaskProgress, TasksList.Completed as TaskCompleted, TasksList.Status as TaskStatus, TasksList.Task as TaskRef, 
	|	TasksList.Observation as Observation
	|from Document.Document as Documents
	|	//
	|	// FileNames
	|	//
	|	left join InformationRegister.FileNames as FileNames
	|	on FileNames.Document = Documents.Ref
	|	//
	|	// Tags
	|	//
	|	left join InformationRegister.SuperTags as SuperTags
	|	on SuperTags.Document = Documents.Ref
	|	//
	|	// ReadingHistory
	|	//
	|	left join InformationRegister.ReadingHistory as History
	|	on History.Document = Documents.Ref
	|	and History.User = &User
	|	//
	|	// AttachmentsCount
	|	//
	|	left join InformationRegister.AttachmentsCount as AttachmentsCount
	|	on AttachmentsCount.Reference = Documents.Ref
	|	//
	|	// DocumentStatuses
	|	//
	|	left join InformationRegister.DocumentStatuses as DocumentStatuses
	|	on DocumentStatuses.Document = Documents.Ref
	|	//
	|	// DocumentsSorting
	|	//
	|	left join InformationRegister.DocumentsSorting as DocumentsSorting
	|	on DocumentsSorting.Document = Documents.Ref
	|	//
	|	// Tasks
	|	//
	|	left join InformationRegister.Tasks as TasksList
	|	on TasksList.Source = Documents.Ref
	|	and TasksList.User = &Performer
	|";
	filter = not CurrentBook.IsEmpty ();
	if ( filter ) then
		code = DF.Pick ( CurrentBook, "Code" );
		if ( SortByBooks ) then
			s = s + "
			|where Documents.Book.Code = """ + code + """
			|";
		else
			s = s + "
			|	//
			|	// Books
			|	//
			|	join InformationRegister.BooksHierarchy as Books
			|	on Books.Child = Documents.Book
			|	and Books.Father.Code = """ + code + """
			|";
		endif; 
		setOrderBySorting ();
	else
		setOrderByDate ();
	endif; 
	DocumentsList.QueryText = s;

EndProcedure 

&AtServer
Procedure setOrderBySorting ()
	
	manualSorting = DF.Pick ( CurrentBook, "ManualSorting" );
	if ( manualSorting ) then
		DocumentsList.Order.Items.Clear ();
		DC.SetOrder ( DocumentsList, "Book" );
		DC.SetOrder ( DocumentsList, "Sorting desc" );
	else
		setOrderByDate ();
	endif; 
	
EndProcedure 

&AtServer
Procedure setOrderByDate ()
	
	DocumentsList.Order.Items.Clear ();
	DC.SetOrder ( DocumentsList, "Date desc" );
	
EndProcedure 

&AtServer
Procedure loadShowBooks ()
	
	value = CommonSettingsStorage.Load ( PurposeKey + Enum.SettingsShowBooks () );
	if ( value = undefined ) then
		ShowBooks = false;
	else
		ShowBooks = value;
	endif; 
	
EndProcedure 

&AtServer
Procedure initListFixedSettings ()
	
	DC.SetParameter ( DocumentsList, "User", SessionParameters.User, true );
	DC.SetParameter ( DocumentsList, "Today", CurrentSessionDate (), true );

EndProcedure 

&AtServer
Procedure restoreShowRemoved ()
	
	ShowRemoved = CommonSettingsStorage.Load ( Enum.SettingsDocumentsShowRemoved () );
	filterByDeletionMark ();
	
EndProcedure 

&AtServer
Procedure filterByDeletionMark ()
	
	if ( ShowRemoved ) then
		DC.ChangeFilter ( DocumentsList, "DeletionMark", undefined, false );
		DC.ChangeFilter ( BooksList, "DeletionMark", undefined, false );
	else
		DC.ChangeFilter ( DocumentsList, "DeletionMark", false, true );
		DC.ChangeFilter ( BooksList, "DeletionMark", false, true );
	endif; 
	
EndProcedure 

&AtServer
Procedure restoreShowFiles ()
	
	value = CommonSettingsStorage.Load ( Enum.SettingsDocumentsShowFiles () );
	ShowFiles = ? ( value = undefined, true, value );
	
EndProcedure 

&AtServer
Procedure restoreShowTags ()
	
	value = CommonSettingsStorage.Load ( Enum.SettingsDocumentsShowTags () );
	ShowTags = ? ( value = undefined, true, value );
	
EndProcedure 

&AtServer
Procedure restoreSortByBooks ()
	
	value = CommonSettingsStorage.Load ( Enum.SettingsDocumentsSortByBooks () );
	SortByBooks = ? ( value = undefined, false, value );
	
EndProcedure 

&AtServer
Procedure restoreBooksManualSort ()
	
	value = CommonSettingsStorage.Load ( Enum.SettingsDocumentsBooksManualSort () );
	BooksManualSort = ? ( value = undefined, false, value );
	sortBooks ();
	
EndProcedure 

&AtServer
Procedure sortBooks ()
	
	BooksList.Order.Items.Clear ();
	if ( BooksManualSort ) then
		DC.SetOrder ( BooksList, "Sorting" );
	else
		DC.SetOrder ( BooksList, "Description" );
	endif; 
	
EndProcedure 

&AtServer
Procedure restoreCurrentBook ()
	
	document = Parameters.CurrentRow;
	if ( document = undefined ) then
		book = CommonSettingsStorage.Load ( PurposeKey + Enum.SettingsCurrentBook () );
	else
		book = DF.Pick ( document, "Book" );
	endif;
	if ( book = undefined
		or book.IsEmpty () ) then
		try
			removed = DF.Pick ( book, "DeletionMark as DeletionMark" )
		except
			removed = true;
		endtry;
		if ( removed ) then
			setOrderByDate ();
			return;
		endif; 
	endif;
	Items.CurrentBook.ChoiceList.Add ( book );
	CurrentBook = book;
	Items.Bookslist.CurrentRow = book;
	setQuery ();
	BookActivated = true;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( DocumentsFindBook <> undefined ) then
		syncExternalBook ();
	endif;
	
EndProcedure

&AtClient
Procedure syncExternalBook ()
	
	applyCurrentBook ( ThisObject, DocumentsFindBook );
	setQuery ();
	Items.BooksList.CurrentRow = CurrentBook;
	DocumentsFindBook = undefined;
	
EndProcedure 

&AtClientAtServerNoContext
Procedure applyCurrentBook ( Form, Value )
	
	Form.CurrentBook = Value;
	saveCurrentBook ( Value, Form.PurposeKey );
	
EndProcedure 

&AtServerNoContext
Procedure saveCurrentBook ( val Book, val PurposeKey )
	
	LoginsSrv.SaveSettings ( PurposeKey + Enum.SettingsCurrentBook (), , Book );
	
EndProcedure 

&AtClient
Procedure OnReopen ()
	
	if ( DocumentsCurrentRow <> undefined ) then
		syncExternalDocument ();
	elsif ( DocumentsFindBook <> undefined ) then
		syncExternalBook ();
	endif; 
	
EndProcedure

&AtClient
Procedure syncExternalDocument ()
	
	applyCurrentBook ( ThisObject, DF.Pick ( DocumentsCurrentRow, "Book" ) );
	setQuery ();
	Items.DocumentsList.CurrentRow = DocumentsCurrentRow;
	Items.BooksList.CurrentRow = CurrentBook;
	DocumentsCurrentRow = undefined;
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.BooksActivate ()
		and Source = ThisObject ) then
		activateBook ( Parameter );
	endif; 
	
EndProcedure

&AtClient
Procedure activateBook ( Book )
	
	if ( not ShowBooks
		or Book.IsEmpty () ) then
		return;
	endif; 
	Items.BooksList.CurrentRow = Book;
	setCurrentBook ();
	setQuery ();
	
EndProcedure 

// *****************************************
// *********** Table Books

&AtClient
Procedure LoadFolder ( Command )
	
	openLoadForm ( selectedBook () );
	
EndProcedure

&AtClient
Function selectedBook ()
	
	return ? ( BooksRow = undefined, undefined, BooksRow.Ref );
	
EndFunction 

&AtClient
Procedure openLoadForm ( Book, Folder = undefined )
	
	p = new Structure ();
	p.Insert ( "Folder", Folder );
	p.Insert ( "EmbeddedIn", EmbeddedIn );
	p.Insert ( "Book", Book );
	OpenForm ( "Document.Document.Form.LoadFolder", p, ThisObject );
	
EndProcedure 

&AtClient
Procedure DownloadBook ( Command )
	
	openDownloadForm ();
	
EndProcedure

&AtClient
Procedure openDownloadForm ()
	
	p = new Structure ( "Book", selectedBook () );
	OpenForm ( "Document.Document.Form.DownloadBook", p );
	
EndProcedure 

&AtClient
Procedure LoadFiles ( Command )
	
	LocalFiles.Prepare ( new NotifyDescription ( "СhooseFiles", ThisObject ) );
	
EndProcedure

&AtClient
Procedure СhooseFiles ( Result, Params ) export
	
	dialog = new FileDialog ( FileDialogMode.Open );
	dialog.Multiselect = true;
	dialog.Show ( new NotifyDescription ( "SelectFiles", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure SelectFiles ( Files, Params ) export
	
	if ( Files = undefined ) then
		return;
	endif; 
	resetVars ( Files, selectedBook () );
	uploadFile ();
	
EndProcedure 

&AtClient
Procedure resetVars ( Files, Book )
	
	FilesCount = Files.Count ();
	FoldersCount = 0;
	FilesIndex = 0;
	FilesList = Files;
	FilesBook = Book;

EndProcedure 

&AtClient
Procedure uploadFile ()
	
	if ( FilesIndex = FilesCount ) then
		actual = FilesCount - FoldersCount;
		if ( actual > 0 ) then
			Output.DocumentsLoadingCompleted ( ThisObject, , new Structure ( "Count", Format ( actual, "NZ=" ) ) );
		endif; 
	else
		CurrentFile = FilesList [ FilesIndex ];
		FilesIndex = FilesIndex + 1;
		file = new File ( CurrentFile );
		file.BeginCheckingIsDirectory ( new NotifyDescription ( "CheckIfFolder", ThisObject ) );
	endif;
	
EndProcedure 

&AtClient
Procedure CheckIfFolder ( Folder, Params ) export
	
	if ( Folder ) then
		FoldersCount = FoldersCount + 1;
		openLoadForm ( FilesBook, CurrentFile );
		uploadFile ();
	else
		files = new Array ();
		files.Add ( new TransferableFileDescription ( CurrentFile ) );
		BeginPuttingFiles ( new NotifyDescription ( "Loading", ThisObject ), files, , false );
	endif; 
	
EndProcedure 

&AtClient
Procedure Loading ( Result, Params ) export
	
	file = Result [ 0 ];
	newDocument ( file.Location, file.Name, FilesBook, EmbeddedIn );
	Output.DocumentLoaded ( new Structure ( "Name", file.Name ) );
	uploadFile ();
	
EndProcedure 

&AtServerNoContext
Procedure newDocument ( val Address, val Path, val CurrentBook, val EmbeddedIn )
	
	fileName = FileSystem.GetFileName ( Path );
	name = FileSystem.GetBaseName ( fileName );
	Documents.Document.Create ( Address, name, fileName, CurrentBook, EmbeddedIn );
	
EndProcedure 

&AtClient
Procedure DocumentsLoadingCompleted ( Result ) export
	
	NotifyChanged ( Type ( "DocumentRef.Document" ) );
	
EndProcedure 

&AtClient
Procedure BooksListDragCheck ( Item, DragParameters, StandardProcessing, Row, Field )
	
	#if ( WebClient ) then
		// 8.3.6.2041 Bugworkaroud.
		// I need to reset StandardProcessing in order to continue dragging process
		StandardProcessing = false;
	#endif

EndProcedure

&AtClient
Procedure BooksListDrag ( Item, DragParameters, StandardProcessing, Row, Field )
	
	value = DragParameters.Value;
	valueType = TypeOf ( value );
	fileType = Type ( "File" );
	documentType = Type ( "DocumentRef.Document" );
	if ( valueType = Type ( "Array" ) ) then
		itemType = TypeOf ( value [ 0 ] );
		if ( itemType = documentType ) then
			StandardProcessing = false;
			moveDocuments ( Row, value );
			NotifyChanged ( documentType );
		elsif ( itemType = fileType ) then
			StandardProcessing = false;
			dragFiles ( DragParameters, Row );
		endif;
	elsif ( valueType = fileType ) then
		StandardProcessing = false;
		dragFiles ( DragParameters, Row );
	endif; 

EndProcedure

&AtServerNoContext
Procedure moveDocuments ( val Book, val Docs )
	
	for each document in Docs do
		obj = document.GetObject ();
		obj.Book = Book;
		obj.Write ();
	enddo; 
	
EndProcedure 

&AtClient
Procedure dragFiles ( Params, Book )
	
	resetVars ( getPaths ( Params.Value ), Book );
	uploadFile ();
	
EndProcedure 

&AtClient
Function getPaths ( Dragged )
	
	files = new Array ();
	if ( TypeOf ( Dragged ) = Type ( "Array" ) ) then
		for each item in Dragged do
			files.Add ( item.FullName );
		enddo; 
	else
		files.Add ( Dragged.FullName );
	endif; 
	return files;
	
EndFunction 

&AtClient
Procedure BooksListOnActivateRow ( Item )
	
	BooksRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure BooksListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	setCurrentBook ();
	setQuery ();
	
EndProcedure

&AtClient
Procedure setCurrentBook ()
	
	book = BooksRow.Ref;
	list = Items.CurrentBook.ChoiceList;
	limit = 10;
	count = list.Count ();
	if ( count > 0 and list [ 0 ].Value = book ) then
		applyCurrentBook ( ThisObject, book );
		return;
	endif; 
	list.Insert ( 0, book );
	applyCurrentBook ( ThisObject, book );
	if ( count > limit ) then
		i = count;
		while ( i > limit ) do
			list.Delete ( i );
			i = i - 1;
		enddo; 
	endif; 
	
EndProcedure 

&AtClient
Procedure MoveUp ( Command )
	
	shiftBook ( -1 );
	
EndProcedure

&AtClient
Procedure shiftBook ( Direction )
	
	if ( BooksRow = undefined ) then
		return;
	endif; 
	if ( moveBook ( BooksRow.Ref, Direction ) ) then
		NotifyChanged ( BooksRow.Ref );
	endif;
	
EndProcedure 

&AtServerNoContext
Function moveBook ( val Book, val Direction )
	
	if ( Catalogs.Books.CanChange ( Book )
		and Catalogs.Books.CanChange ( DF.Pick ( Book, "Parent" ) ) ) then
		return changePosition ( Book, Direction );
	else
		Output.BooksAccessError ();
		return false;
	endif; 
	
EndFunction

&AtServerNoContext
Function changePosition ( Book, Direction )
	
	SetPrivilegedMode ( true );
	s = "
	|select top 1 Books1.Ref as Book, Books1.Sorting as Sorting, Books2.Sorting as OldSorting
	|from Catalog.Books as Books1
	|	//
	|	// Books2
	|	//
	|	join Catalog.Books as Books2
	|	on Books2.Ref = &Ref
	|	and Books2.Sorting " + ? ( Direction = 1, "<", ">" ) + "Books1.Sorting
	|	and Books2.Parent = Books1.Parent
	|where not Books1.DeletionMark
	|order by Books1.Sorting " + ? ( Direction = 1, "asc", "desc" ) + "
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Book );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		return false;
	endif; 
	data = table [ 0 ];
	obj1 = Book.GetObject ();
	obj1.Sorting = data.Sorting;
	obj2 = data.Book.GetObject ();
	obj2.Sorting = data.OldSorting;
	BeginTransaction ();
	obj1.Write ();
	obj2.Write ();
	CommitTransaction ();
	SetPrivilegedMode ( false );
	return true;
	
EndFunction 

&AtClient
Procedure MoveDown ( Command )
	
	shiftBook ( 1 );
	
EndProcedure

// *****************************************
// *********** Table DocumentsList

&AtClient
Procedure ShowBooks ( Command )
	
	applyShowBooks ();
	
EndProcedure

&AtServer
Procedure applyShowBooks ()
	
	ShowBooks = not ShowBooks;
	LoginsSrv.SaveSettings ( PurposeKey + Enum.SettingsShowBooks (), , ShowBooks );
	if ( not ShowBooks ) then
		applyCurrentBook ( ThisObject, undefined );
		setSortByBooks ( false );
		setQuery ();
		Appearance.Apply ( ThisObject, "SortByBooks" );
	endif; 
	Appearance.Apply ( ThisObject, "ShowBooks" );
	
EndProcedure 

&AtServer
Procedure setSortByBooks ( Value )
	
	SortByBooks = Value;
	LoginsSrv.SaveSettings ( Enum.SettingsDocumentsSortByBooks (), , Value );
	
EndProcedure 

&AtClient
Procedure AttachObject ( Command )
	
	p = new Structure ( "MultipleChoice", true );
	OpenForm ( "Document.Document.ChoiceForm", p, ThisObject, , , , new NotifyDescription ( "DocumentSelected", ThisObject ) );
	
EndProcedure

&AtClient
Procedure DocumentSelected ( List, Params ) export
	
	if ( List = undefined ) then
		return;
	endif; 
	bindDocuments ( EmbeddedIn, List );
	for each item in List do
		NotifyChanged ( item );
	enddo; 
	
EndProcedure 

&AtServerNoContext
Procedure bindDocuments ( val EmbeddedIn, val List )
	
	msg = new Structure ( "Object" );
	for each item in List do
		if ( Documents.Document.CanChange ( item ) ) then
			obj = item.GetObject ();
			obj.Object = EmbeddedIn;
			obj.Write ();
		else
			msg.Object = item;
			Output.LinkAccessError ( msg );
		endif; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure BooksManualSort ( Command )
	
	applyManualSort ();
	
EndProcedure

&AtServer
Procedure applyManualSort ()
	
	BooksManualSort = not BooksManualSort;
	LoginsSrv.SaveSettings ( Enum.SettingsDocumentsBooksManualSort (), , BooksManualSort );
	sortBooks ();
	Appearance.Apply ( ThisObject, "BooksManualSort" );
	
EndProcedure 

&AtClient
Procedure ShowRemoved ( Command )
	
	applyShowRemoved ();
	
EndProcedure

&AtServer
Procedure applyShowRemoved ()
	
	ShowRemoved = not ShowRemoved;
	LoginsSrv.SaveSettings ( Enum.SettingsDocumentsShowRemoved (), , ShowRemoved );
	filterByDeletionMark ();
	Appearance.Apply ( ThisObject, "ShowRemoved" );
	
EndProcedure 

&AtClient
Procedure ShowFiles ( Command )
	
	applyShowFiles ();
	
EndProcedure

&AtServer
Procedure applyShowFiles ()
	
	ShowFiles = not ShowFiles;
	LoginsSrv.SaveSettings ( Enum.SettingsDocumentsShowFiles (), , ShowFiles );
	Appearance.Apply ( ThisObject, "ShowFiles" );
	
EndProcedure 

&AtClient
Procedure ShowTags ( Command )
	
	applyShowTags ();
	
EndProcedure

&AtServer
Procedure applyShowTags ()
	
	ShowTags = not ShowTags;
	LoginsSrv.SaveSettings ( Enum.SettingsDocumentsShowTags (), , ShowTags );
	Appearance.Apply ( ThisObject, "ShowTags" );
	
EndProcedure 

&AtClient
Procedure SortByBooks ( Command )
	
	applySortByBooks ();
	
EndProcedure

&AtServer
Procedure applySortByBooks ()
	
	setSortByBooks ( not SortByBooks );
	setQuery ();
	Appearance.Apply ( ThisObject, "SortByBooks" );
	
EndProcedure 

&AtClient
Procedure OpenAttachment ( Command )
	
	if ( DocumentsRow = undefined ) then
		return;
	endif; 
	perform ( Enum.AttachmentsCommandsRun () );
	
EndProcedure

&AtClient
Procedure perform ( Command )
	
	p = Attachments.GetParams ();
	p.Command = Command;
	p.Ref = DocumentsRow.Ref;
	Attachments.Command ( p );
	
EndProcedure 

&AtClient
Procedure DownloadFile ( Command )

	if ( DocumentsRow = undefined ) then
		return;
	endif; 
	perform ( Enum.AttachmentsCommandsDownload () );

EndProcedure

&AtClient
Procedure DownloadAllFiles ( Command )
	
	if ( DocumentsRow = undefined ) then
		return;
	endif; 
	perform ( Enum.AttachmentsCommandsDownloadAll () );
	
EndProcedure

&AtClient
Procedure PrintAttachment ( Command )
	
	if ( DocumentsRow = undefined ) then
		return;
	endif; 
	perform ( Enum.AttachmentsCommandsPrint () );
	
EndProcedure

&AtClient
Procedure UpdateDocument ( Command )
	
	if ( DocumentsRow = undefined
		or not canChange () ) then
		return;
	endif; 
	p = new Structure ( "Key, Command", DocumentsRow.Ref, Enum.DocumentCommandsUpdateFiles () );
	OpenForm ( "Document.Document.ObjectForm", p );
	
EndProcedure

&AtClient
Function canChange ()
	
	allow = access ( DocumentsRow.Ref );
	if ( not allow ) then
		Output.CannotUpdateDocument ();
	endif; 
	return allow;
	
EndFunction 

&AtServerNoContext
Function access ( val Document )
	
	return Documents.Document.CanChange ( Document );
	
EndFunction 

&AtClient
Procedure CurrentBookOnChange ( Item )
	
	setQuery ();
	
EndProcedure

&AtClient
Procedure DocumentsListDragStart ( Item, DragParameters, Perform )
	
	DragParameters.AllowedActions = DragAllowedActions.Move;
	
EndProcedure

&AtClient
Procedure DocumentsListDragCheck ( Item, DragParameters, StandardProcessing, Row, Field )
	
	StandardProcessing = false;
	if ( not draggedFile ( DragParameters ) ) then
		DragParameters.Action = DragAction.Cancel;
	endif; 
	
EndProcedure

&AtClient
Function draggedFile ( DragParameters )
	
	value = DragParameters.Value;
	valueType = TypeOf ( value );
	fileType = Type ( "File" );
	if ( valueType = Type ( "Array" ) ) then
		return fileType = TypeOf ( value [ 0 ] );
	else
		return fileType = valueType;
	endif;
		
EndFunction

&AtClient
Procedure DocumentsListDrag ( Item, DragParameters, StandardProcessing, Row, Field )
	
	// Platform 8.3.8.2088, webclient error workaround:
	// In some cases Drag event is generated during fast mouse clicking on the DocumentsList
	#if ( not WebClient ) then
		StandardProcessing = false;
		dragFiles ( DragParameters, selectedBook () );
	#endif
	
EndProcedure

&AtClient
Procedure DocumentsListOnActivateRow ( Item )
	
	DocumentsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure DocumentsListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	StandardProcessing = false;
	openDocument ();
	
EndProcedure

&AtClient
Procedure openDocument ()
	
	p = new Structure ( "RefreshList, Key", DocumentsRow.New, DocumentsRow.Ref );
	OpenForm ( "Document.Document.ObjectForm", p );
	
EndProcedure 

&AtClient
Procedure FindBook ( Command )
	
	if ( DocumentsRow = undefined ) then
		return;
	endif; 
	locateBook ();	
	
EndProcedure

&AtClient
Procedure locateBook ()
	
	if ( DocumentsRow.Book.IsEmpty () ) then
		Output.BookIsNotDefined ();
	else
		Items.BooksList.CurrentRow = DocumentsRow.Book;
	endif; 
	
EndProcedure 

&AtClient
Procedure MoveDocumentUp ( Command )
	
	shiftDocument ( 1 );
	
EndProcedure

&AtClient
Procedure shiftDocument ( Direction )
	
	if ( DocumentsRow = undefined ) then
		return;
	endif; 
	if ( CurrentBook.IsEmpty () ) then
		Output.SelectBookFirst ();
		return;
	endif; 
	if ( moveDocument ( DocumentsRow.Ref, Direction ) ) then
		NotifyChanged ( DocumentsRow.Ref );
	endif; ;
	
EndProcedure 

&AtServerNoContext
Function moveDocument ( val Document, val Direction )
	
	SetPrivilegedMode ( true );
	if ( not manualSorting ( Document ) ) then
		return false;
	endif; 
	s = "
	|select top 1 Documents1.Document as Document, Documents1.Sorting as Sorting, Documents2.Sorting as OldSorting
	|from InformationRegister.DocumentsSorting as Documents1
	|	//
	|	// Documents2
	|	//
	|	join InformationRegister.DocumentsSorting as Documents2
	|	on Documents2.Document = &Ref
	|	and Documents2.Sorting " + ? ( Direction = 1, "<", ">" ) + "Documents1.Sorting
	|	and Documents2.Document.Book = Documents1.Document.Book
	|where not Documents1.Document.DeletionMark
	|order by Documents1.Sorting " + ? ( Direction = 1, "asc", "desc" ) + "
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Document );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		return false;
	endif; 
	data = table [ 0 ];
	rm1 = InformationRegisters.DocumentsSorting.CreateRecordManager ();
	rm1.Document = Document;
	rm1.Sorting = data.Sorting;
	rm2 = InformationRegisters.DocumentsSorting.CreateRecordManager ();
	rm2.Document = data.Document;
	rm2.Sorting = data.OldSorting;
	BeginTransaction ();
	rm1.Write ();
	rm2.Write ();
	CommitTransaction ();
	SetPrivilegedMode ( false );
	return true;
	
EndFunction

&AtServerNoContext
Function manualSorting ( Document )
	
	data = DF.Values ( Document, "Book as Book, Book.ManualSorting as ManualSorting" );
	if ( not data.ManualSorting ) then
		Output.ManualSortingOff ( new Structure ( "Book", data.Book ), , data.Book );
	endif; 
	return data.ManualSorting;
	
EndFunction 

&AtClient
Procedure MoveDocumentDown ( Command )
	
	shiftDocument ( -1 );

EndProcedure

&AtClient
Procedure DocumentsListBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	if ( Clone ) then
		return;
	endif;
	Cancel = true;
	openNew ();
	
EndProcedure

&AtClient
Procedure openNew ()
	
	values = new Structure ();
	values.Insert ( "Book", CurrentBook );
	values.Insert ( "Object", EmbeddedIn );
	OpenForm ( "Document.Document.ObjectForm", new Structure ( "FillingValues", values ), Items.DocumentsList );
	
EndProcedure 
