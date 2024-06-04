// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	initFilters ();
	filterByLogin ();
	filterByServer ();
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure initFilters ()
	
	LoginFilter = SessionParameters.Login;
	if ( Parameters.Filter.Property ( "Server", FixedServerFilter ) ) then
		ServerFilter = FixedServerFilter;
	endif;
	
EndProcedure

&AtServer
Procedure filterByLogin ()
	
	DC.ChangeFilter ( List, "Login", LoginFilter, not LoginFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "LoginFilter" );
	
EndProcedure

&AtServer
Procedure filterByServer ()
	
	DC.ChangeFilter ( List, "Server", ServerFilter, not ServerFilter.IsEmpty () );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Login show empty ( LoginFilter );
	|ServerFilter show empty ( FixedServerFilter );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Select ( Command )

	choose ();

EndProcedure

&AtClient
Procedure choose ()
	
	files = new Array ();
	for each row in Items.List.SelectedRows do
		data = Items.List.RowData ( row );
		files.Add ( new Structure ( "Name, ID", data.Name, data.ID ) );
	enddo;
	if ( files.Count () > 0 ) then
		NotifyChoice ( files );
	endif;
	
EndProcedure

&AtClient
async Procedure Remove ( Command )

	row = Items.List.CurrentData;
	if ( row = undefined ) then
		return;
	endif;
	delete ( false );

EndProcedure

&AtClient
async Procedure delete ( Hard )
	
	if ( Hard ) then
		answer = await Output.RemoveFilesConfirmationAsync ();
		if ( answer = DialogReturnCode.Yes ) then
			JobKey = "Deleting " + UUID;
			runDeletion ( filesList () );
			Progress.Open ( JobKey, ThisObject, new CallBackDescription ( "DeletionComplete", ThisObject ), true );
		endif;
	else
		answer = await Output.RemoveFilesFromListConfirmationAsync ();
		if ( answer = DialogReturnCode.Yes ) then
			truncate ();
			Items.List.Refresh ();
		endif;
	endif;
	
EndProcedure

&AtClient
Function filesList ()
	
	files = new Array ();
	table = Items.List;
	for each id in table.SelectedRows do
		data = table.RowData ( id );
		files.Add ( new Structure ( "Login, ID, Name",
			data.Login, data.ID, data.Name ) );
	enddo;
	return files;
	
EndFunction

&AtServer
Procedure runDeletion ( val Files )
	
	p = AIServer.DropFilesParams ();
	p.Files = Files;
	p.Server = ServerFilter;
	p.Session = Parameters.Session;
	args = new Array ();
	args.Add ( p );
	Jobs.Run ( "AIServer.DropFiles", args, JobKey, , TesterCache.Testing () );
	
EndProcedure

&AtServer
Procedure truncate ()
	
	batch = Enum.StandardTransactionBatch ();
	counter = 0;
	BeginTransaction ();
	for each record in Items.List.SelectedRows do
		entry = InformationRegisters.AIFiles.CreateRecordManager ();
		FillPropertyValues ( entry, record, "Login, ID, Server" );
		entry.Delete ();
		counter = counter + 1;
		if ( counter = batch ) then
			counter = 0;
			CommitTransaction ();
			BeginTransaction ();
		endif;
	enddo;
	CommitTransaction ();
	
EndProcedure

&AtClient
Procedure LoginFilterOnChange ( Item )
	
	filterByLogin ();
	
EndProcedure

&AtClient
Procedure ServerFilterOnChange ( Item )

	filterByServer ();

EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ListValueChoice ( Item, Value, StandardProcessing )
	
	StandardProcessing = false;
	choose ();
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	if ( CheckFilling () ) then
		upload ();
	endif;
	
EndProcedure

&AtClient
async Procedure upload ()

	files = await prepareFiles ();
	if ( files = undefined ) then
		return;
	endif;
	JobKey = "Uploading " + UUID;
	runUploading ( files );
	Progress.Open ( JobKey, ThisObject,
		new CallBackDescription ( "UploadingComplete", ThisObject ), true );

EndProcedure

&AtClient
async Function prepareFiles ()

	files = await PutFilesToServerAsync ( , , new PutFilesDialogParameters ( , true ) );
	if ( files = undefined ) then
		return undefined;
	endif;
	stored = Attachments.GetStoredFiles ( files );
	return ? ( stored.Count () = 0, undefined, stored );

EndFunction

&AtServer
Procedure runUploading ( val Files )
	
	set = new Array ();
	for each file in Files do
		set.Add ( new Structure ( "Name, Size, Data", file.Name, file.Size,
			GetFromTempStorage ( file.Address ) ) );
	enddo;
	p = AIServer.UploadFilesParams ();
	p.Files = set;
	ResultAddress = PutToTempStorage ( undefined, UUID );
	p.Result = ResultAddress;
	p.Server = ServerFilter;
	p.Session = Session;
	args = new Array ();
	args.Add ( p );
	Jobs.Run ( "AIServer.UploadFiles", args, JobKey, , TesterCache.Testing () );
	
EndProcedure

&AtClient
Procedure UploadingComplete ( Complete, Params ) export
	
	if ( not Complete ) then
		return;
	endif;
	data = GetFromTempStorage ( ResultAddress) ;
	if ( data = undefined ) then
		return;
	endif;
	lastFile = undefined;
	Session = data.Session;
	for each file in data.Files do
		error = file.Error;
		if ( error = "" ) then
			lastFile = file.ID;
		else
			showError ( file.File.Name + ": " + error );
		endif;
	enddo;
	activateFile ( lastFile );
	
EndProcedure

&AtClient
Procedure activateFile ( File )
	
	if ( File = undefined ) then
		return;
	endif;
	control = Items.List;
	CurrentItem = control;
	control.Refresh ();
	control.CurrentRow = fileKey ( File, ServerFilter );
	
EndProcedure

&AtServerNoContext
Function fileKey ( val ID, val Server )
	
	record = new Structure ( "Login, ID, Server", SessionParameters.Login, Server, ID, Server );
	return InformationRegisters.AIFiles.CreateRecordKey ( record );
	
EndFunction

&AtClient
Procedure showError ( Text )
	
	Output.Error ( new Structure ( "Error", text ) );
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	if ( CheckFilling () ) then
		delete ( true );
	endif;
	
EndProcedure

&AtClient
Procedure DeletionComplete ( Result, Params ) export
	
	Items.List.Refresh ();
	
EndProcedure
