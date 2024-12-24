// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	filterFiles ();
	setFilter ();
	readID ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure filterFiles ()
	
	DC.SetParameter ( Files, "Server", Object.Server );
	ids = new Array ();
	creators = new Array ();
	for each row in Object.Files do
		ids.Add ( row.ID );
		creators.Add ( row.Login );
	enddo;
	DC.SetParameter ( Files, "Logins", creators );
	DC.SetParameter ( Files, "IDs", ids );
	
EndProcedure

&AtServer
Procedure setFilter ()

	tenants = new Array ();
	tenants.Add ( Catalogs.Tenants.EmptyRef () );
	if ( not Object.Tenant.IsEmpty () ) then
		tenants.Add ( Object.Tenant );
	endif;
	list = new Array ();
	list.Add ( new ChoiceParameter ( "Filter.Tenant", new FixedArray ( tenants ) ) );
	Items.InstructionsInstruction.ChoiceParameters = new FixedArray ( list );

EndProcedure

&AtServer
Procedure readID ()
	
	obj = FormAttributeToValue ( "Assistant" );
	obj.Assistant = Object.Ref;
	obj.Read ();
	ValueToFormAttribute ( obj, "Assistant" );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
		filterFiles ();
		setFilter ();
	endif; 
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	Sysadmin = Logins.Sysadmin ();
	Login = SessionParameters.Login;
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormReDeploy show filled ( Object.Ref );
	|DeployWarning show not ( Assistant.Synced or Object.DeletionMark ) and filled ( Assistant.ID );
	|RemovedWarning show not Assistant.Synced and Object.DeletionMark and filled ( Assistant.ID )
	|	and Object.Provider = Enum.AIProviders.OpenAI;
	|AssistantID show filled ( Assistant.ID );
	|Tenant lock filled ( Assistant.ID ) or not Sysadmin;
	|CodeInterpreter Retrieval Attach AttachDocument Delete Upload Files
	|	show Object.Provider = Enum.AIProviders.OpenAI;
	|Provider lock filled ( Object.Ref );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()

	if ( Logins.Sysadmin () ) then
		Object.Tenant = undefined;
	else
		Object.Tenant = SessionParameters.Tenant;
	endif;
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	if ( Deploying ) then
		return;
	endif;
	if ( not CheckFilling () ) then
		Cancel = true;
		return;
	endif;
	if ( not Assistant.Synced ) then
		Cancel = true;
		deploy ();
	endif;
	
EndProcedure

&AtClient
Procedure deploy ()
	
	Deploying = true;
	if ( Modified ) then
		Write ();
	endif;
	if ( Object.DeletionMark and
		Object.Provider = PredefinedValue ( "Enum.AIProviders.Anthropic" ) ) then
		return;
	endif;
	run ( Object.Ref, Object.DeletionMark, JobKey );
	Progress.Open ( JobKey, ThisObject, new CallbackDescription ( "DeploymentComplete", ThisObject ), true );
	
EndProcedure

&AtServerNoContext
Procedure run ( val Ref, val DeletionMark, val JobKey )
	
	args = new Array ();
	if ( DeletionMark ) then
		p = AIServer.DeleteAssistantParams ();
		job = "AIServer.DeleteAssistant";
	else
		p = AIServer.DeployAssistantParams ();
		job = "AIServer.DeployAssistant";
	endif;
	p.Assistant = Ref;
	args.Add ( p );
	Jobs.Run ( job, args, JobKey, , TesterCache.Testing () );
	
EndProcedure

&AtClient
Procedure DeploymentComplete ( Result, Params ) export
	
	Deploying = false;
	readID ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( not Assistant.Synced ) then
		Catalogs.Assistants.Unsync ( Object.Ref );
	endif;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure FieldOnChange ( Item )

	dirty ( ThisObject );

EndProcedure

&AtClientAtServerNoContext
Procedure dirty ( Form )
	
	Form.Assistant.Synced = false;
	Appearance.Apply ( Form, "Assistant.Synced" );
	
EndProcedure

&AtClient
Procedure InstructionsInstructionOnChange ( Item )
	
	dirty ( ThisObject );
	
EndProcedure

&AtClient
Procedure ReDeploy ( Command )

	dirty ( ThisObject );
	Write ();

EndProcedure

&AtClient
Procedure ProviderOnChange ( Item )
	
	applyProvider ();
	
EndProcedure

&AtClient
Procedure applyProvider ()
	
	if ( Object.Provider = PredefinedValue ( "Enum.AIProviders.Anthropic" ) ) then
		Object.CodeInterpreter = false;
		Object.Retrieval = false;
	endif;
	AssistantsForm.AdjustTemperature ( ThisObject, true );
	dirty ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Provider" );
	
EndProcedure

// *****************************************
// *********** Table Instructions

&AtClient
Procedure TenantOnChange ( Item )
	
	applyTenant ();
	
EndProcedure

&AtServer
Procedure applyTenant ()

	cleanInstructions ();
	setFilter ();
	dirty ( ThisObject );

EndProcedure

&AtServer
Procedure cleanInstructions ()

	for each row in Object.Instructions do
		row.Instruction = undefined;
	enddo;

EndProcedure

// *****************************************
// *********** Table Files

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
		new Structure ( "Filter, ChoiceMode", new Structure ( "Server", Object.Server ), true ),
		Items.Files,,,,, FormWindowOpeningMode.LockOwnerWindow );
	
EndProcedure

&AtClient
async Procedure Upload ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif;
	set = await prepareFiles ();
	if ( set = undefined ) then
		return;
	endif;
	uploadData ( set, true );

EndProcedure

&AtClient
Procedure uploadData ( List, FromFiles )

	JobKey = "Uploading " + UUID;
	if ( FromFiles ) then
		transferFiles ( List );
	else
		transferDocuments ( List );
	endif;
	Progress.Open ( JobKey, ThisObject, new CallbackDescription ( "CompleteUploading", ThisObject ), true );

EndProcedure

&AtClient
async Function prepareFiles ()

	list = await PutFilesToServerAsync ( , , new PutFilesDialogParameters ( , true ) );
	if ( list = undefined ) then
		return undefined;
	endif;
	set = Attachments.GetStoredFiles ( list );
	return ? ( set.Count () = 0, undefined, set );

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
	p.Server = Object.Server;
	args = new Array ();
	args.Add ( p );
	Jobs.Run ( "AIServer.UploadFiles", args, JobKey, , TesterCache.Testing () );

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
	set = new Array ();
	for each row in table do
		name = row.Name;
		file = CKEditorSrv.GetFolder ( row.Folder ) + separator + name;
		descriptor = AIServer.FileDescriptor (
			name,
			row.Size,
			new BinaryData ( file )
		);
		set.Add ( descriptor );
	enddo;
	startUploadingJob ( set );
	
EndProcedure

&AtClient
Procedure CompleteUploading ( Result, Params ) export
	
	if ( not Result ) then
		return;
	endif;
	data = GetFromTempStorage ( ResultAddress );
	if ( data = undefined ) then
		return;
	endif;
	isDirty = false;
	for each file in data.Files do
		error = file.Error;
		if ( error = "" ) then
			addFile ( file.ID );
			isDirty = true;
		else
			Output.Error ( new Structure ( "Error", file.File.Name + ": " + error ) );
		endif;
	enddo;
	if ( isDirty ) then
		dirty ( ThisObject );
		filterFiles ();
		Items.Files.Refresh ();
	endif;
	
EndProcedure

&AtClient
Procedure addFile ( ID )

	row = Object.Files.Add ();
	row.Login = Login;
	row.ID = ID;
	
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
		Items.Files,,,,,
		FormWindowOpeningMode.LockOwnerWindow );

EndProcedure

&AtClient
Procedure FilesChoiceProcessing ( Item, Set, StandardProcessing )

	StandardProcessing = false;
	if ( TypeOf ( Set [ 0 ] ) = Type ( "DocumentRef.Document" ) ) then
		uploadData ( Set, false );
	else
		loadFiles ( Set );
	endif;

EndProcedure

&AtClient
Procedure loadFiles ( List )

	if ( List.Count () = 0 ) then
		return;
	endif;
	for each file in List do
		addFile ( file.ID );
	enddo;
	dirty ( ThisObject );
	filterFiles ();
	Items.Files.Refresh ();

EndProcedure

&AtClient
Procedure Delete ( Command )

	row = Items.Files.CurrentData;
	if ( row = undefined ) then
		return;
	endif;
	table = Object.Files;
	rows = table.FindRows ( new Structure ( "Login, ID", Login, row.ID ) );
	table.Delete ( rows [ 0 ] );
	dirty ( ThisObject );
	filterFiles ();
	Items.Files.Refresh ();

EndProcedure
