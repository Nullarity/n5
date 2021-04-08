#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	Fields.Add ( "Subject" );
	StandardProcessing = false;
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Left ( Data.Subject, 50 );
	
EndProcedure

Procedure Create ( Address, Name, File, Book, Object ) export
	
	date = CurrentSessionDate ();
	obj = Documents.Document.CreateDocument ();
	obj.Date = date;
	obj.Book = Book;
	obj.CreationDate = date;
	obj.Creator = SessionParameters.User;
	folder = new UUID ();
	obj.FolderID = folder;
	obj.IsEmpty = true;
	obj.Subject = Name;
	obj.Object = Object;
	obj.Versioning = true;
	version = Documents.DocumentVersion.GetRef ( new UUID () );
	LogChanges ( obj, version, Output.VersionCreated () );
	obj.Write ();
	ref = obj.Ref;	
	writeSorting ( ref );
	WriteStatus ( ref, Enums.DocumentStatuses.Published );				
	loadAttachment ( obj, Address, File );
	obj.AttachmentsContent = Documents.Document.ExtractContent ( obj.Ref );
	obj.DataExchange.Load = true;
	obj.Write ();
	if ( not ValueIsFilled ( Book ) ) then
		setAccess ( obj );
	endif; 
	CKEditorSrv.Store ( folder, "" );
	Documents.DocumentVersion.Create ( obj, version );
	
EndProcedure 

Procedure loadAttachment ( Document, Address, File )
	
	folder = CKEditorSrv.GetFolder ( Document.FolderID );
	CreateDirectory ( folder );
	data = GetFromTempStorage ( Address );
	data.Write ( folder + "\" + File );
	size = data.Size ();
	AttachmentsSrv.AddFile ( Document.Ref, File, size, 1, Document.FolderID, true );
		
EndProcedure 

Procedure setAccess ( Document )
	
	r = InformationRegisters.UsersAccess.CreateRecordManager ();
	r.User = Document.Creator;
	r.Document = Document.Ref;
	r.Read = true;
	r.Write = true;
	r.Write ();
	r = InformationRegisters.GroupsAccess.CreateRecordManager ();
	r.UserGroup = Catalogs.UserGroupsDocuments.Everybody;
	r.Document = Document.Ref;
	r.Read = true;
	r.Write ();
	
EndProcedure 

Function ExtractContent ( Document ) export
	
	SetPrivilegedMode ( true );
	path = CKEditorSrv.GetFolder ( Document.FolderID );
	text = new Array ();
	extractor = new TextExtraction ();
	for each name in documentFiles ( Document ) do
		extractor.FileName = path + "\" + name;
		try
			data = extractor.GetText ();
		except
			continue;
		endtry;
		text.Add ( data );
	enddo;
	return StrConcat ( text, Chars.LF );
	
EndFunction

Function documentFiles ( Document )
	
	s = "
	|select Files.File as File
	|from InformationRegister.Files as Files
	|where Files.Document = &Document
	|";
	q = new Query ( s );
	q.SetParameter ( "Document", Document );
	return q.Execute ().Unload ().UnloadColumn ( "File" );
	
EndFunction

Procedure LogChanges ( Document, Version, Comment ) export
	
	row = Document.Changes.Add ();
	row.Date = CurrentSessionDate ();
	row.Comment = Comment;
	row.User = SessionParameters.User;
	row.ComputerName = ComputerName ();
	row.Version = version;
	
EndProcedure 

Function CanChange ( Document ) export
	
	fields = DF.Values ( Document, "Book, SpecialAccess" );
	s = "
	|select top 1 1
	|where &Ref in (
	|	select Statuses.Document
	|	from InformationRegister.DocumentStatuses as Statuses
	|	where Document = &Ref
	|	and ( Statuses.Status = value ( Enum.DocumentStatuses.Published )
	|		or Statuses.User = &User ) )
	|and (
	|	&Ref in (
	|		select Document
	|		from InformationRegister.GroupsAccess as GroupsAccess
	|			//
	|			// Groups
	|			//
	|			join InformationRegister.UsersAndGroupsDocuments as Groups
	|			on Groups.UserGroup = GroupsAccess.UserGroup
	|			and Groups.User = &User
	|		where GroupsAccess.Write
	|		union
	|		select Document
	|		from InformationRegister.UsersAccess as UsersAccess
	|		where UsersAccess.User = &User
	|		and UsersAccess.Document = &Ref
	|		and UsersAccess.Write
	|		union
	|		select Document
	|		from InformationRegister.GroupsAccess as GroupsAccess
	|		where GroupsAccess.UserGroup = value ( Catalog.UserGroupsDocuments.Everybody )
	|		and GroupsAccess.Document = &Ref
	|		and GroupsAccess.Write
	|	)";
	if ( not fields.SpecialAccess ) then
		s = s + "
		|	or &Book in (
		|		select EffectiveRights.Book
		|		from InformationRegister.EffectiveRights as EffectiveRights
		|			//
		|			// GroupsAccess
		|			//
		|			join InformationRegister.GroupsAccessBooks as GroupsAccess
		|			on GroupsAccess.Book = EffectiveRights.AccessBook
		|			and GroupsAccess.Write
		|			//
		|			// Groups
		|			//
		|			join InformationRegister.UsersAndGroupsDocuments as Groups
		|			on Groups.UserGroup = GroupsAccess.UserGroup
		|			and Groups.User = &User
		|		where EffectiveRights.Book = &Book
		|		union
		|		select EffectiveRights.Book
		|		from InformationRegister.EffectiveRights as EffectiveRights
		|			//
		|			// UsersAccess
		|			//
		|			join InformationRegister.UsersAccessBooks as UsersAccess
		|			on UsersAccess.Book = EffectiveRights.AccessBook
		|			and UsersAccess.User = &User
		|			and UsersAccess.Write
		|		where EffectiveRights.Book = &Book
		|		union
		|		select EffectiveRights.Book
		|		from InformationRegister.EffectiveRights as EffectiveRights
		|			//
		|			// GroupsAccess
		|			//
		|			join InformationRegister.GroupsAccessBooks as GroupsAccess
		|			on GroupsAccess.UserGroup = value ( Catalog.UserGroupsDocuments.Everybody )
		|			and GroupsAccess.Book = EffectiveRights.AccessBook
		|			and GroupsAccess.Write
		|		where EffectiveRights.Book = &Book
		|	)";
	endif; 
	s = s + "
	|)
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Document );
	q.SetParameter ( "Book", fields.Book );
	q.SetParameter ( "User", SessionParameters.User );
	return q.Execute ().Select ().Next ();
	
EndFunction 

Procedure Copy ( Source, Receiver ) export

	writeSorting ( Receiver );
	copyStatus ( Source, Receiver );
	copyGroupsAccess ( Source, Receiver );
	copyUsersAccess ( Source, Receiver );	
	copyFiles ( Source, Receiver );
	copyFileNames ( Source, Receiver );
	copyAttachmentsCount ( Source, Receiver );	
	copyTags ( Source, Receiver );
	copySuperTags ( Source, Receiver );
	
EndProcedure 

Procedure copyStatus ( Source, Receiver )
	
	status = InformationRegisters.DocumentStatuses.Get ( new Structure ( "Document", Source ) ).Status;
	WriteStatus ( Receiver, status );
	
EndProcedure 

Procedure copyGroupsAccess ( Source, Receiver )
	
	recordset = InformationRegisters.GroupsAccess.CreateRecordSet ();
	recordset.Filter.Document.Set ( Source );
	recordset.Read ();	
	recordset2 = InformationRegisters.GroupsAccess.CreateRecordSet ();
	recordset2.Filter.Document.Set ( Receiver );	
	for each record in recordset do
		record2 = recordset2.Add ();
		FillPropertyValues ( record2, record );				
		record2.Document = Receiver;
	enddo; 
	recordset2.Write ( false );
	
EndProcedure 

Procedure copyUsersAccess ( Source, Receiver )
	
	recordset = InformationRegisters.UsersAccess.CreateRecordSet ();
	recordset.Filter.Document.Set ( Source );
	recordset.Read ();	
	recordset2 = InformationRegisters.UsersAccess.CreateRecordSet ();
	recordset2.Filter.Document.Set ( Receiver );	
	for each record in recordset do
		record2 = recordset2.Add ();
		FillPropertyValues ( record2, record );				
		record2.Document = Receiver;
	enddo; 
	recordset2.Write ( false );
	
EndProcedure

Procedure copyFiles ( Source, Receiver )
	
	recordset = InformationRegisters.Files.CreateRecordSet ();
	recordset.Filter.Document.Set ( Source );
	recordset.Read ();	
	recordset2 = InformationRegisters.Files.CreateRecordSet ();
	recordset2.Filter.Document.Set ( Receiver );	
	for each record in recordset do
		record2 = recordset2.Add ();
		FillPropertyValues ( record2, record );
		record2.Document = Receiver;
	enddo; 
	recordset2.Write ( false );
	
EndProcedure 

Procedure copyFileNames ( Source, Receiver )
	
	recordset = InformationRegisters.FileNames.CreateRecordSet ();
	recordset.Filter.Document.Set ( Source );
	recordset.Read ();	
	recordset2 = InformationRegisters.FileNames.CreateRecordSet ();
	recordset2.Filter.Document.Set ( Receiver );	
	for each record in recordset do
		record2 = recordset2.Add ();
		FillPropertyValues ( record2, record );
		record2.Document = Receiver;
	enddo; 
	recordset2.Write ( false );
	
EndProcedure 

Procedure copyTags ( Source, Receiver )
	
	recordset = InformationRegisters.Tags.CreateRecordSet ();
	recordset.Filter.Document.Set ( Source );
	recordset.Read ();	
	recordset2 = InformationRegisters.Tags.CreateRecordSet ();
	recordset2.Filter.Document.Set ( Receiver );	
	for each record in recordset do
		record2 = recordset2.Add ();
		FillPropertyValues ( record2, record );				
		record2.Document = Receiver;
	enddo; 
	recordset2.Write ( false );
	
EndProcedure 

Procedure copySuperTags ( Source, Receiver )
	
	recordset = InformationRegisters.SuperTags.CreateRecordSet ();
	recordset.Filter.Document.Set ( Source );
	recordset.Read ();	
	recordset2 = InformationRegisters.SuperTags.CreateRecordSet ();
	recordset2.Filter.Document.Set ( Receiver );	
	for each record in recordset do
		record2 = recordset2.Add ();
		FillPropertyValues ( record2, record );				
		record2.Document = Receiver;
	enddo; 
	recordset2.Write ( false );
	
EndProcedure 

Procedure copyAttachmentsCount ( Source, Receiver )
	
	recordset = InformationRegisters.AttachmentsCount.CreateRecordSet ();
	recordset.Filter.Reference.Set ( Source );
	recordset.Read ();	
	recordset2 = InformationRegisters.AttachmentsCount.CreateRecordSet ();
	recordset2.Filter.Reference.Set ( Receiver );	
	for each record in recordset do
		record2 = recordset2.Add ();
		FillPropertyValues ( record2, record );
		record2.Reference = Receiver;
	enddo; 
	recordset2.Write ( false );
	
EndProcedure 

Procedure WriteStatus ( Document, Status ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.DocumentStatuses.CreateRecordManager ();
	r.Document = Document;
	r.Status = Status;
	r.User = SessionParameters.User;
	r.Write ();
	SetPrivilegedMode ( false );
	
EndProcedure 

Procedure writeSorting ( Document )
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.DocumentsSorting.CreateRecordManager ();
	r.Document = Document;
	r.Sorting = Catalogs.Books.GetSorting ();
	r.Write ();
	SetPrivilegedMode ( false );
		
EndProcedure

#endif