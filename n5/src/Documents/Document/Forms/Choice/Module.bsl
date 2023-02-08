&AtClient
var DocumentsRow;
&AtClient
var BooksRow;
&AtClient
var FilesCount;
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
&AtClient
var Sorting;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadShowBooks ();
	initListFixedSettings ();
	restoreCurrentBook ();
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|BooksGroup CurrentBook Sync Sync1 show ShowBooks;
	|ShowBooks press ShowBooks
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure loadShowBooks ()
	
	value = CommonSettingsStorage.Load ( Enum.SettingsShowBooksChoice () );
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
Procedure restoreCurrentBook ()
	
	if ( Parameters.CurrentRow <> undefined ) then
		return;
	endif;
	book = CommonSettingsStorage.Load ( "ChoiceList" + Enum.SettingsCurrentBook () );
	if ( book = undefined
		or book.IsEmpty () ) then
		try
			removed = DF.Pick ( book, "DeletionMark as DeletionMark" )
		except
			removed = true;
		endtry;
		if ( removed ) then
			return;
		endif; 
	endif;
	Items.CurrentBook.ChoiceList.Add ( book );
	CurrentBook = book;
	Items.Bookslist.CurrentRow = book;
	filterByBook ();
	
EndProcedure 

&AtServer
Procedure setOrderByDate ()
	
	DC.RemoveOrder ( DocumentsList, "Sorting" );
	DC.SetOrder ( DocumentsList, "Date desc" );
	
EndProcedure 

&AtServer
Procedure filterByBook ()
	
	filter = not CurrentBook.IsEmpty ();
	if ( filter ) then
		DC.SetParameter ( DocumentsList, "Book", CurrentBook, true );
		setOrderBySorting ();
	else
		DC.SetParameter ( DocumentsList, "Book", undefined, false );
		setOrderByDate ();
	endif; 
	
EndProcedure 

&AtServer
Procedure setOrderBySorting ()
	
	manualSorting = DF.Pick ( CurrentBook, "ManualSorting" );
	if ( manualSorting ) then
		DC.RemoveOrder ( DocumentsList, "Date" );
		DC.SetOrder ( DocumentsList, "Sorting desc" );
	else
		setOrderByDate ();
	endif; 
	
EndProcedure 

// *****************************************
// *********** Table Books

&AtClient
Procedure BooksListOnActivateRow ( Item )
	
	BooksRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure BooksListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	setCurrentBook ();
	filterByBook ();
	
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

&AtClientAtServerNoContext
Procedure applyCurrentBook ( Form, Value )
	
	Form.CurrentBook = Value;
	saveCurrentBook ( Value );
	
EndProcedure 

&AtServerNoContext
Procedure saveCurrentBook ( val Book )
	
	LoginsSrv.SaveSettings ( "ChoiceList" + Enum.SettingsCurrentBook (), , Book );
	
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
	LoginsSrv.SaveSettings ( Enum.SettingsShowBooksChoice (), , ShowBooks );
	if ( not ShowBooks ) then
		applyCurrentBook ( ThisObject, undefined );
		filterByBook ();
	endif; 
	Appearance.Apply ( ThisObject, "ShowBooks" );
	
EndProcedure 

&AtClient
Procedure CurrentBookOnChange ( Item )
	
	filterByBook ();
	
EndProcedure

&AtClient
Procedure DocumentsListOnActivateRow ( Item )
	
	DocumentsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure Sync ( Command )
	
	if ( DocumentsRow = undefined ) then
		return;
	endif; 
	syncDocument ();	
	
EndProcedure

&AtClient
Procedure syncDocument ()
	
	if ( DocumentsRow.Book.IsEmpty () ) then
		Output.BookIsNotDefined ();
	else
		Items.BooksList.CurrentRow = DocumentsRow.Book;
	endif; 
	
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
	OpenForm ( "Document.Document.ObjectForm", new Structure ( "FillingValues", values ), ThisObject );
	
EndProcedure 
