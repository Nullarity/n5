&AtClient
var Separator;
&AtClient
var SeparatorText;
&AtClient
var Finisher;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.SetCreator ( Object );
		fillNew ();
	endif; 
	prepareMenu ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure prepareMenu ()

	MessageMenu.Add ( menuSelectPhrase (), Output.SelectPhrase (), , PictureLib.Catalog );
	assistantsList ();
	if ( Logins.Admin ()
		or IsInRole ( Metadata.Roles.AIFiles ) ) then
		MessageMenu.Add ( menuUploadFile (), Commands.Upload.Title, , Commands.Upload.Picture );
		MessageMenu.Add ( menuAttachFile (), Commands.Attach.Title, , Commands.Attach.Picture );
		MessageMenu.Add ( menuAttachDocument (), Commands.AttachDocument.Title, , Commands.AttachDocument.Picture );
	endif;
	
EndProcedure

&AtClientAtServerNoContext
Function menuSelectPhrase ()
	
	return 0;
	
EndFunction

&AtClientAtServerNoContext
Function menuUploadFile ()
	
	return 1;
	
EndFunction

&AtClientAtServerNoContext
Function menuAttachFile ()
	
	return 2;
	
EndFunction

&AtClientAtServerNoContext
Function menuAttachDocument ()
	
	return 3;
	
EndFunction

&AtServer
Procedure assistantsList ()
	
	s = "
	|select allowed Assistants.Ref as Ref, Assistants.Description as Name,
	|	Assistants.Purpose as Purpose
	|from Catalog.Assistants as Assistants
	|where not Assistants.DeletionMark
	|order by Name
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	parts = new Array ();
	for each row in table do
		parts.Add ( row.Name );
		purpose = row.Purpose;
		if ( purpose <> "" ) then
			parts.Add ( purpose );
		endif;
		MessageMenu.Add ( row.Ref, StrConcat ( parts, ". " ), , PictureLib.User );
		parts.Clear ();
	enddo;
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormSend Assistant MenuAttach MenuUpload MenuAttachDocument
	|MessagesContextMenuAttach MessagesContextMenuUpload MessagesContextAttachDocument
	|	disable SendingProcess;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Parameters.CopyingValue.IsEmpty () ) then
		settings = Logins.Settings ( "Company" );
		Object.Company = settings.Company;
	else
		Object.Messages.Clear ();
		Object.Subject = "";
		Object.Thread = "";
	endif; 
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( Object.Messages.Count () > 0 ) then
		AttachIdleHandler ( "activateLastMessage", 0.1, true );
	endif;
	
EndProcedure

&AtClient
Procedure activateLastMessage () export
	
	scrollMessages ();
	
EndProcedure 

&AtClient
Procedure scrollMessages ()
	
	id = Object.Messages [ Object.Messages.Count () - 1 ].GetID ();
	Items.Messages.CurrentRow = id;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Send ( Command )
	
	if ( CheckFilling ()
		and not IsBlankString ( Object.Message ) ) then
		start ();
	endif;
	CurrentItem = Items.Message;
	
EndProcedure

&AtClient
Procedure start ()
	
	lockSending ();
	setSubject ();
	addQuestion ();
	addSeparator ( false );
	scrollMessages ();
	JobKey = "Chat " + UUID;
	run ();
	startWaiting ( new CallbackDescription ( "CompleteSending", ThisObject ) );
	
EndProcedure

&AtClient
Procedure lockSending ()
	
	lockUnlock ( true );
	
EndProcedure

&AtClient
Procedure lockUnlock ( Lock )
	
	SendingProcess = Lock;
	Appearance.Apply ( ThisObject, "SendingProcess" );
	
EndProcedure

&AtClient
Procedure setSubject ()
	
	if ( Object.Subject = ""
		and Object.Messages.Count () = 0 ) then
		Object.Subject = Left ( StrReplace ( Object.Message, Chars.LF, "; " ), 150 );
	endif;
	
EndProcedure

&AtClient
Procedure addQuestion ()
	
	addSeparator ( true );
	addRow ( Object.Message, false, true, "", false );
	MessageText = Object.Message;
	Object.Message = "";
	
EndProcedure

&AtClient
Procedure addSeparator ( Me )
	
	table = Object.Messages;
	i = table.Count ();
	while ( i > 0 ) do
		i = i - 1;
		row = table [ i ];
		if ( row.Separator ) then
			if ( row.Me = Me ) then
				Separator = row;
				return;
			else
				break;
			endif;
		endif;
	enddo;
	Separator = table.Add ();
	SeparatorText = ? ( Me, Object.Creator, Object.Assistant );
	Separator.Text = SeparatorText;
	Separator.Me = Me;
	Separator.Separator = true;
	
EndProcedure

&AtServer
Procedure run ()
	
	p = DataProcessors.Chat.GetParams ();
	ResultAddress = PutToTempStorage ( undefined, UUID );
	p.Result = ResultAddress;
	p.Assistant = Object.Assistant;
	p.Message = getMessage ();
	p.Files = getFiles ();
	p.Thread = Object.Thread;
	p.Session = Session;
	args = new Array ();
	args.Add ( "Chat" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, JobKey, , TesterCache.Testing () );
	
EndProcedure

&AtServer
Function getMessage ()
	
	parts = new Array ();
	if ( Object.Messages.Count () = 0 ) then
		parts.Add ( Output.AssistantInitializationMessage ( new Structure ( "Name", Object.Creator ) ) ); 
	endif;
	parts.Add ( MessageText );
	return StrConcat ( parts, Chars.LF );
	
EndFunction

&AtServer
Function getFiles ()
	
	table = Object.Messages;
	files = new Array ();
	i = table.Count () - 1;
	limit = Enum.OpenAIMessageFilesLimit ();
	while ( i > 0 ) do
		i = i - 1;
		row = table [ i ];
		if ( not row.Me
			or limit = 0 ) then
			break;
		endif;
		if ( row.File ) then
			files.Add ( row.ID );
			limit = limit - 1;
		endif;
	enddo;
	return files;
	
EndFunction

&AtClient
Procedure startWaiting ( Callback )
	
	Finisher = Callback;
	AttachIdleHandler ( "checkCompletion", 1 );
	
EndProcedure

&AtClient
Procedure checkCompletion () export
	
	error = undefined;
	if ( jobIsActive ( JobKey, error ) ) then
		indicateProcess ();
	else
		DetachIdleHandler ( "checkCompletion" );
		restoreSeparator ();
		RunCallback ( Finisher, error );
		unlockSending ();
	endif;
	
EndProcedure 

&AtServerNoContext
Function jobIsActive ( val JobKey, Error )
	
	job = Jobs.GetBackground ( JobKey, false );
	if ( job = undefined ) then
		return false;
	elsif ( job.State = BackgroundJobState.Active ) then
		return true;
	else
		msg = new Array ();
		if ( job.State = BackgroundJobState.Failed ) then
			msg.Add ( Output.JobFailed () );
		endif;
		exception = job.ErrorInfo;
		if ( exception <> undefined ) then
			msg.Add ( exception.Description );
		endif;
		if ( msg.Count () > 0 ) then
			Error = StrConcat ( msg, ". " );
		endif;
		return false;
	endif;
	
EndFunction

&AtClient
Procedure indicateProcess ()
	
	Separator.Text = Separator.Text + ".";
	
EndProcedure

&AtClient
Procedure restoreSeparator ()
	
	if ( Separator <> undefined ) then
		Separator.Text = SeparatorText;
	endif;
	
EndProcedure

&AtClient
Procedure CompleteSending ( Exception, Params ) export
	
	if ( Exception = undefined ) then
		json = GetFromTempStorage ( ResultAddress) ;
		if ( json = undefined ) then
			return;
		endif;
		response = ReadJSONValue ( json );
		message = response.Message;
		if ( response.Error ) then
			addError ( message );
		else
			data = ReadJSONValue ( message );
			addAnswer ( data );
			Session = response.Session;
			Object.Thread = data.Thread;
		endif;
	else
		addRow ( Exception, true, false, "", false );
	endif;
	scrollMessages ();
	
EndProcedure

&AtClient
Procedure addError ( Body )
	
	try
		info = ReadJSONValue ( Body );
		text = info.error.message;
	except
		text = Body;
	endtry;
	addRow ( text, true, false, "", false );
	
EndProcedure

&AtClient
Procedure addRow ( Text, Error, Me, ID, File )
	
	table = Object.Messages;
	for each line in StrSplit ( Text, Chars.LF ) do
		row = table.Add ();
		row.Text = line;
		row.Error = Error;
		row.Me = Me;
		row.ID = ID;
		row.File = File;
	enddo;
	Appearance.Update ( ThisObject, "Assistant" );
	
EndProcedure

&AtClient
Procedure addAnswer ( Data )
	
	messages = Data.Messages.Data;
	i = messages.UBound ();
	if ( i = -1 ) then
		return;
	endif;
	last = messages [ 0 ];
	for each row in last.content do
		id = last.id;
		if ( row.type = "text" ) then
			addRow ( row.text.value, false, false, id, false );
		endif;
	enddo;
	
EndProcedure

&AtClient
Procedure unlockSending ()
	
	lockUnlock ( false );
	
EndProcedure

&AtClient
Procedure Attach ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	pickFiles ();
	
EndProcedure

&AtClient
Procedure pickFiles ()
	
	OpenForm ( "InformationRegister.AIFiles.ListForm",
		new Structure ( "Assistant, Session, ChoiceMode", Object.Assistant, Session, true ),
		Items.Messages,,,,,
		FormWindowOpeningMode.LockOwnerWindow );
	
EndProcedure

&AtClient
async Procedure Upload ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	lockSending ();
	files = await prepareFiles ();
	if ( files = undefined ) then
		unlockSending ();
		return;
	endif;
	uploadData ( files, true );

EndProcedure

&AtClient
Procedure uploadData ( List, Files )

	lockSending ();
	addSeparator ( true );
	scrollMessages ();
	JobKey = "Uploading " + UUID;
	if ( Files ) then
		transferFiles ( List );
	else
		transferDocuments ( List );
	endif;
	startWaiting ( new CallbackDescription ( "CompleteUploading", ThisObject ) );

EndProcedure

&AtClient
async Function prepareFiles ()

	list = await PutFilesToServerAsync ( , , new PutFilesDialogParameters ( , true ) );
	if ( list = undefined ) then
		return undefined;
	endif;
	files = Attachments.GetStoredFiles ( list );
	return ? ( files.Count () = 0, undefined, files );

EndFunction

&AtServer
Procedure transferFiles ( val Files )
	
	list = new Array ();
	for each file in Files do
		descriptor = DataProcessors.UploadToAI.Descriptor (
			file.Name,
			file.Size,
			GetFromTempStorage ( file.Address )
		);
		list.Add ( descriptor );
	enddo;
	startUploadingJob ( list );
	
EndProcedure

&AtServer
Procedure startUploadingJob ( Files )

	p = DataProcessors.UploadToAI.GetParams ();
	p.Files = Files;
	ResultAddress = PutToTempStorage ( undefined, UUID );
	p.Result = ResultAddress;
	p.Assistant = Object.Assistant;
	p.Session = Session;
	args = new Array ();
	args.Add ( "UploadToAI" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, JobKey, , TesterCache.Testing () );

EndProcedure

&AtServer
Procedure transferDocuments ( val List )
	
	s = "
	|select Files.Document.FolderID as Folder, Files.File as Name, Files.Size as Size
	|from InformationRegister.Files as Files
	|where Files.Document in ( &Documents )
	|";
	q = new Query ( s );
	q.SetParameter ( "Documents", List );
	table = q.Execute ().Unload ();
	separator = GetPathSeparator ();
	files = new Array ();
	for each row in table do
		name = row.Name;
		file = CKEditorSrv.GetFolder ( row.Folder ) + separator + name;
		descriptor = DataProcessors.UploadToAI.Descriptor (
			name,
			row.Size,
			new BinaryData ( file )
		);
		files.Add ( descriptor );
	enddo;
	startUploadingJob ( files );
	
EndProcedure

&AtClient
Procedure CompleteUploading ( Exception, Params ) export
	
	if ( Exception = undefined ) then
		data = GetFromTempStorage ( ResultAddress) ;
		if ( data = undefined ) then
			return;
		endif;
		Session = data.Session;
		for each file in data.Files do
			error = file.Error;
			if ( error = "" ) then
				addFile ( file.File.Name, file.ID );
			else
				addRow ( file.File.Name + ": " + error, true, true, "", true );
			endif;
		enddo;
	else
		addRow ( Exception, true, true, "", true );
	endif;
	scrollMessages ();
	activateMessage ();
	
EndProcedure

&AtClient
Procedure addFile ( Name, ID )

	addRow ( Name, false, true, ID, true );
	
EndProcedure

&AtClient
Procedure AttachDocument ( Command )

	if ( not CheckFilling () ) then
		return;
	endif;
	pickDocuments ();

EndProcedure
	
&AtClient
Procedure pickDocuments ()

	OpenForm ( "Document.Document.ChoiceForm",
		new Structure ( "MultipleChoice", true ),
		Items.Messages,,,,,
		FormWindowOpeningMode.LockOwnerWindow );

EndProcedure
	
&AtClient
Procedure AssistantOnChange ( Item )
	
	activateMessage ();
	
EndProcedure

&AtClient
Procedure activateMessage ()
	
	if ( not Object.Assistant.IsEmpty () ) then
		CurrentItem = Items.Message;
	endif;
	
EndProcedure

&AtClient
Procedure MessageStartChoice ( Item, ChoiceData, ChoiceByAdding, StandardProcessing )
	
	StandardProcessing = false;
	showMenu ();
	
EndProcedure

&AtClient
async Procedure showMenu ()
	
	menu = await ChooseFromMenuAsync ( MessageMenu, Items.Message );
	if ( menu = undefined ) then
		return;
	endif;
	selected = menu.Value;
	type = TypeOf ( selected );
	if ( type = Type ( "Number" ) ) then
		if ( selected = menuSelectPhrase () ) then
			OpenForm ( "Catalog.Phrases.ChoiceForm", , Items.Message );
		elsif ( selected = menuUploadFile () ) then
			Upload ( undefined );
		elsif ( selected = menuAttachFile () ) then
			Attach ( undefined );
		elsif ( selected = menuAttachDocument () ) then
			AttachDocument ( undefined );
		endif;
	else
		Object.Assistant = menu.Value;
		activateMessage ();
	endif;
	
EndProcedure

&AtClient
Procedure MessageChoiceProcessing ( Item, Phrase, AdditionalData, StandardProcessing )
	
	StandardProcessing = false;
	injectPhrase ( Phrase );
	
EndProcedure

&AtClient
Procedure injectPhrase ( Phrase )
	
	Items.Message.SelectedText = DF.Pick ( Phrase, "Text" );
	
EndProcedure

// *****************************************
// *********** Table Messages

&AtClient
Procedure MessagesChoiceProcessing ( Item, Set, StandardProcessing )

	StandardProcessing = false;
	if ( TypeOf ( Set [ 0 ] ) = Type ( "DocumentRef.Document" ) ) then
		uploadData ( Set, false );
	else
		loadFiles ( Set );
	endif;

EndProcedure

&AtClient
Procedure loadFiles ( Files )

	addSeparator ( true );
	for each file in Files do
		addFile ( file.Name, file.ID );
	enddo;
	scrollMessages ();

EndProcedure

&AtClient
Procedure MessagesSelection ( Item, RowSelected, Field, StandardProcessing )
	
	StandardProcessing = false;
	augmentMessage ();
	
EndProcedure

&AtClient
Procedure augmentMessage ()
	
	table = Items.Messages;
	text = new Array ();
	for each id in table.SelectedRows do
		text.Add ( table.RowData ( id ).Text );
	enddo;
	content = StrConcat ( text, Chars.LF );
	if ( Object.Message = "" ) then
		Object.Message = content;
	else
		Object.Message = Object.Message + Chars.LF + content;
	endif;
	Modified = true;
	
EndProcedure
