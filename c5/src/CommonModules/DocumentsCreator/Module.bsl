Procedure Change ( Creator, Book ) export
	
	table = getTable ( Book );
	BeginTransaction ();
	for each row in table do
		obj = row.Document.GetObject ();
		record = InformationRegisters.UsersAccess.CreateRecordManager ();
		record.User = obj.Creator;
		record.Document = obj.Ref;
		record.Read ();
		if ( record.Selected () ) then
			record.User = Creator;
			record.Write ();
		endif; 
		obj.DataExchange.Load = true;
		obj.Creator = Creator;
		obj.Write ();
	enddo; 
	CommitTransaction ();
	
EndProcedure 

Function getTable ( Book )
	s = "
	|select Books.Ref as Book
	|into Books
	|from Catalog.Books as Books
	|where Books.Ref in hierarchy ( &Book )
	|and not Books.DeletionMark
	|;
	|select Documents.Ref as Document
	|from Document.Document as Documents
	|where Documents.Book in ( select Book from Books )
	|";
	q = new Query ( s );
	q.SetParameter ( "Book", Book );
	return q.Execute ().Unload ();
	
EndFunction 