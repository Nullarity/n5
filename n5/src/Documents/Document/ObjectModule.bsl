#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	fixSubject ();
	if ( IsNew () ) then
		return;
	endif; 
	if ( DeletionMark ) then
		markDeletion ( true );
	elsif ( DF.Pick ( Ref, "DeletionMark" ) ) then
		markDeletion ( false );
	endif; 
	
EndProcedure 

Procedure fixSubject ()
	
	newSubject = uniqueSubject ();
	if ( newSubject <> Subject ) then
		Subject = newSubject;
	endif; 

EndProcedure 

Function uniqueSubject ()
	
	s = "
	|select top 1 1
	|from Document.Document as Documents
	|where Documents.Subject = &Subject
	|and Documents.Book = &Book
	|and Documents.Ref <> &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Book", Book );
	SetPrivilegedMode ( true );
	lockDocuments ();
	for i = 0 to 999 do
		variant = Subject + ? ( i = 0, "", " #" + Format ( i, "NG=" ) );
		q.SetParameter ( "Subject", variant );
		if ( q.Execute ().IsEmpty () ) then
			break;
		endif; 
	enddo; 
	return variant;
	
EndFunction 

Procedure lockDocuments ()
	
	lock = new DataLock ();
	item = lock.Add ( "Document.Document");
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Book", Book );
	lock.Lock ();
	
EndProcedure 

Procedure markDeletion ( Flag )
	
	SetPrivilegedMode ( true );
	versions = getVersions ();
	for each version in versions do
		version.GetObject ().SetDeletionMark ( Flag );
	enddo; 
	cleanReadingLog ();
	
EndProcedure 

Function getVersions ()
	
	s = "
	|select Versions.Ref as Ref
	|from Document.DocumentVersion as Versions
	|where Versions.CurrentVersion = &Ref
	|and not Versions.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction 

Procedure cleanReadingLog ()
	
	s = "
	|select Log.Date as Date, Log.ID as ID
	|from InformationRegister.ReadingLog as Log
	|where Log.Document = &Document
	|";
	q = new Query ( s );
	q.SetParameter ( "Document", Ref );
	selection = q.Execute ().Select ();
	r = InformationRegisters.ReadingLog.CreateRecordManager ();
	while ( selection.Next () ) do
		r.Date = selection.Date;
		r.ID = selection.ID;
		r.Delete ();
	enddo;
	
EndProcedure

Procedure BeforeDelete ( Cancel )
	
	CKEditorSrv.Clean ( FolderID );
	
EndProcedure

#endif