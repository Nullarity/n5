&AtServer
var TextDocument;
&AtClient
var AttachmentRow;
&AtClient
var TagRow;
&AtClient
var OldTag;
&AtServer
var Reference;
&AtClient
var WorkFolder;
&AtClient
var Processing;
&AtClient
var SearchCounter;
&AtClient
var SeachCallback;
&AtClient
var ChangedFiles;
&AtClient
var FilesCounter;
&AtClient
var PreviousArea;
&AtClient
var TotalsEnv;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	installStatus ();
	readAccess ( Object.Ref );
	setReadonlyLabel ();
	loadTable ();
	setCanChange ();
	setCanChangeAccess ();
	Attachments.Read ( Object.Ref, Tables.Attachments );
	Tags.Read ( Object.Ref, Tables.Tags );
	if ( Status = Enums.DocumentStatuses.Published ) then
		initPreview ();
	else
		initEditor ( CurrentObject );
	endif; 
	setAttachmentsCount ();
	updateChangesPermission ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure installStatus ()
	
	info = InformationRegisters.DocumentStatuses.Get ( new Structure ( "Document", Object.Ref ) );
	if ( Parameters.Command = Enum.DocumentCommandsUpdateFiles ()
		and info.Status = Enums.DocumentStatuses.Published ) then
		editing = Enums.DocumentStatuses.Editing;
		Documents.Document.WriteStatus ( Object.Ref, editing );
		Status = editing;
		CurrentEditor = SessionParameters.User;
	else
		Status = info.Status;
		CurrentEditor = info.User;
	endif; 
	SomeoneLocked = ( Status <> Enums.DocumentStatuses.Published
	and CurrentEditor <> SessionParameters.User );

EndProcedure 

&AtServer
Procedure readAccess ( Document )
	
	s = "
	|select Access.UserGroup as UserGroup, Access.Read as Read, Access.Write as Write
	|from InformationRegister.GroupsAccess as Access
	|where Access.Document = &Document
	|order by Access.UserGroup.Description
	|;
	|select Access.User as User, Access.Read as Read, Access.Write as Write
	|from InformationRegister.UsersAccess as Access
	|where Access.Document = &Document
	|order by Access.User.Description
	|";
	q = new Query ( s );
	q.SetParameter ( "Document", Document );
	data = q.ExecuteBatch ();
	Tables.UsersGroupsRights.Load ( data [ 0 ].Unload () );
	Tables.UsersRights.Load ( data [ 1 ].Unload () );
	
EndProcedure 

&AtServer
Procedure setReadonlyLabel ()
	
	s = Items.ReadonlyLabel.Title;
	Items.ReadonlyLabel.Title = Output.FormatStr ( s, new Structure ( "User", CurrentEditor ) );

EndProcedure 

&AtServer
Procedure loadTable ()
	
	currentObject = FormAttributeToValue ( "Object" );
	TabDoc = currentObject.Table.Get ();
	entitleTable ( ThisObject );
	
EndProcedure

&AtClientAtServerNoContext
Procedure entitleTable ( Form )
	
	items = Form.Items;
	tabDoc = Form.TabDoc;
	caption = Output.TableCaption ();
	if ( 0 < ( tabDoc.TableWidth + tabDoc.TableHeight ) ) then
		caption = caption + " *";
	endif; 
	items.PageTable.Title = caption;
	
EndProcedure 

&AtServer
Procedure setCanChange ()

	if ( Object.Ref.IsEmpty () ) then
		CanChange = true;
	else
		CanChange = Documents.Document.CanChange ( Object.Ref );
	endif; 
	
EndProcedure

&AtServer
Procedure setCanChangeAccess ()
	
	CanChangeAccess = Logins.Admin ()
	or ( SessionParameters.User = Object.Creator
		and CanChange );
	
EndProcedure 

&AtServer
Procedure initPreview ()
	
	if ( Object.IsEmpty ) then
		if ( Tables.Attachments.Count () > 0 ) then
			row = Tables.Attachments [ 0 ];
			file = row.File;
			if ( Attachments.PreviewSupported ( file ) ) then
				loadHTML ( file );
			endif;
		endif; 
	else
		loadDocument ();
	endif; 
	
EndProcedure 

&AtServer
Procedure loadHTML ( val File )
	
	Preview = getHTMl ( File );
	PreviewMode = 2;
	Appearance.Apply ( ThisObject, "PreviewMode" );
	
EndProcedure 

Function getHTML ( val File )
	
	address = AttachmentsSrv.GetFile ( Object.FolderID, File, undefined, UUID );
	return AttachmentsSrv.PreviewScript ( File, address );
	
EndFunction 

&AtServer
Procedure loadDocument ()
	
	ref = Object.Ref;
	Preview = DF.Pick ( ref, "Data" ).Get ();
	DocumentPresenter.Compile ( Preview, ref );
	PreviewMode = 1;
	Appearance.Apply ( ThisObject, "PreviewMode" );
	
EndProcedure 

&AtServer
Procedure initEditor ( CurrentObject )
	
	if ( TypeOf ( CurrentObject ) = Type ( "DocumentObject.Document" ) ) then
		data = CurrentObject.Data.Get ();
	else
		data = DF.Pick ( CurrentObject.Ref, "Data" ).Get ();
	endif;
	TextEditor.SetHTML ( data, new Structure () );
	
EndProcedure 

&AtServer
Procedure setAttachmentsCount ()
	
	AttachmentsCount = Tables.Attachments.Count ();

EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	filterHistory ();
	if ( Object.Ref.IsEmpty () ) then
		initStatus ();
		setFolderID ( Object );
		setCreator ();
		if ( Parameters.CopyingValue.IsEmpty () ) then
			cmd = Parameters.Command;
			if ( cmd = Enum.DocumentCommandsUploadEmail () ) then
				copyEmail ();
			elsif ( cmd = Enum.DocumentCommandsUploadPrintForm () ) then
				loadPrintForm ();
			endif;
		else
			resetCreationDate ();
			Object.Changes.Clear ();
			copyAccess ();
			copyAttachments ();
			copyTable ();
			Tags.Read ( Parameters.CopyingValue, Tables.Tags );
			CKEditorSrv.Copy ( Parameters.CopyingValue, Object.FolderID );
		endif; 
		setCanChange ();
		setCanChangeAccess ();
		Constraints.ShowAccess ( ThisObject );
	else
		saveHistory ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Write1 show empty ( Object.Ref );
	|GroupsAccess enable filled ( Object.Ref );
	|Tags enable CanChange;
	|FormPublish FormWrite AttachmentsUpload AttachmentsRemove AttachmentsContextMenuUpload AttachmentsContextMenuRemove AttachmentsContextMenuRenameFile FormShowPreview show Status <> Enum.DocumentStatuses.Published and CanChange;
	|FormWrite show CanChange;
	|FormEdit show CanChange and Status = Enum.DocumentStatuses.Published;
	|TextEditorGroup show Status <> Enum.DocumentStatuses.Published;
	|GroupPreview show Status = Enum.DocumentStatuses.Published;
	|FormOpenInList AttachmentsDocumentDocumentPrint AttachmentsContextMenuDocumentDocumentPrint show filled ( Object.Ref );
	|ShowDocument AttachmentsContextMenuShowDocument show
	|Status = Enum.DocumentStatuses.Published
	|and not Object.IsEmpty
	|and AttachmentsCount > 0
	|and PreviewMode <> 1;
	|Users Groups enable CanChangeAccess;
	|Book Link Object SpecialAccess Versioning lock not CanChange;
	|SpecialAccess lock ( not CanChange or not CanChangeAccess );
	|OpenFile show AttachmentsCount > 0 and PreviewMode > 1;
	|Subject TabDoc Number lock ( Status = Enum.DocumentStatuses.Published or not CanChange );
	|TabDocCommands enable Status <> Enum.DocumentStatuses.Published and CanChange;
	|FormCancelChanges show
	|filled ( Object.Ref )
	|and Object.Versioning
	|and Status = Enum.DocumentStatuses.Editing
	|and CanChange;
	|ReadonlyLabel show SomeoneLocked;
	|FilesAndTags show ( AttachmentsCount <> 0 or Status <> Enum.DocumentStatuses.Published )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure filterHistory ()
	
	DC.ChangeFilter ( Log, "Document", Object.Ref, true );
	
EndProcedure 

&AtServer
Procedure initStatus ()
	
	Status = Enums.DocumentStatuses.New;
	
EndProcedure 

&AtServer
Procedure setFolderID ( Document )
	
	Document.FolderID = new UUID ();
	
EndProcedure 

&AtServer
Procedure setCreator ()
	
	Object.Creator = SessionParameters.User;
	
EndProcedure 

&AtServer
Procedure copyEmail ()
	
	email = Parameters.Email;
	data = DF.Values ( email, "Subject, MessageID, Mailbox" );
	Object.Subject = data.Subject;
	messageID = data.MessageID;
	profile = data.Mailbox;	
	folder = EmailsSrv.GetFolder ( messageID, profile );
	folderURL = EmailsSrv.GetFolderURL ( messageID, profile );		
	folder2 = CKEditorSrv.GetFolder ( Object.FolderID );
	folderURL2 = CKEditorSrv.GetFolderURL ( Object.FolderID );
	FileSystem.CopyFolder ( folder, folder2, false );
	FileSystem.CopyFolder ( EmailsSrv.GetAttachmentsFolder ( messageID, profile ), folder2, false );	
	html = EmailsSrv.GetHTML ( email, messageID, profile, , true );
	html = StrReplace ( html, folderURL, folderURL2 );
	DeleteFiles ( folder2 + "\" + email.UUID () );	
	TextDocument = Conversion.HTMLToDocument ( html );
	Attachments.Read ( email, Tables.Attachments, true );
	for each row in Tables.Attachments do
		row.ID = new UUID ();
	enddo; 
	setAttachmentsCount ();

EndProcedure

&AtServer
Procedure loadPrintForm ()
	
	TabDoc = Parameters.TabDoc.GetArea ();
	entitleTable ( ThisObject );
	
EndProcedure 

&AtServer
Procedure resetCreationDate ()
	
	Object.CreationDate = undefined;
	
EndProcedure 

&AtServer
Procedure copyAccess ()
	
	readAccess ( Parameters.CopyingValue );
	for each row in Tables.UsersGroupsRights do
		row.Dirty = true;
	enddo; 
	for each row in Tables.UsersRights do
		row.Dirty = true;
	enddo; 
	
EndProcedure 

&AtServer
Procedure copyAttachments ()
	
	Attachments.Read ( Parameters.CopyingValue, Tables.Attachments, true );
	for each row in Tables.Attachments do
		row.Dirty = true;
	enddo; 
	setAttachmentsCount ();
			
EndProcedure 

&AtServer
Procedure copyTable ()
	
	TabDoc = DF.Pick ( Parameters.CopyingValue, "Table" ).Get ();
	entitleTable ( ThisObject );
	
EndProcedure 

&AtServer
Procedure saveHistory ()
	
	SetPrivilegedMode ( true );
	ref = Object.Ref;
	r = InformationRegisters.ReadingHistory.CreateRecordManager ();
	r.User = SessionParameters.User;
	r.Document = ref;
	r.Date = CurrentSessionDate ();
	r.Status = Status;
	r.Write ();
	InformationRegisters.ReadingLog.Add ( ref );
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( Parameters.RefreshList ) then
		NotifyChanged ( Object.Ref );
	elsif ( Parameters.Command = Enum.DocumentCommandsUpdateFiles () ) then
		ChangesList ( new NotifyDescription ( "UpdateFiles", ThisObject ) );
	endif; 
	activateTabDoc ();

EndProcedure

&AtClient
Procedure activateTabDoc ()
	
	if ( Object.IsEmpty
		and TabDoc.TableHeight > 0 ) then
		CurrentItem = Items.TabDoc;
	endif; 
	
EndProcedure 

&AtClient
Procedure UpdateFiles ( List, Params ) export
	
	if ( SomeoneLocked ) then
		Processing = false;
		Output.DocumentLocked ( ThisObject, , new Structure ( "User", CurrentEditor ), "CloseDocument" );
	else
		if ( List = undefined ) then
			Processing = false;
			Output.ChangedFilesNotFound ( ThisObject, List );
		else
			UploadFiles ( List, Params );
		endif; 
	endif; 
	
EndProcedure 

&AtClient
Procedure CloseDocument ( Params ) export
	
	Close ();
	
EndProcedure 

&AtClient
Procedure ChangedFilesNotFound ( Answer, List ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		UploadFiles ( List, undefined );
	else
		stopCommand ();
	endif; 
	
EndProcedure 

&AtClient
Procedure UploadFiles ( List, Params ) export
	
	if ( List = undefined ) then
		Processing = false;
		notifySubscribers ();
	else
		p = new Structure ();
		p.Insert ( "Files", List );
		p.Insert ( "Command", Enum.DocumentFilesCommandsUpload () );
		OpenForm ( "Document.Document.Form.Files", p, ThisObject, , , , new NotifyDescription ( "AutoUpload", ThisObject ) );
	endif; 
	
EndProcedure 

&AtClient
Procedure notifySubscribers ()
	
	subscribers = getSubscribers ();
	if ( subscribers.Count () = 0
		and Status = PredefinedValue ( "Enum.DocumentStatuses.New" ) ) then
		publishAndClose ();
	else
		p = new Structure ();
		p.Insert ( "Document", Object.Ref );
		p.Insert ( "Status", Status );
		p.Insert ( "Subscribers", subscribers );
		OpenForm ( "Document.Document.Form.Publishing", p, ThisObject, , , , new NotifyDescription ( "PublishingConfirmation", ThisObject ) );
	endif; 
	
EndProcedure

&AtServer
Function getSubscribers ()
	
	table = new ValueTable ();
	table.Columns.Add ( "Object" );
	table.Columns.Add ( "Description" );
	getBookSubscribers ( table );
	getDocumentSubscribers ( table );
	table.GroupBy ( "Object, Description" );
	table.Sort ( "Description" );
	list = new ValueList ();
	for each row in table do
		list.Add ( row.Object, row.Description );
	enddo; 
	return list;
	
EndFunction 

&AtServer
Procedure getBookSubscribers ( Table )
	
	if ( Object.Book.IsEmpty () ) then
		return;
	endif; 
	s = "
	|select Access.UserGroup as Object, Access.UserGroup.Description as Description
	|from InformationRegister.GroupsAccessBooks as Access
	|where Access.Book in ( select AccessBook from InformationRegister.EffectiveRights where Book = &Book )
	|union
	|select Access.User, Access.User.Description
	|from InformationRegister.UsersAccessBooks as Access
	|where Access.Book in ( select AccessBook from InformationRegister.EffectiveRights where Book = &Book )
	|";
	q = new Query ( s );
	q.SetParameter ( "Book", Object.Book );
	result = q.Execute ().Unload ();
	for each row in result do
		newRow = Table.Add ();
		FillPropertyValues ( newRow, row );
	enddo; 
	
EndProcedure

&AtServer
Procedure getDocumentSubscribers ( Table )
	
	for each row in Tables.UsersGroupsRights do
		if ( not row.UserGroup.IsEmpty ()
			and row.Read ) then
			newRow = Table.Add ();
			newRow.Object = row.UserGroup;
			newRow.Description = "" + row.UserGroup;
		endif; 
	enddo; 
	for each row in Tables.UsersRights do
		if ( not row.User.IsEmpty ()
			and row.User <> Object.Creator
			and row.Read ) then
			newRow = Table.Add ();
			newRow.Object = row.User;
			newRow.Description = "" + row.User;
		endif; 
	enddo; 
	
EndProcedure 

&AtClient
Procedure publishAndClose ( Subscribers = undefined, Comment = "" )
	
	writeParams = new Structure ();
	writeParams.Insert ( "Command", Enum.DocumentCommandsPublish () );
	writeParams.Insert ( "Subscribers", Subscribers );
	writeParams.Insert ( "Comment", Comment );
	if ( not Write ( writeParams ) ) then
		return;
	endif; 
	Close ();
	
EndProcedure 

&AtClient
Procedure PublishingConfirmation ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	publishAndClose ( Result.Subscribers, Result.Comment );
	
EndProcedure

&AtClient
Procedure AutoUpload ( Files, Params ) export
	
	FilesCounter = ? ( Files = undefined, 0, Files.Count () );
	if ( FilesCounter = 0 ) then
		Processing = false;
		notifySubscribers ();
	else
		for each file in Files do
			path = WorkFolder + "\" + file;
			descriptor = new Array ();
			descriptor.Add ( new TransferableFileDescription ( path ) );
			BeginPuttingFiles ( new NotifyDescription ( "FileSaved", ThisObject, file ), descriptor, , false, UUID );
		enddo; 
	endif; 
	
EndProcedure 

&AtClient
Procedure FileSaved ( Locations, File ) export
	
	saveFile ( Locations [ 0 ].Location, File, Object.Ref, Object.FolderID );
	FilesCounter = FilesCounter - 1;
	if ( FilesCounter = 0 ) then
		Processing = false;	
		notifySubscribers ();
	endif; 
	
EndProcedure 

&AtServerNoContext
Procedure saveFile ( val Location, val File, val Document, val FolderID )
	
	folder = CKEditorSrv.GetFolder ( FolderID );
	data = GetFromTempStorage ( Location );
	data.Write ( folder + GetPathSeparator () + File );
	AttachmentsSrv.AddFile ( Document, File, data.Size (), FolderID );
	
EndProcedure 

&AtClient
Procedure stopCommand ()
	
	Parameters.Command = 0;

EndProcedure 

&AtClient
Procedure OnClose ( Exit )
	
	if ( Exit ) then
		return;
	endif; 
	if ( Object.Ref.IsEmpty () ) then
		CKEditorSrv.Clean ( Object.FolderID );
	else
		if ( AttachmentsCount <> Tables.Attachments.Count () ) then
			NotifyChanged ( Object.Ref );
		endif; 
	endif; 
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	setReference ( CurrentObject );
	setAttachmentsCount ();
	setCreationDate ( CurrentObject );
	addDefaultAccess ();
	storeTable ( CurrentObject );
	storeContent ( CurrentObject );
	Tags.Save  ( Reference, Tables.Tags );
	AttachmentsSrv.Save ( Reference, Tables.Attachments );
	if ( AttachmentsCount > 0 ) then
		AttachmentsSrv.UpdateFileNames ( Reference );
	endif; 
	applyCommand ( CurrentObject, WriteParameters );
	
EndProcedure

&AtServer
Procedure setReference ( CurrentObject )
	
	if ( Object.Ref.IsEmpty () ) then
		Reference = Documents.Document.GetRef ( new UUID () );
		CurrentObject.SetNewObjectRef ( Reference );
	else
		Reference = Object.Ref;
	endif; 
		
EndProcedure 

&AtServer
Procedure setCreationDate ( CurrentObject )
	
	if ( CurrentObject.CreationDate = Date ( 1, 1, 1 ) ) then
		CurrentObject.CreationDate = CurrentSessionDate ();
	endif; 
	
EndProcedure 

&AtServer
Procedure addDefaultAccess ()
	
	if ( Tables.UsersGroupsRights.Count () = 0
		and Tables.UsersRights.Count () = 0 ) then
		row = Tables.UsersRights.Add ();
		row.Dirty = true;
		row.User = Object.Creator;
		row.Read = true;
		row.Write = true;
	endif; 
	
EndProcedure 

&AtServer
Procedure storeTable ( CurrentObject )
	
	CurrentObject.Table = storeTabDoc ();
	
EndProcedure

&AtServer
Function storeTabDoc ()
	
	return new ValueStorage ( TabDoc, new Deflation ( 9 ) );
	
EndFunction 

&AtServer
Procedure storeContent ( CurrentObject )
	
	content = TextEditor.GetText ();
	CurrentObject.Content = new ValueStorage ( content );
	data = FD.GetHTML ( TextEditor );
	CurrentObject.Data = new ValueStorage ( data.HTML );
	CurrentObject.IsEmpty = IsBlankString ( content ) and ( data.PicturesCount = 0 );
	
EndProcedure 

&AtServer
Procedure applyCommand ( CurrentObject, WriteParameters )
	
	command = undefined;
	WriteParameters.Property ( "Command", command );
	if ( command = Enum.DocumentCommandsPublish () ) then
		logChanges ( CurrentObject, WriteParameters );
		CurrentObject.Date = CurrentSessionDate ();
		Status = Enums.DocumentStatuses.Published;
	endif; 

EndProcedure 

&AtServer
Procedure logChanges ( CurrentObject, WriteParameters )
	
	if ( Status = Enums.DocumentStatuses.Editing ) then
		comment = WriteParameters.Comment;
	elsif ( Object.Versioning ) then
		comment = Output.VersionCreated ();
	else
		comment = Output.DocumentPublished ();
	endif; 
	version = ? ( Object.Versioning, Documents.DocumentVersion.Create ( CurrentObject ), undefined );
	Documents.Document.LogChanges ( CurrentObject, version, comment );
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	Documents.Document.WriteStatus ( Reference, Status );
	saveAccess ();
	sendNotifications ( WriteParameters );
	if ( Object.Ref.IsEmpty () ) then
		setSorting ();
	endif; 
	
EndProcedure

&AtServer
Procedure saveAccess ()
	
	for each row in Tables.UsersGroupsRights do
		if ( row.Dirty ) then
			writeGroupAccess ( Reference, Collections.GetFields ( row, "UserGroup, Read, Write" ) );
		endif; 
	enddo; 
	for each row in Tables.UsersRights do
		if ( row.Dirty ) then
			writeUserAccess ( Reference, Collections.GetFields ( row, "User, Read, Write" ) );
		endif;
	enddo; 
	
EndProcedure 

&AtServer
Procedure sendNotifications ( WriteParameters )
	
	command = undefined;
	WriteParameters.Property ( "Command", command );
	if ( command = Enum.DocumentCommandsPublish () ) then
		if ( WriteParameters.Subscribers = undefined ) then
			return;
		endif; 
		p = new Array ();
		p.Add ( Reference );
		p.Add ( WriteParameters.Subscribers );
		p.Add ( WriteParameters.Comment );
		Jobs.Run ( "DocumentsNotifications.Send", p, , "Send documents notifications" );
	endif; 
	
EndProcedure 

&AtServer
Procedure setSorting ()
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.DocumentsSorting.CreateRecordManager ();
	r.Document = Reference;
	r.Sorting = Catalogs.Books.GetSorting ();
	r.Write ();
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	if ( Status = Enums.DocumentStatuses.Published ) then
		return;
	endif; 
	setAttachmentsCount ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure ShowPreview ( Command )
	
	Write ();
	openPreview ();
	
EndProcedure

&AtClient
Procedure openPreview ()
	
	p = new Structure ();
	p.Insert ( "FolderID", Object.FolderID );
	p.Insert ( "Document", Object.Ref );
	OpenForm ( "Document.Document.Form.Preview", p );
	
EndProcedure 

&AtClient
Procedure Publish ( Command )
	
	Output.PublishDocument ( ThisObject );
	
EndProcedure

&AtClient
Procedure PublishDocument ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	if ( accessExists () ) then
		startUploading ();
	else
		Output.PublicationAccessSetup ( ThisObject );
	endif; 
	
EndProcedure 

&AtClient
Function accessExists ()
	
	if ( not Object.Book.IsEmpty () ) then
		return true;
	endif; 
	for each row in Tables.UsersGroupsRights do
		if ( not row.UserGroup.IsEmpty ()
			and row.Read ) then
			return true;
		endif; 
	enddo; 
	for each row in Tables.UsersRights do
		if ( not row.User.IsEmpty ()
			and row.User <> Object.Creator
			and row.Read ) then
			return true;
		endif; 
	enddo; 
	return false;
	
EndFunction 

&AtClient
Procedure startUploading ()
	
	ChangesList ( new NotifyDescription ( "UploadFiles", ThisObject ) );

EndProcedure 

&AtClient
Procedure ChangesList ( Callback )
	
	if ( Tables.Attachments.Count () = 0 ) then
		ExecuteNotifyProcessing ( Callback, undefined );
	else
		SeachCallback = Callback;
		Attachments.UserFolder ( Object.FolderID, new NotifyDescription ( "SearchFiles", ThisObject ) );
	endif; 
	
EndProcedure 

&AtClient
Procedure SearchFiles ( Folder, Params ) export
	
	table = Tables.Attachments;
	WorkFolder = Folder;
	Processing = true;
	SearchCounter = table.Count ();
	ChangedFiles = new Array ();
	for each row in table do
		name = row.File;
		path = Folder + "\" + name;
		file = new Structure ( "File, Extension", name, row.Extension );
		LocalFiles.Modification ( path, new NotifyDescription ( "ModificationTime", ThisObject, file ) );
	enddo; 
	
EndProcedure 

&AtClient
Procedure ModificationTime ( Time, File ) export
	
	if ( Time <> undefined ) then
		downloaded = downloaded ( Object.Ref, File.File );
		changed = SessionDate ( Time );
		if ( changed > downloaded
			and downloaded <> Date ( 1, 1, 1 ) ) then
			ChangedFiles.Add ( File );
		endif;
	endif; 
	searchLoop ();
	
EndProcedure 

&AtServerNoContext
Function downloaded ( val Document, val File )
	
	p = new Structure ( "User, Reference, File", SessionParameters.User, Document, File );
	return InformationRegisters.Downloads.Get ( p ).Date;
	
EndFunction 

&AtClient
Procedure searchLoop ()
	
	SearchCounter = SearchCounter - 1;
	if ( SearchCounter > 0 ) then
		return;
	endif; 
	ExecuteNotifyProcessing ( SeachCallback, ? ( ChangedFiles.Count () = 0, undefined, ChangedFiles ) );
	SeachCallback = undefined; // Unbinds cross-reference to avoid memory leaks

EndProcedure 

&AtClient
Procedure PublicationAccessSetup ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		startUploading ();
	endif; 
	
EndProcedure 

&AtClient
Procedure Edit ( Command )
	
	Output.ChangeDocument ( ThisObject );
	
EndProcedure

&AtClient
Procedure ChangeDocument ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	unpublish ();
	
EndProcedure 

&AtServer
Procedure unpublish ()
	
	Status = Enums.DocumentStatuses.Editing;
	Documents.Document.WriteStatus ( Object.Ref, Status );
	initEditor ( Object );
	Appearance.Apply ( ThisObject, "Status" );
	
EndProcedure 

&AtClient
Procedure PreviewOnClick ( Item, EventData, StandardProcessing )
	
	Emails.ProcessLink ( EventData, StandardProcessing );
	
EndProcedure

&AtClient
Procedure OpenInList ( Command )
	
	syncInList ();
	
EndProcedure

&AtClient
Procedure syncInList ()
	
	DocumentsCurrentRow = Object.Ref;
	OpenForm ( "Document.Document.ListForm", new Structure ( "CurrentRow", Object.Ref ) );
	
EndProcedure 

&AtClient
Procedure CancelChanges ( Button )
	
	Output.RollbackChanges ( ThisObject );
	
EndProcedure

&AtClient
Procedure RollbackChanges ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	rollback ();
	
EndProcedure 

&AtServer
Procedure rollback ()
	
	version = lastVersion ();
	rollbackDocument ( version );
	rollbackAttachments ( version );
	Attachments.Read ( Object.Ref, Tables.Attachments );
	Tags.Read ( Object.Ref, Tables.Tags );
	initPreview ();
	setAttachmentsCount ();
	Modified = false;
	Appearance.Apply ( ThisObject );
	
EndProcedure 

&AtServer
Function lastVersion ()
	
	i = Object.Changes.Count ();
	while ( i > 0 ) do
		i = i - 1;
		version = Object.Changes [ i ].Version;
		if ( ValueIsFilled ( version ) ) then
			return version;
		endif; 
	enddo; 
	
EndFunction 

&AtServer
Procedure rollbackDocument ( Version )
	
	Status = Enums.DocumentStatuses.Published;
	Documents.Document.WriteStatus ( Object.Ref, Status );
	fields = DF.Values ( Version, "FolderID, Content, Subject, Table, IsEmpty" );
	obj = FormAttributeToValue ( "Object" );
	FillPropertyValues ( obj, fields, "Content, Subject, IsEmpty" );
	TabDoc = fields.Table.Get ();
	obj.Table = storeTabDoc ();
	obj.Write ();
	ValueToFormAttribute ( obj, "Object" );
	CKEditorSrv.CopyDocument ( fields.FolderID, obj.FolderID );
	entitleTable ( ThisObject );
	
EndProcedure 

&AtServer
Procedure rollbackAttachments ( Version )
	
	recordset = InformationRegisters.Files.CreateRecordSet ();
	recordset.Filter.Document.Set ( Version );
	recordset.Read ();
	recordset2 = InformationRegisters.Files.CreateRecordSet ();
	recordset2.Filter.Document.Set ( Object.Ref );
	for each record in recordset do
		record2 = recordset2.Add ();
		FillPropertyValues ( record2, record );
		record2.Document = Object.Ref;
	enddo; 
	recordset2.Write ();
	
EndProcedure

// *****************************************
// *********** Group Preview

&AtClient
Procedure ShowDocument ( Command )
	
	#if ( WebClient ) then
		// 8.3.8.1675 Bug Workaround. Preview updating should go from the client side
		PreviewMode = 1;
		Appearance.Apply ( ThisObject, "PreviewMode" );
		Preview = loadWebDocument ( Object.Ref );
	#else
		loadDocument ();
	#endif

EndProcedure

&AtServerNoContext
Function loadWebDocument ( Reference )
	
	html = DF.Pick ( Reference, "Data" ).Get ();
	DocumentPresenter.Compile ( html, Reference );
	return html;
	
EndFunction 

&AtClient
Procedure OpenFile ( Command )
	
	openSelectedFile ();
	
EndProcedure

&AtClient
Procedure openSelectedFile ()
	
	Items.Attachments.CurrentRow = SelectedFile;
	perform ( Enum.AttachmentsCommandsRun () );
	
EndProcedure 

&AtClient
Procedure perform ( Command )
	
	p = Attachments.GetParams ();
	p.Command = Command;
	p.Control = Items.Attachments;
	p.Table = Tables.Attachments;
	p.FolderID = Object.FolderID;
	p.Ref = Object.Ref;
	p.Form = ThisObject;
	callback = new NotifyDescription ( "Perform2", ThisObject, p );
	Attachments.UserFolder ( Object.FolderID, callback );
	
EndProcedure

&AtClient
Procedure Perform2 ( Folder, Params ) export
	
	Params.Insert ( "Folder", Folder );
	if ( Params.Command = Enum.AttachmentsCommandsRemove () ) then
		Attachments.Remove ( Params );
	else
		Attachments.Command ( Params );
	endif; 
	
EndProcedure

&AtClient
Procedure OpenAttachment ( Command )
	
	perform ( Enum.AttachmentsCommandsRun () );
	
EndProcedure

// *****************************************
// *********** Table Attachments

&AtClient
Procedure AttachmentsOnActivateRow ( Item )
	
	AttachmentRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure AttachmentsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Status = PredefinedValue ( "Enum.DocumentStatuses.Published" ) ) then
		file = AttachmentRow.File;
		if ( Attachments.PreviewSupported ( file ) ) then
			SelectedFile = SelectedRow;
			loadHTML ( file );
			return;
		endif;
	endif;
	perform ( Enum.AttachmentsCommandsRun () );
	
EndProcedure

&AtClient
Procedure Upload ( Command )
	
	perform ( Enum.AttachmentsCommandsUpload () );
	
EndProcedure

&AtClient
Procedure Remove ( Command )
	
	perform ( Enum.AttachmentsCommandsRemove () );
	
EndProcedure

&AtClient
Procedure DownloadFile ( Command )

	perform ( Enum.AttachmentsCommandsDownload () );

EndProcedure

&AtClient
Procedure DownloadAllFiles ( Command )
	
	perform ( Enum.AttachmentsCommandsDownloadAll () );
	
EndProcedure

&AtClient
Procedure PrintAttachment ( Command )
	
	perform ( Enum.AttachmentsCommandsPrint () );
	
EndProcedure

&AtClient
Procedure RenameFile ( Command )
	
	if ( AttachmentRow = undefined ) then
		return;
	endif; 
	ShowInputString ( new NotifyDescription ( "NewFileName", ThisObject ), AttachmentRow.File, Output.RenameFile (), fileLength () );
	
EndProcedure

&AtServerNoContext
Function fileLength ()
	
	return Metadata.DataProcessors.Tables.TabularSections.Attachments.Attributes.File.Type.StringQualifiers.Length;
	
EndFunction 

&AtClient
Procedure NewFileName ( Name, Params ) export
	
	if ( not checkName ( Name ) ) then
		return;
	endif; 
	file = TrimAll ( Name );
	ext = AttachmentsSrv.Rename ( Object.Ref, AttachmentRow.File, file, Object.FolderID );
	AttachmentRow.File = file;
	AttachmentRow.Extension = ext;
	
EndProcedure 

&AtClient
Function checkName ( Name )
	
	if ( Name = undefined ) then
		return false;
	endif; 
	file = TrimAll ( Name );
	if ( IsBlankString ( file ) ) then
		return false;
	endif; 
	for each row in Tables.Attachments do
		if ( row.File = file ) then
			Output.FileNameExists ();
			return false;
		endif; 
	enddo; 
	return true;

EndFunction 

// *****************************************
// *********** Table Groups

&AtClient
Procedure GroupsOnStartEdit ( Item, NewRow, Clone )
	
	if ( not Clone and NewRow ) then
		setReadAccess ( Item );
	endif; 
	
EndProcedure

&AtClient
Procedure setReadAccess ( Item )
	
	Item.CurrentData.Read = true;
	
EndProcedure 

&AtClient
Procedure GroupsOnEditEnd ( Item, NewRow, CancelEdit )
	
	if ( CancelEdit ) then
		return;
	endif; 
	fixRights ( Item );
	writeGroupAccess ( Object.Ref, Collections.GetFields ( Item.CurrentData, "UserGroup, Read, Write" ) );
	
EndProcedure

&AtClient
Procedure fixRights ( Item )
	
	currentData = Item.CurrentData;
	currentData.Dirty = false;
	column = Item.CurrentItem.Name;
	if ( Find ( column, "Read" ) > 0
		and currentData.Read = false
		and currentData.Write = true ) then
		currentData.Write = false;
	elsif ( Find ( column, "Write" ) > 0
		and currentData.Read = false
		and currentData.Write = true ) then
		currentData.Read = true;
	endif;
	
EndProcedure 

&AtServerNoContext
Procedure writeGroupAccess ( val Document, val Access )
	
	if ( Access.UserGroup.IsEmpty () ) then
		return;
	endif; 
	SetPrivilegedMode ( true );
	r = InformationRegisters.GroupsAccess.CreateRecordManager ();
	r.UserGroup = Access.UserGroup;
	r.Document = Document;
	if ( Access.Read or Access.Write ) then
		r.Read = Access.Read;
		r.Write = Access.Write;
		r.Write ();
	else
		r.Delete ();
	endif; 
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtClient
Procedure GroupsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	Output.AccessRemovingConfirmation ( ThisObject, Item );
	
EndProcedure

&AtClient
Procedure AccessRemovingConfirmation ( Answer, Item ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	if ( Item = Items.Groups ) then
		groups = true;
		table = Tables.UsersGroupsRights;
		field = "UserGroup";
	else
		groups = false;
		table = Tables.UsersRights;
		field = "User"
	endif; 
	objects = new Array ();
	for each row in Item.SelectedRows do
		objects.Add ( Item.RowData ( row ) [ field ] );
	enddo; 
	removeAccess ( Object.Ref, objects, groups );
	Forms.DeleteSelectedRows ( table, Item );
	
EndProcedure 

&AtServerNoContext
Procedure removeAccess ( val Document, val Objects, val Groups )
	
	SetPrivilegedMode ( true );
	for each item in Objects do
		if ( Groups ) then
			r = InformationRegisters.GroupsAccess.CreateRecordManager ();
			r.UserGroup = item;
		else
			r = InformationRegisters.UsersAccess.CreateRecordManager ();
			r.User = item;
		endif; 
		r.Document = Document;
		r.Delete ();
	enddo; 
	SetPrivilegedMode ( false );
	
EndProcedure 

// *****************************************
// *********** Table Users

&AtClient
Procedure UsersOnEditEnd ( Item, NewRow, CancelEdit )
	
	if ( CancelEdit ) then
		return;
	endif; 
	fixRights ( Item );
	writeUserAccess ( Object.Ref, Collections.GetFields ( Item.CurrentData, "User, Read, Write" ) );
	
EndProcedure

&AtServerNoContext
Procedure writeUserAccess ( val Document, val Access )
	
	if ( Access.User.IsEmpty () ) then
		return;
	endif; 
	SetPrivilegedMode ( true );
	r = InformationRegisters.UsersAccess.CreateRecordManager ();
	r.User = Access.User;
	r.Document = Document;
	if ( Access.Read or Access.Write ) then
		r.Read = Access.Read;
		r.Write = Access.Write;
		r.Write ();
	else
		r.Delete ();
	endif; 
	SetPrivilegedMode ( false );
	
EndProcedure 

// *****************************************
// *********** Table Changes

&AtClient
Procedure ChangesSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	if ( Field.Name = "ChangesVersion" ) then
		openVersion ();
	endif; 
	
EndProcedure

&AtClient
Procedure openVersion ()
	
	version = Items.Changes.CurrentData.Version;
	if ( version <> undefined ) then
		ShowValue ( , version );
	endif; 
	
EndProcedure 

// *****************************************
// *********** Table Tags

&AtClient
Procedure TagsOnActivateRow ( Item )
	
	TagRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure TagsOnStartEdit ( Item, NewRow, Clone )
	
	OldTag = TagRow.Tag;
	
EndProcedure

&AtClient
Procedure TagsOnEditEnd ( Item, NewRow, CancelEdit )
	
	if ( CancelEdit ) then
		return;
	endif;
	Tags.Attach ( Object.Ref, TagRow, OldTag );
	
EndProcedure

&AtClient
Procedure TagsBeforeDeleteRow ( Item, Cancel )
	
	Tags.Delete ( Object.Ref, Items.Tags, Tables.Tags  );
	
EndProcedure

// *****************************************
// *********** Page Table

&AtClient
Procedure TabDocOnChange ( Item )
	
	entitleTable ( ThisObject );
	PreviousArea = undefined;
	
EndProcedure 

&AtClient
Procedure TabDocOnActivateArea ( Item )

	if ( drawing ()
		or sameArea () ) then
		return;
	endif;
	startCalculation ();
	
EndProcedure

&AtClient
Function drawing ()
	
	return TypeOf ( TabDoc.CurrentArea ) <> Type ( "SpreadsheetDocumentRange" );
	
EndFunction 

&AtClient
Function sameArea ()
	
	currentName = TabDoc.CurrentArea.Name;
	if ( PreviousArea = currentName ) then
		return true;
	else
		PreviousArea = currentName;
		return false;
	endif; 
	
EndFunction 

&AtClient
Procedure startCalculation ()
	
	DetachIdleHandler ( "startUpdating" );
	AttachIdleHandler ( "startUpdating", 0.2, true );
	
EndProcedure 

&AtClient
Procedure startUpdating ()
	
	updateTotals ( true );
	
EndProcedure

&AtClient
Procedure updateTotals ( CheckSquare )
	
	if ( TotalsEnv = undefined ) then
		SpreadsheetTotals.Init ( TotalsEnv );	
	endif;
	TotalsEnv.Spreadsheet = TabDoc;
	TotalsEnv.CheckSquare = CheckSquare;
	SpreadsheetTotals.Update ( TotalsEnv );
	Items.CalcTotals.Visible = CheckSquare and TotalsEnv.HugeSquare;
	TotalInfo = TotalsEnv.Result; 
	
EndProcedure

&AtClient
Procedure CalcTotals ( Command )
	
	updateTotals ( false );
	
EndProcedure

// *****************************************
// *********** Variables Initialization

#if ( not Server ) then
	Processing = false;
#endif
