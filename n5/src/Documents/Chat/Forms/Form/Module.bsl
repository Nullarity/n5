&AtClient
var Separator;
&AtClient
var SeparatorID;
&AtClient
var SeparatorText;
&AtClient
var Finisher;
&AtClient
var StoppingTimeout;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	initChat ();
	initIDs ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure initChat ()

	ChatForm.Prepare ( ThisObject );
	ChatForm.SetBody ( Chat, Object );

EndProcedure

&AtServer
Procedure initIDs ()
	
	count = Object.Data.Count ();
	LinkID = 1 + ? ( count = 0, 0, Object.Data [ count - 1 ].Link );
	ElementID = 1 + ? ( count = 0, 0, Object.Data [ count - 1 ].Element );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	readSettings ();
	restoreAssistant ();
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.SetCreator ( Object );
		fillNew ();
		initIDs ();
		initChat ();
	endif; 
	prepareMenu ();
	readAppearance ();
	invalidateHomepage ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	StageComplete = 0;
	StageSending = 1;
	StageStopping = 2;
	
EndProcedure

&AtServer
Procedure readSettings ()

	Plaintext = CommonSettingsStorage.Load ( Enum.SettingsChatInPlaintext () );

EndProcedure

&AtServer
Procedure restoreAssistant ()
	
	setAssistant ( ThisObject, CommonSettingsStorage.Load ( Enum.SettingsChatAssistant () ) );
	
EndProcedure

&AtServer
Procedure prepareMenu ()

	FunctionsMenu.Add ( menuSelectPhrase (), Output.SelectPhrase (), , PictureLib.Catalog );
	assistantsList ();
	if ( Logins.Admin ()
		or IsInRole ( Metadata.Roles.AIFiles ) ) then
		FunctionsMenu.Add ( menuUploadFile (), Commands.Upload.Title, , Commands.Upload.Picture );
		FunctionsMenu.Add ( menuAttachFile (), Commands.Attach.Title, , Commands.Attach.Picture );
		FunctionsMenu.Add ( menuAttachDocument (), Commands.AttachDocument.Title, , Commands.AttachDocument.Picture );
		FunctionsMenu.Add ( menuDeleteFile (), Commands.DeleteFile.Title, , Commands.DeleteFile.Picture );
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

&AtClientAtServerNoContext
Function menuDeleteFile ()
	
	return 4;
	
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
		FunctionsMenu.Add ( row.Ref, StrConcat ( parts, ". " ), , PictureLib.User );
		parts.Clear ();
	enddo;
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|GroupHomepage hide ChatStarted;
	|Attach Upload AttachDocument
	|MenuAttach MenuUpload MenuAttachDocument
	|MessagesContextMenuAttach MessagesContextMenuUpload MessagesContextAttachDocument
	|MessagesContextMenuAttach1 MessagesContextMenuUpload1 MessagesContextAttachDocument1
	|	show RetrievalCapability;
	|SaveAndNew FormWrite
	|FormSend FormResend Assistant MenuAttach MenuUpload MenuAttachDocument
	|MessagesContextMenuAttach MessagesContextMenuUpload MessagesContextAttachDocument
	|MessagesContextMenuAttach1 MessagesContextMenuUpload1 MessagesContextAttachDocument1
	|OpenHistory
	|	disable CurrentStage <> StageComplete;
	|FormSend show not Object.Error and CurrentStage = StageComplete;
	|FormSend assign not Object.Error and CurrentStage = StageComplete;
	|FormResend show Object.Error and CurrentStage = StageComplete;
	|FormResend assign Object.Error and CurrentStage = StageComplete;
	|FormStop show CurrentStage = StageSending;
	|FormStop assign CurrentStage = StageSending;
	|FormStopping show CurrentStage = StageStopping;
	|GroupHTML disable CurrentStage = StageSending and Plaintext;
	|GroupText disable CurrentStage = StageSending and not Plaintext;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.Property ( "CopyingValue" )
		or Parameters.CopyingValue.IsEmpty () ) then
		settings = Logins.Settings ( "Company" );
		Object.Company = settings.Company;
		Object.Date = CurrentSessionDate ();
		if ( Object.Assistant.IsEmpty () ) then
			setAssistant ( ThisObject, defaultAssistant () );
		endif;
	else
		Object.Messages.Clear ();
		Object.Data.Clear ();
		Object.Files.Clear ();
		Object.Subject = "";
		Object.Thread = "";
	endif; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setAssistant ( Form, Assistant )
	
	if ( not ValueIsFilled ( Assistant ) ) then
		return;
	endif;
	memorizeAssistant ( Assistant );
	Form.Object.Assistant = Assistant;
	data = DF.Values ( Assistant, "Server, Retrieval" );
	Form.Server = data.Server;
	Form.RetrievalCapability = data.Retrieval;
	Appearance.Apply ( Form, "RetrievalCapability" );
	
EndProcedure

&AtServerNoContext
Procedure memorizeAssistant ( val Assistant )

	LoginsSrv.SaveSettings ( Enum.SettingsChatAssistant (), , Assistant );

EndProcedure

&AtServer
Function defaultAssistant ()
	
	s = "
	|select allowed top 1 Assistants.Ref as Ref
	|from Catalog.Assistants as Assistants
	|	//
	|	// Filter by actual assistants
	|	//
	|	join InformationRegister.Assistants as AI
	|	on AI.Assistant = Assistants.Ref
	|where not Assistants.DeletionMark
	|order by Assistants.Code
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction

&AtClient
Procedure OnOpen ( Cancel )
	
	invalidateHomepage ( ThisObject );
	scrollMessages ();
	
EndProcedure

&AtClient
Procedure scrollMessages ()
	
	if ( Plaintext ) then
		if ( Object.Messages.Count () = 0 ) then
			return;
		endif;
		id = Object.Messages [ Object.Messages.Count () - 1 ].GetID ();
		Items.Messages.CurrentRow = id;
	else
		scrollHTML ();
	endif;
	
EndProcedure

&AtClient
Procedure scrollHTML () export
	
	data = Object.Data;
	last = data.Count ();
	if ( last = 0 ) then
		return;
	endif;
	DetachIdleHandler ( "scrollHTML" );
	document = Items.HTML.Document;
	if ( document = undefined or document.body = undefined ) then
		keepScrolling ();
		return;
	endif;
	id = ChatForm.ElementID ( data [ last - 1 ].Element );
	element = document.getElementById ( id );
	if ( element = undefined ) then
		keepScrolling ();
	else
		element.scrollIntoView ( true );
	endif;
	
EndProcedure

&AtClient
Procedure keepScrolling ()
	
	AttachIdleHandler ( "scrollHTML", 0.5, true );
	
EndProcedure

&AtClient
Procedure ChoiceProcessing ( Value, Source )

	type = TypeOf ( Value );
	if ( type = Type ( "Array" )
		and TypeOf ( Value [ 0 ] ) = Type ( "DocumentRef.Document" ) ) then
		uploadData ( Value, false );
	elsif ( type = Type ( "DocumentRef.Chat" ) ) then
		if ( Value <> Object.Ref ) then
			loadChat ( Value );
			activateMessage ();
		endif;
	else
		loadFiles ( Value );
		flushChanges ();
		scrollMessages ();
		activateMessage ();
	endif;

EndProcedure

&AtServer
Procedure loadChat ( val Ref )
	
	if ( not Object.Ref.IsEmpty () and Modified ) then
		Write ();
	endif;
	activateStage ( ThisObject, StageComplete );
	ChatStarted = undefined;
	blank = ( Ref = undefined or Ref.IsEmpty () );
	if ( blank ) then
		obj = Documents.Chat.CreateDocument ();
		Metafields.Constructor ( obj );
		message = "";
	else
		message = Object.Message;
		obj = Ref.GetObject ()
	endif;
	ValueToFormAttribute ( obj, "Object" );
	initIDs ();
	ChatForm.SetBody ( Chat, Object );
	if ( Object.Message = "" ) then
		Object.Message = message;
	endif;
	if ( blank ) then
		DocumentForm.SetCreator ( Object );
		restoreAssistant ();
		fillNew ();
	endif;
	setAssistant ( ThisObject, obj.Assistant );
	Session = "";
	invalidateHomepage ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadFiles ( val Files )

	if ( Object.Error ) then
		deleteAnswer ( ThisObject );
	else
		addSeparator ( ThisForm, true );
	endif;
	for each file in Files do
		addFile ( file.Name, file.ID );
	enddo;
	Write ();

EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )

	if ( IsBlankString ( Object.Subject )
		and not setSubject ( CurrentObject ) ) then
		Cancel = true;
	else
		CurrentObject.Date = CurrentSessionDate ();
	endif;

EndProcedure

&AtServer
Function setSubject ( CurrentObject )
	
	row = findRow ( CurrentObject.Data, "_.Me and not _.Separator", , false );
	if ( row = undefined ) then
		Output.SubjectIsEmpty ( , "Subject" );
		return false;
	endif;
	CurrentObject.Subject = Left ( StrReplace ( row.Text, Chars.LF, "; " ), 150 );
	return true;
	
EndFunction

// *****************************************
// *********** Group Form

&AtClient
Procedure NewChat ( Command )

	loadChat ( undefined );
	activateMessage ();

EndProcedure

&AtClient
Procedure OpenHistory ( Command )

	showHistory ();

EndProcedure

&AtClient
Procedure showHistory ()
	
	OpenForm ( "Document.Chat.Form.History",
		new Structure ( "Filter, Source, CurrentRow", Object.Ref, Object.Ref ), ThisObject );
	
EndProcedure

&AtClient
Procedure Send ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	resend = Object.Error;
	if ( not resend and IsBlankString ( Object.Message ) ) then
		return;
	endif;
	start ();
	activateMessage ();
	
EndProcedure

&AtClient
Procedure start ()
	
	activateStage ( ThisObject, StageSending );
	tryAgain = Object.Error;
	newMessage = not IsBlankString ( Object.Message );
	if ( tryAgain ) then
		if ( newMessage ) then
			deleteQuestion ();
		else
			deleteAnswer ( ThisObject );
		endif;
	endif;
	if ( not tryAgain or newMessage ) then
		if ( not tryAgain ) then
			addSeparator ( ThisForm, true );
		endif;
		addQuestion ();
	endif;
	addSeparator ( ThisForm, false );
	scrollMessages ();
	JobKey = "Chat " + UUID;
	error = run ( newMessage );
	if ( error = undefined ) then
		startWaiting ( new CallbackDescription ( "CompleteSending", ThisObject ) );
	else
		CompleteSending ( error, undefined );
	endif;
	
EndProcedure

&AtClientAtServerNoContext
Procedure activateStage ( Form, Stage )
	
	Form.CurrentStage = Stage;
	Appearance.Apply ( Form, "CurrentStage" );
	
EndProcedure

&AtClient
Procedure deleteQuestion ()
	
	info = getMyLastMessage ( ThisObject );
	line = info.Messages [ 0 ].LineNumber;
	table = Object.Messages;
	messageBegins = findRow ( table, "_.Separator", line - 1 ).LineNumber;
	i = table.Count ();
	while ( i > messageBegins ) do
		i = i - 1;
		row = table [ i ];
		keep = row.Me
			and ( row.Separator
				or row.Content = PredefinedValue ( "Enum.ContentType.File" ) );
		if ( not keep ) then
			deleteRow ( ThisObject, row );
		endif;
	enddo;
	
EndProcedure

&AtClient
Procedure addQuestion ()
	
	addRow ( ThisObject, Object.Message, false, true, "",
		PredefinedValue ( "Enum.ContentType.Text" ), false );
	Object.Message = "";
	Items.Message.UpdateEditText ();
	
EndProcedure

&AtClientAtServerNoContext
Procedure addSeparator ( Form, Me )
	
	object = Form.Object;
	table = object.Messages;
	row = findRow ( table, "_.Separator" );
	if ( row = undefined or row.Me <> Me ) then
		text = ? ( Me, object.Creator, object.Assistant );
		addRow ( Form, text, false, Me, "", PredefinedValue ( "Enum.ContentType.Text" ), true );
	endif;
	
EndProcedure

&AtClientAtServerNoContext
Procedure assignElement ( Form, Row )
	
	Row.Element = Form.ElementID;
	Form.ElementID = Form.ElementID + 1;
	
EndProcedure

&AtServer
Function run ( val NewMessage )
	
	if ( Object.Thread = "" ) then
		try
			Object.Thread = AIServer.GetThread ( Server );
		except
			return ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
		endtry;
	endif;
	p = AIServer.ChatParams ();
	ResultAddress = PutToTempStorage ( undefined, UUID );
	p.Result = ResultAddress;
	p.Assistant = Object.Assistant;
	p.Thread = Object.Thread;
	p.Session = Session;
	data = getMyLastMessage ( ThisObject );
	messageData = getMessage ( data );
	alreadySent = ( messageData.ID <> "" );
	p.Resend = alreadySent;
	if ( NewMessage or not alreadySent ) then
		p.Message = messageData.Text;
	endif;
	p.Files = getFiles ( data );
	args = new Array ();
	args.Add ( p );
	Jobs.Run ( "AIServer.Chat", args, JobKey, , TesterCache.Testing () );
	
EndFunction

&AtServer
Function getMessage ( Data )
	
	parts = new Array ();
	weMet = undefined <> findRow ( Object.Data, "_.Me and _.Content = Enums.ContentType.Text and _.ID <> """"" );
	if ( not weMet ) then
		parts.Add ( Output.AssistantInitializationMessage (
			new Structure ( "Name, Email", Object.Creator, DF.Pick ( Object.Creator, "Email" ) ) ) ); 
	endif;
	id = "";
	for each row in Data.Data do
		if ( row.Content <> Enums.ContentType.File ) then
			id = row.ID;
			parts.Add ( row.Text );
			break;
		endif;
	enddo;
	text = StrConcat ( parts, Chars.LF );
	return new Structure ( "Text, ID", text, id );
	
EndFunction

&AtServer
Function getFiles ( Data )
	
	files = new Array ();
	table = Data.Data;
	for each row in table do
		if ( row.Content = Enums.ContentType.File ) then
			files.Add ( new Structure ( "ID, Name", row.ID, row.Text ) );
		endif;
	enddo;
	return files;
	
EndFunction

&AtClient
Procedure startWaiting ( Callback )
	
	Finisher = Callback;
	initSeparator ();
	initStoppingTimeout ();
	AttachIdleHandler ( "checkCompletion", 1 );
	
EndProcedure

&AtClient
Procedure initSeparator ()
	
	Separator = findRow ( Object.Messages, "_.Separator" );
	SeparatorID = ChatForm.ElementID ( findRow ( Object.Data, "_.Separator" ).Element );
	SeparatorText = Separator.Text;
	
EndProcedure

&AtClient
Procedure initStoppingTimeout ()
	
	StoppingTimeout = 3;
	
EndProcedure

&AtClient
Procedure checkCompletion () export
	
	error = undefined;
	if ( jobIsActive ( JobKey, error ) ) then
		reactivateStopping ();
		indicateProcess ();
	else
		DetachIdleHandler ( "checkCompletion" );
		restoreSeparator ();
		RunCallback ( Finisher, error );
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
Procedure reactivateStopping ()

	if ( CurrentStage <> StageStopping ) then
		return;
	endif;
	if ( StoppingTimeout = 0 ) then
		initStoppingTimeout ();
		activateStage ( ThisObject, StageSending );
	else
		StoppingTimeout = StoppingTimeout - 1;
	endif;

EndProcedure

&AtClient
Procedure indicateProcess ()
	
	text = Separator.Text + ".";
	Separator.Text = text;
	if ( not Plaintext ) then
		setElementText ( SeparatorID, text );
	endif;
	
EndProcedure

&AtClient
Procedure setElementText ( ID, Text )
	
	element = Items.HTML.Document.getElementById ( ID );
	if ( element <> undefined ) then
		element.textContent = Text;
	endif;
	
EndProcedure

&AtClient
Procedure restoreSeparator ()
	
	if ( Separator = undefined ) then
		return;
	endif;
	Separator.Text = SeparatorText;
	if ( not Plaintext ) then
		setElementText ( SeparatorID, SeparatorText );
	endif;
	
EndProcedure

&AtClient
Procedure CompleteSending ( Exception, Params ) export
	
	applyAnswer ( Exception );
	flushChanges ();
	scrollMessages ();
	activateMessage ();
	activateStage ( ThisObject, StageComplete );
	
EndProcedure

&AtServer
Procedure applyAnswer ( val Exception )
	
	result = fetchResult ( Exception );
	if ( result = undefined ) then
		return;
	endif;
	Object.Error = result.Error;
	setMyMessageID ( result.MessageID );
	if ( result.Error ) then
		addRow ( ThisObject, StrConcat ( result.Messages, Chars.LF ), true, false, "", Enums.ContentType.Text, false );
		Appearance.Apply ( ThisObject, "Object.Error" );
	else
		Session = result.Session;
		Object.Thread = result.Thread;
		increateLinkID ();
		processFiles ( result );
		processAnswer ( result );
		increateLinkID ();
	endif;
	Write ();
	
EndProcedure

&AtServer
Function fetchResult ( Exception )
	
	result = new Structure ( "Error, Messages, Files, MessageID, Thread, Session",
		false, new Array (), "", "", "" );
	if ( Exception = undefined ) then
		json = GetFromTempStorage ( ResultAddress );
		if ( json = undefined ) then
			return undefined;
		endif;
		response = ReadJSONValue ( json );
		message = response.Message;
		if ( response.Error ) then
			result.Error = true;
			try
				info = ReadJSONValue ( message );
				try
					result.Messages.Add ( info.error.message );
				except
					result.Messages.Add ( info.message );
					result.MessageID = info.MessageID;
					result.Thread = info.Thread;
				endtry;
			except
				result.Messages.Add ( message );
			endtry;
		else
			result.Session = response.Session;
			data = ReadJSONValue ( message );
			result.Messages = data.Messages.data;
			result.Files = data.Files;
			result.Thread = data.Thread;
			result.MessageID = data.MessageID;
		endif;
	else
		result.Error = true;
		result.Messages.Add ( Exception );
	endif;
	return result;
	
EndFunction

&AtServer
Procedure setMyMessageID ( ID )
	
	if ( ID = "" ) then
		return;
	endif;
	info = getMyLastMessage ( ThisObject );
	for each row in info.Data do
		if ( row.Content <> Enums.ContentType.File ) then
			row.ID = ID;
			break;
		endif;
	enddo;
	for each row in info.Messages do
		row.ID = ID;
	enddo;
	
EndProcedure

&AtClientAtServerNoContext
Function getMyLastMessage ( Form )

	filter = "_.Link = " + Format ( Form.LinkID, "NG=0;NZ=0" );
	object = Form.Object;
	data = findRows ( object.Data, filter );
	messages = findRows ( object.Messages, filter );
	return new Structure ( "Data, Messages", data, messages );

EndFunction

&AtClientAtServerNoContext
Function findRow ( Table, Lambda, From = undefined, Backward = true )
	
	size = Table.Count ();
	if ( Backward ) then
		i = ? ( From = undefined, size, From ) - 1;
		end = -1;
		step = -1;
	else
		i = ? ( From = undefined, 1, size ) - 1;
		end = size;
		step = 1;
	endif;
	while ( i <> end ) do
		_ = table [ i ];
		if ( Eval ( Lambda ) ) then
			return _;
		endif;
		i = i + step;
	enddo;
	return undefined;
	
EndFunction

&AtClientAtServerNoContext
Function findRows ( Table, Lambda )
	
	list = new Array ();
	lastRow = undefined;
	while ( true ) do
		row = findRow ( Table, Lambda, ? ( lastRow = undefined, undefined, lastRow.LineNumber - 1 ) );
		if ( row = undefined ) then
			break;
		endif;
		list.Insert ( 0, row );
		lastRow = row;
	enddo;
	return list;
	
EndFunction

&AtClientAtServerNoContext
Procedure addRow ( Form, Text, Error, Me, ID, Content, Separator )
	
	object = Form.Object;
	data = object.Data.Add ();
	link = ? ( Error or Separator, 0, Form.LinkID );
	data.Link = link;
	data.Me = Me;
	data.ID = ID;
	data.Content = Content;
	data.Text = Text;
	data.Error = Error;
	data.Separator = Separator;
	assignElement ( Form, data );
	Form.ChangesQueue.Add ( data.LineNumber - 1 );
	#if ( Client ) then
		Form.flushChanges ();
	#endif
	table = object.Messages;
	for each line in StrSplit ( Text, Chars.LF ) do
		row = table.Add ();
		row.Text = line;
		row.Error = Error;
		row.Separator = Separator;
		row.Me = Me;
		row.Content = Content;
		row.ID = ID;
		row.Link = link;
	enddo;
	invalidateHomepage ( Form );
	Appearance.Update ( Form, "Assistant" );
	
EndProcedure

&AtClientAtServerNoContext
Procedure invalidateHomepage ( Form )

	haveMessages = Form.Object.Data.Count () > 0;
	if ( Form.ChatStarted = haveMessages ) then
		return;
	endif;
	Form.ChatStarted = haveMessages;
	items = Form.Items;
	pages = items.Pages;
	if ( haveMessages ) then
		pages.PagesRepresentation = FormPagesRepresentation.Auto;
		Items.Pages.CurrentPage = ? ( Form.Plaintext, items.GroupText, items.GroupHTML );
	else
		pages.PagesRepresentation = FormPagesRepresentation.None;
		Items.Pages.CurrentPage = items.GroupHomepage;
	endif;
	Appearance.Apply ( Form, "ChatStarted" );

EndProcedure

&AtClient
Procedure addElement () export

	document = Items.HTML.Document;
	if ( document = undefined
		or document.body = undefined ) then
		flushChanges ();
		return;
	endif;
	table = Object.Data;
	for each element in ChangesQueue do
		row = table [ element.Value ];
		document.body.insertAdjacentHTML ( "beforeend", ChatForm.GetParagraph ( Chat, Object, row ) );
		answer = not (
			row.Me
			or row.Separator
			or ( row.Content = PredefinedValue ( "Enum.ContentType.File" ) )
			or row.Error
		);
		if ( answer ) then
			message = document.getElementById ( ChatForm.ElementID ( row.Element ) );
			document.defaultView.Prism.highlightAllUnder ( message );
		endif;
	enddo;
	ChangesQueue.Clear ();
	for each element in DeletionQueue do
		node = document.getElementById ( ChatForm.ElementID ( element.Value ) );
		if ( node <> undefined ) then
			node.parentNode.removeChild ( node );
		endif;
	enddo;
	DeletionQueue.Clear ();

EndProcedure

&AtServer
Procedure processFiles ( Answer )
	
	BeginTransaction ();
	table = Object.Files;
	for each record in Answer.Files do
		row = table.Add ();
		FillPropertyValues ( row, record );
		if ( not record.Picture ) then
			continue;
		endif;
		r = InformationRegisters.ChatPictures.CreateRecordManager ();
		r.ID = record.ID;
		r.Picture = new ValueStorage ( Base64Value ( record.Data.Content ) );
		r.Write ();
	enddo;
	CommitTransaction ();
	
EndProcedure

&AtServer
Procedure processAnswer ( Answer )
	
	messages = Answer.Messages;
	i = messages.UBound ();
	if ( i = -1 ) then
		return;
	endif;
	last = messages [ 0 ];
	files = Object.Files;
	for each row in last.content do
		id = last.id;
		contentType = row.type;
		if ( contentType = "text" ) then
			addRow ( ThisObject, row.text.value, false, false, id, Enums.ContentType.Text, false );
		elsif ( contentType = "image_file" ) then
			addRow ( ThisObject, row.image_file.file_id, false, false, id, Enums.ContentType.Image, false );
		endif;
	enddo;
	
EndProcedure

&AtServer
Procedure increateLinkID ()
	
	LinkID = LinkID + 1;
	
EndProcedure

&AtClient
Procedure flushChanges () export
	
	DetachIdleHandler ( "addElement" );
	AttachIdleHandler ( "addElement", 0.1, true );
	
EndProcedure

&AtClient
Procedure Attach ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	commitMessage ();
	pickFiles ();
	
EndProcedure

&AtClient
Procedure pickFiles ()
	
	OpenForm ( "InformationRegister.AIFiles.ListForm",
		new Structure ( "Filter, Session, ChoiceMode",
			new Structure ( "Server", Server ), Session, true ),
		ThisObject, , , , ,
		FormWindowOpeningMode.LockOwnerWindow );
	
EndProcedure

&AtClient
async Procedure Upload ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	commitMessage ();
	activateStage ( ThisObject, StageSending );
	files = await prepareFiles ();
	if ( files = undefined ) then
		activateStage ( ThisObject, StageComplete );
		return;
	endif;
	uploadData ( files, true );

EndProcedure

&AtClient
Procedure uploadData ( List, Files )

	activateStage ( ThisObject, StageSending );
	if ( Object.Error ) then
		deleteAnswer ( ThisObject );
	else
		addSeparator ( ThisObject, true );
	endif;
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

	try
		list = await PutFilesToServerAsync ( , , new PutFilesDialogParameters ( , true ) );
	except
		error = ErrorProcessing.BriefErrorDescription ( ErrorInfo () );
		Output.MessageBox ( , , new Structure ( "Message", error ) );
	endtry;
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
		descriptor = AIServer.FileDescriptor (
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

	p = AIServer.UploadFilesParams ();
	p.Files = Files;
	ResultAddress = PutToTempStorage ( undefined, UUID );
	p.Result = ResultAddress;
	p.Server = Server;
	p.Session = Session;
	args = new Array ();
	args.Add ( p );
	Jobs.Run ( "AIServer.UploadFiles", args, JobKey, , TesterCache.Testing () );

EndProcedure

&AtClientAtServerNoContext
Procedure deleteAnswer ( Form )
	
	table = Form.Object.Messages;
	row = findRow ( table, "_.Separator" );
	if ( row.Me ) then
		return;
	endif;
	i = table.Count ();
	from = ( row.LineNumber - 1 );
	while ( i > from ) do
		i = i - 1;
		row = table [ i ];
		deleteRow ( Form, row );
	enddo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure deleteRow ( Form, Row )

	filter = new Array ();
	filter.Add ( "_.ID = """ + Row.ID + """" );
	filter.Add ( "_.Me = " + ? ( Row.Me, "true", "false" ) );
	filter.Add ( "_.Separator = " + ? ( Row.Separator, "true", "false" ) );
	filter.Add ( "_.Link = " + Format ( Row.Link, "NG=0;NZ=0" ) );
	object = Form.Object;
	table = object.Data;
	data = findRow ( table, StrConcat ( filter, " and " ) );
	if ( data <> undefined ) then
		Form.DeletionQueue.Add ( data.Element );
		#if ( Client ) then
			Form.flushChanges ();
		#endif
		table.Delete ( data );
	endif;
	object.Messages.Delete ( Row );
	
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
		descriptor = AIServer.FileDescriptor (
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
		applyUploading ( Exception );
		flushChanges ();
	else
		addRow ( ThisObject, Exception, true, true, "",
			PredefinedValue ( "Enum.ContentType.File" ), false );
	endif;
	scrollMessages ();
	activateMessage ();
	activateStage ( ThisObject, StageComplete );
	
EndProcedure

&AtServer
Procedure applyUploading ( val Exception )

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
			addRow ( ThisObject, file.File.Name + ": " + error, true, true, "",
				Enums.ContentType.File, false );
		endif;
	enddo;

EndProcedure

&AtServer
Procedure addFile ( Name, ID )

	addRow ( ThisObject, Name, false, true, ID, Enums.ContentType.File, false );
	
EndProcedure

&AtClient
Procedure AttachDocument ( Command )

	if ( not CheckFilling () ) then
		return;
	endif;
	commitMessage ();
	pickDocuments ();

EndProcedure
	
&AtClient
Procedure pickDocuments ()

	OpenForm ( "Document.Document.ChoiceForm",
		new Structure ( "MultipleChoice", true ),
		ThisObject, , , , ,
		FormWindowOpeningMode.LockOwnerWindow );

EndProcedure
	
&AtClient
Procedure DeleteFile ( Command )
	
	if ( deletionAllowed () ) then
		deleteRow ( ThisObject, Items.Messages.CurrentData );
	endif;
	
EndProcedure

&AtClient
Function deletionAllowed ()
	
	row = Items.Messages.CurrentData;
	if ( row.Content <> PredefinedValue ( "Enum.ContentType.File" ) ) then
		Output.SelectFileForDeletion ();
		return false;
	endif;
	messages = getMyLastMessage ( ThisObject ).Data;
	sent = ( messages.Count () = 0 );
	for each row in messages do
		if ( row.Content <> PredefinedValue ( "Enum.ContentType.File" ) ) then
			sent = row.ID <> "";
			break;
		endif;
	enddo;
	if ( sent and not Object.Error ) then
		Output.FileAlreadySent ();
		return false;
	endif;
	return true;
	
EndFunction

&AtClient
Procedure AssistantOnChange ( Item )
	
	setAssistant ( ThisObject, Object.Assistant );
	
EndProcedure

&AtClient
Procedure activateMessage ()
	
	if ( not Object.Assistant.IsEmpty () ) then
		AttachIdleHandler ( "gentleMessageActivation", 0.1, true );
	endif;
	
EndProcedure

&AtClient
Procedure gentleMessageActivation () export
	
	CurrentItem = Items.Message;
	
EndProcedure

&AtClient
Procedure Stop ( Command )

	if ( stopRunning ( Server, Object.Thread, Session ) ) then
		activateStage ( ThisObject, StageStopping );
	else
		raise Output.RequestToStopFailed ();
	endif;

EndProcedure

&AtServerNoContext
Function stopRunning ( val Server, val Thread, val Session )

	return AIServer.StopRunning ( Server, Thread, Session );
	
EndFunction

&AtClient
Procedure MessageStartChoice ( Item, ChoiceData, ChoiceByAdding, StandardProcessing )
	
	StandardProcessing = false;
	commitMessage ();
	OpenForm ( "CommonForm.Menu", new Structure ( "Menu", FunctionsMenu ), Items.Message );
	
EndProcedure

&AtClient
Procedure commitMessage ()
	
	#if ( WebClient ) then
		Object.Message = Items.Message.EditText;
	#endif
	
EndProcedure

&AtClient
Procedure MessageChoiceProcessing ( Item, Value, AdditionalData, StandardProcessing )
	
	StandardProcessing = false;
	type = TypeOf ( Value );
	if ( type = Type ( "Number" ) ) then
		if ( Value = menuSelectPhrase () ) then
			OpenForm ( "Catalog.Phrases.ChoiceForm", , Items.Message );
		elsif ( Value = menuUploadFile () ) then
			Upload ( undefined );
		elsif ( Value = menuAttachFile () ) then
			Attach ( undefined );
		elsif ( Value = menuAttachDocument () ) then
			AttachDocument ( undefined );
		elsif ( Value = menuDeleteFile () ) then
			DeleteFile ( undefined );
		endif;
	elsif ( type = Type ( "CatalogRef.Phrases" ) ) then
		injectPhrase ( Value );
	else
		setAssistant ( ThisObject, Value );
		activateMessage ();
	endif;

EndProcedure

&AtClient
Procedure injectPhrase ( Phrase )
	
	Items.Message.SelectedText = DF.Pick ( Phrase, "Text" );
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange ( Item, CurrentPage )
	
	changePage ();
	activateMessage ();
	
EndProcedure

&AtClient
Procedure changePage ()
	
	Plaintext = not Plaintext;
	saveChatView ( Plaintext );
	scrollMessages ();
	
EndProcedure

&AtServerNoContext
Procedure saveChatView ( val Plaintext )

	LoginsSrv.SaveSettings ( Enum.SettingsChatInPlaintext (), , Plaintext );

EndProcedure

// *****************************************
// *********** Table Messages

&AtClient
async Procedure MessagesSelection ( Item, RowSelected, Field, StandardProcessing )
	
	StandardProcessing = false;
	if ( not await openLink () ) then
		augmentMessage ();
	endif;
	
EndProcedure

&AtClient
async Function openLink ()
	
	row = Items.Messages.CurrentData.Text;
	links = getLinks ( row );
	count = links.Count ();
	if ( count = 0 ) then
		return false;
	elsif ( count = 1 ) then
		GotoURL ( links [ 0 ].Value );
		return true;
	endif;
	menu = await ChooseFromMenuAsync ( links, Items.Messages );
	if ( menu = undefined ) then
		return false;
	else
		GotoURL ( menu.Value );
		return true;
	endif;
	
EndFunction

&AtServerNoContext
Function getLinks ( val Message )
	
	links = new ValueList ();
	// This regular expression splits the following string:
	// source: [Vendor Information](http://65.94.42.138/us/60B3CD67EB/#e1cib/data/Catalog.Organizations?ref=936516b38455d1004bc4360ffd0daa0c)
	// result: Vendor Information | http://65.94.42.138/us/60B3CD67EB/#e1cib/data/Catalog.Organizations?ref=936516b38455d1004bc4360ffd0daa0c
	template = "(\[[^\]]+\])\((http[^\)]+)\)";
	list = StrFindAllByRegularExpression ( Message, template );
	for each item in list do
		set = item.GetGroups ();
		links.Add ( set [ 1 ].Value, set [ 0 ].Value );
	enddo;
	return links;
	
EndFunction

&AtClient
Procedure augmentMessage ()
	
	table = Items.Messages;
	list = new ValueList ();
	for each id in table.SelectedRows do
		row = table.RowData ( id );
		list.Add ( row.LineNumber, row.Text );
	enddo;
	text = new Array ();
	list.SortByValue ();
	for each value in list do
		text.Add ( value.Presentation );
	enddo;
	content = StrConcat ( text, Chars.LF );
	if ( Object.Message = "" ) then
		Object.Message = content;
	else
		Object.Message = Object.Message + Chars.LF + content;
	endif;
	Modified = true;
	
EndProcedure

// *****************************************
// *********** Page HTML

&AtClient
Procedure HTMLDocumentComplete ( Item )
	
	if ( windowPinned () ) then
		restoreHTML ();
	else
		scrollHTML ();
	endif;
	
EndProcedure

&AtClient
Function windowPinned ()
	
	return Items.HTML.Document.body.children.length = 0;
	
EndFunction

&AtServer
Procedure restoreHTML ()

	ChatForm.SetBody ( Chat, Object );

EndProcedure

&AtClient
Procedure HTMLOnClick ( Item, EventData, StandardProcessing )
	
	StandardProcessing = false;
	ChatForm.OnClick ( filesList (), Server, Session, Item, EventData );
	
EndProcedure

&AtClient
Function filesList ()
	
	list = new ValueList ();
	for each row in Object.Files do
		list.Add ( row.ID, row.Link );
	enddo;
	return list;
	
EndFunction