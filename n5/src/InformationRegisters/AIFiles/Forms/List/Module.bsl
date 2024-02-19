// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	initFilter ();
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure initFilter ()
	
	CreatorFilter = SessionParameters.User;
	filterByCreator ();
	
EndProcedure

&AtServer
Procedure filterByCreator ()
	
	DC.ChangeFilter ( List, "Creator", CreatorFilter, not CreatorFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "CreatorFilter" );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Creator show empty ( CreatorFilter );
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
			JobKey = "Uploading " + UUID;
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
		files.Add ( new Structure ( "ID, Name", data.ID, data.Name ) );
	enddo;
	return files;
	
EndFunction

&AtServer
Procedure runDeletion ( val Files )
	
	p = DataProcessors.DeleteFromAI.GetParams ();
	p.Files = Files;
	p.Assistant = Parameters.Assistant;
	p.Session = Parameters.Session;
	args = new Array ();
	args.Add ( "DeleteFromAI" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, JobKey, , TesterCache.Testing () );
	
EndProcedure

&AtServer
Procedure truncate ()
	
	batch = Enum.StandardTransactionBatch ();
	counter = 0;
	BeginTransaction ();
	for each record in Items.List.SelectedRows do
		entry = InformationRegisters.AIFiles.CreateRecordManager ();
		FillPropertyValues ( entry, record, "Creator, ID" );
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
Procedure CreatorFilterOnChange ( Item )
	
	filterByCreator ();
	
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
	upload ();
	
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
	p = DataProcessors.UploadToAI.GetParams ();
	p.Files = set;
	ResultAddress = PutToTempStorage ( undefined, UUID );
	p.Result = ResultAddress;
	p.Assistant = Parameters.Assistant;
	p.Session = Session;
	args = new Array ();
	args.Add ( "UploadToAI" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, JobKey, , TesterCache.Testing () );
	
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
	control.CurrentRow = fileKey ( File );
	
EndProcedure

&AtServerNoContext
Function fileKey ( val ID )
	
	record = new Structure ( "Creator, ID", SessionParameters.User, ID );
	return InformationRegisters.AIFiles.CreateRecordKey ( record );
	
EndFunction

&AtClient
Procedure showError ( Text )
	
	Output.Error ( new Structure ( "Error", text ) );
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	delete ( true );
	
EndProcedure

&AtClient
Procedure DeletionComplete ( Result, Params ) export
	
	Items.List.Refresh ();
	
EndProcedure
