#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var AccessBook;
var IsNew;
var OldParent;
var CopiedBook;

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	IsNew = IsNew ();
	setOldParent ();
	if ( not checkAccess () ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

Function checkAccess ()
	
	if ( not SpecialAccess and Parent.IsEmpty () ) then
		Output.BookAccessNotDefined ();
		return false;
	endif; 
	if ( Parent = OldParent ) then
		return true;
	endif; 
	if ( ValueIsFilled ( OldParent )
		and not Catalogs.Books.CanChange ( OldParent ) ) then
		Output.BooksAccessError ();
		return false;
	endif; 
	if ( Parent.IsEmpty () ) then
		if ( not AccessRight ( "InteractiveInsert", Metadata () ) ) then
			Output.BooksAccessError ();
			return false;
		endif; 
	elsif ( not Catalogs.Books.CanChange ( Parent ) ) then
		Output.BooksAccessError ();
		return false;
	endif; 
	return true;
	
EndFunction 

Procedure setOldParent ()
	
	if ( not IsNew ) then
		OldParent = Ref.Parent;
	endif; 
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	SetPrivilegedMode ( true );
	freeze ();	
	if ( DeletionMark ) then
		removeDocuments ();	
	elsif ( AdditionalProperties.Property ( "CopiedBook" ) ) then
		CopiedBook = AdditionalProperties.CopiedBook;
		copyBooks ();
	endif; 
	defineRights ();
	if ( IsNew ) then
		createHierarchy ( Ref, Parent );
	elsif ( Parent <> OldParent ) then
		moveHierarchy ();
	endif; 
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure freeze ()
	
	lockData = new DataLock ();
	lockItem = lockData.Add ( "Catalog.Books");
	lockItem.Mode = DataLockMode.Exclusive;
	lockData.Lock ();
	
EndProcedure 

Procedure removeDocuments ()
	
	table = getDocuments ();
	for each row in table do
		obj = row.Document.GetObject ();
		obj.SetDeletionMark ( true );
	enddo; 
	
EndProcedure 

Function getDocuments ()
	
	s = "
	|select Documents.Ref as Document
	|from Document.Document as Documents
	|	//
	|	// Books
	|	//
	|	join InformationRegister.BooksHierarchy as Books
	|	on Books.Child = Documents.Book
	|	and Books.Father = &Book
	|where not Documents.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Book", Ref );
	return q.Execute ().Unload ();

EndFunction 

Procedure copyBooks ()
	
	array = booksToCopy ();	
	books = new Map ();	
	for each row in array do
		copyBook ( row, books );
	enddo;
	copyDocuments ( books );	
	
EndProcedure 

Function booksToCopy ()
	
	s = "
	|select Books.Ref as Ref
	|from Catalog.Books as Books
	|where not Books.DeletionMark 
	|and Books.Parent in hierarchy ( &Book )
	|order by Books.Sorting asc
	|";
	q = new Query ( s );
	q.SetParameter ( "Book", CopiedBook );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction 

Function copyBook ( Source, Books, Root = undefined )

	if ( Source = CopiedBook ) then
		return Ref;
	endif;
	result = Books [ Source ];
	if ( result = undefined ) then
		book = Source.GetObject();
		target = Catalogs.Books.CreateItem ();
		target.Parent = copyBook ( book.Parent, Books );
		target.Description = book.Description;		
		target.ManualSorting = book.ManualSorting;
		target.SpecialAccess = book.SpecialAccess;
		target.CreationDate = book.CreationDate;
		target.Creator = book.Creator;
		target.Write ();
		result = target.Ref;
		copyEffectiveRights ( Source, result );
		copyUsersAccess ( Source, result );
		copyGroupsAccess ( Source, result );
		Books.Insert ( Source, result );
	endif; 
	return result;
	
EndFunction 

Procedure copyDocuments ( Books )

	table = documentsToCopy ();	
	for each row in table do		
		doc = Documents.Document.CreateDocument ();		
		doc.Date = row.Date;
		doc.Book = copyBook ( row.Book, Books );
		doc.CreationDate = row.CreationDate;
		doc.Creator = row.Creator;
		doc.FolderID = new UUID ();
		doc.Subject = row.Subject;
		doc.Content = row.Content;
		doc.IsEmpty = row.IsEmpty;
		doc.Versioning = row.Versioning;
		doc.Table = row.Table;
		doc.Write ( DocumentWriteMode.Write, DocumentPostingMode.Regular );
		Documents.Document.Copy ( row.Ref, doc.Ref );
		CKEditorSrv.CopyDocument ( row.FolderID, doc.FolderID );
	enddo; 
	
EndProcedure 

Function documentsToCopy ()

	s = "
	|select Documents.Ref as Ref, Documents.Date as Date, Documents.Book as Book, Documents.CreationDate as CreationDate,
	|	Documents.Creator as Creator, Documents.FolderID as FolderID, Documents.Subject as Subject,
	|	Documents.Content as Content, Documents.IsEmpty as IsEmpty, Documents.Versioning as Versioning,
	|	Documents.Table as Table
	|from Document.Document as Documents
	|where not Documents.DeletionMark 
	|and Documents.Book in hierarchy ( &Book )
	|order by Documents.Number asc
	|";
	q = new Query ( s );
	q.SetParameter ( "Book", CopiedBook );
	return q.Execute ().Unload ();

EndFunction

Procedure copyEffectiveRights ( Source, Receiver )
	
	recordset = InformationRegisters.EffectiveRights.CreateRecordSet ();
	recordset.Filter.Book.Set ( Source );
	recordset.Read ();	
	recordset2 = InformationRegisters.EffectiveRights.CreateRecordSet ();
	recordset2.Filter.Book.Set ( Receiver );	
	for each record in recordset do
		record2 = recordset2.Add ();
		FillPropertyValues ( record2, record );				
		record2.Book = Receiver;
	enddo; 
	recordset2.Write ( true );
	
EndProcedure 

Procedure copyGroupsAccess ( Source, Receiver )
	
	recordset = InformationRegisters.GroupsAccessBooks.CreateRecordSet ();
	recordset.Filter.Book.Set ( Source );
	recordset.Read ();	
	recordset2 = InformationRegisters.GroupsAccessBooks.CreateRecordSet ();
	recordset2.Filter.Book.Set ( Receiver );	
	for each record in recordset do
		record2 = recordset2.Add ();
		FillPropertyValues ( record2, record );				
		record2.Book = Receiver;
	enddo; 
	recordset2.Write ( false );
	
EndProcedure 

Procedure copyUsersAccess ( Receiver, Source )
	
	recordset = InformationRegisters.UsersAccessBooks.CreateRecordSet ();
	recordset.Filter.Book.Set ( Source );
	recordset.Read ();	
	recordset2 = InformationRegisters.UsersAccessBooks.CreateRecordSet ();
	recordset2.Filter.Book.Set ( Receiver );	
	for each record in recordset do
		record2 = recordset2.Add ();
		FillPropertyValues ( record2, record );				
		record2.Book = Receiver;
	enddo; 
	recordset2.Write ( false );
	
EndProcedure 

Procedure defineRights ()
	
	setEffectiveRights ();
	applyToChildren ( Ref );
	
EndProcedure 

Procedure setEffectiveRights ()
	
	if ( SpecialAccess ) then
		writeRights ( Ref, Ref );
		AccessBook = Ref;
	else
		folder = Parent;
		while ( true ) do
			if ( folder.IsEmpty () ) then
				break;
			endif; 
			fields = DF.Values ( folder, "Parent as Parent, SpecialAccess" );
			if ( fields.SpecialAccess ) then
				writeRights ( Ref, folder );
				break;
			endif; 
			folder = fields.Parent;
		enddo; 
		AccessBook = folder;
	endif; 
	
EndProcedure

Procedure writeRights ( Book, BookAccess )
	
	r = InformationRegisters.EffectiveRights.CreateRecordManager ();
	r.Book = Book;
	r.AccessBook = BookAccess;
	r.Write ();
	
EndProcedure 

Procedure applyToChildren ( Book )
	
	selection = Catalogs.Books.Select ( Book );
	while ( selection.Next () ) do
		if ( selection.SpecialAccess ) then
			continue;
		endif; 
		writeRights ( selection.Ref, AccessBook );
		applyToChildren ( selection.Ref );
	enddo; 
	
EndProcedure 

Procedure createHierarchy ( Child, Folder )
	
	if ( Folder.IsEmpty () ) then
		bind ( Child, Child );
	else
		parents = getParents ( Child );
		parents.Add ( Child );
		for each father in parents do
			bind ( Child, father );
		enddo; 
	endif; 
	
EndProcedure 

Function getParents ( Child, Grandfather = undefined )
	
	result = new Array ();
	level = Child.Level ();
	if ( level = 0 ) then
		return result;
	endif; 
	j = level;
	s = "";
	parents = "";
	for i = 1 to level do
		s = s + ", " + parents + "Parent as Parent" + j;
		parents = parents + "Parent.";
		j = j - 1;
	enddo;
	data = DF.Values ( Child, Mid ( s, 3 ) );
	i = level;
	while ( i > 0 ) do
		father = data [ "Parent" + i ];
		if ( father = Grandfather ) then
			break;
		endif; 
		result.Add ( father );
		i = i - 1;
	enddo; 
	return result;
	
EndFunction 

Procedure bind ( Child, Father )
	
	r = InformationRegisters.BooksHierarchy.CreateRecordManager ();
	r.Child = Child;
	r.Father = Father;
	r.Write ();
	
EndProcedure 

Procedure moveHierarchy ()
	
	children = getChildren ();
	if ( not OldParent.IsEmpty () ) then
		parents = getParents ( OldParent, Parent );
		parents.Add ( OldParent );
		for each father in parents do
			for each child in children do
				unbind ( child, father );
			enddo; 
		enddo; 
	endif; 
	if ( Parent.IsEmpty () ) then
		return;
	endif; 
	parents = getParents ( Parent );
	parents.Add ( Parent );
	for each father in parents do
		for each child in children do
			bind ( child, father );
		enddo; 
	enddo; 

EndProcedure 

Function getChildren ()
	
	s = "
	|select Books.Child as Child
	|from InformationRegister.BooksHierarchy as Books
	|where Books.Father = &Book
	|";
	q = new Query ( s );
	q.SetParameter ( "Book", Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Child" );
	
EndFunction 

Procedure unbind ( Child, Father )
	
	r = InformationRegisters.BooksHierarchy.CreateRecordManager ();
	r.Child = Child;
	r.Father = Father;
	r.Delete ();
	
EndProcedure 

#endif