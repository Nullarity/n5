&AtClient
Function GetParams () export
	
	p = new Structure ();
	p.Insert ( "Command" );
	p.Insert ( "Control" );
	p.Insert ( "Table" );
	p.Insert ( "FolderID" );
	p.Insert ( "Folder" );
	p.Insert ( "Ref" );
	p.Insert ( "Mailbox" );
	p.Insert ( "Files" );
	p.Insert ( "Form" );
	return p;
	
EndFunction 

&AtClient
Procedure UserFolder ( FolderID, Callback ) export
	
	folder = AttachmentsSrv.UserFolder ();
	p = new Structure ( "FolderID, Callback, Folder", FolderID, Callback );
	if ( ValueIsFilled ( folder ) ) then
		p.Folder = folder;
		bridge = new NotifyDescription ( "UserFolderExists", ThisObject, p );
		LocalFiles.CheckExistence ( folder, bridge );
	else
		if ( TemporaryFolder = undefined ) then
			callback = new NotifyDescription ( "UserTempFolder", ThisObject, p );
			LocalFiles.SetTempFolder ( callback );
		else
			p.Folder = TemporaryFolder;
			bridge = new NotifyDescription ( "UserFolderExists", ThisObject, p );
			ExecuteNotifyProcessing ( bridge, true );
		endif; 
	endif;

EndProcedure

&AtClient
Procedure UserFolderExists ( Exists, Params ) export
	
	if ( Exists ) then
		folder = Params.Folder + "\" + Params.FolderID;
		ExecuteNotifyProcessing ( Params.Callback, folder );
	else
		callback = new NotifyDescription ( "UserTempFolder", ThisObject, Params );
		LocalFiles.SetTempFolder ( callback );
	endif;
	
EndProcedure 

&AtClient
Procedure UserTempFolder ( Result, Params ) export
	
	folder = TemporaryFolder + "\" + Params.FolderID;
	ExecuteNotifyProcessing ( Params.Callback, folder );
	
EndProcedure 

&AtClient
Procedure Command ( Params ) export
	
	command = Params.Command;
	if ( command = Enum.AttachmentsCommandsPrint ()
		or command = Enum.AttachmentsCommandsShow ()
		or command = Enum.AttachmentsCommandsDownload ()
		or command = Enum.AttachmentsCommandsRun () ) then
		if ( not fileSelected ( Params ) ) then
			return;
		endif;
	endif;
	#if ( WebClient ) then
		if ( Params.Command = Enum.AttachmentsCommandsPrint () ) then
			Output.WebclientIsNotSupported ();
			return;
		endif;
	#endif
	if ( Params.FolderID = undefined ) then
		fetch ( Params );
	else
		proceedCommand ( Params );
	endif; 
	
EndProcedure 

&AtClient
Function fileSelected ( Params )
	
	control = Params.Control;
	if ( control <> undefined
		and control.CurrentData = undefined ) then
		Output.SelectFile ();
		return false;
	else
		return true;
	endif;
	
EndFunction

&AtClient
Procedure fetch ( Params )
	
	info = AttachmentsSrv.Fetch ( Params.Ref );
	if ( Params.Command = Enum.AttachmentsCommandsPrint () ) then
		removeNonprint ( info.Table );
	endif; 
	p = new Structure ( "Source, Info", Params, info );
	callback = new NotifyDescription ( "SelectFiles", ThisObject, p );
	Attachments.UserFolder ( info.FolderID, callback );
	
EndProcedure 

&AtClient
Procedure removeNonprint ( Files )
	
	i = Files.Count ();
	while ( i > 0 ) do
		i = i - 1;
		file = Files [ i ];
		if ( not FileSystem.Printable ( File.File ) ) then
			Files.Delete ( i );
		endif; 
	enddo; 

EndProcedure 

&AtClient
Procedure SelectFiles ( Folder, Params ) export
	
	info = Params.Info;
	source = Params.Source;
	source.Folder = Folder;
	source.FolderID = info.FolderID;
	source.Files = new Array ();
	command = source.Command;
	if ( info.Table.Count () <= 1
		or command = Enum.AttachmentsCommandsDownloadAll () ) then
		files = source.Files;
		for each row in info.Table do
			files.Add ( row.File );
		enddo; 
		proceedCommand ( source );
	else
		callback = new NotifyDescription ( "FileFromList", ThisObject, Params );
		p = new Structure ();
		p.Insert ( "Files", info.Table );
		p.Insert ( "Command", Enum.DocumentFilesCommandsSelect () );
		OpenForm ( "Document.Document.Form.Files", p, ThisObject, , , , callback );
	endif; 
	
EndProcedure 

&AtClient
Procedure proceedCommand ( Params )
	
	command = Params.Command;
	if ( command = Enum.AttachmentsCommandsPrint ()
		and Params.Control <> undefined ) then
		removeNonprint ( Params.Table );
	endif;
	if ( command = Enum.AttachmentsCommandsUpload ()
		or attachmentExists ( Params ) ) then
		LocalFiles.Prepare ( new NotifyDescription ( "StartCommand", ThisObject, Params ) );
	else
		if ( command = Enum.AttachmentsCommandsPrint () ) then
			Output.PrintedFilesNotFound ();
		else
			Output.FileNotSelected ();
		endif; 
	endif;
	
EndProcedure 

&AtClient
Function attachmentExists ( Params )
	
	return ( Params.Table <> undefined and Params.Table.Count () <> 0 )
	or ( Params.Files <> undefined and Params.Files.Count () <> 0 );
	
EndFunction 

&AtClient
Procedure FileFromList ( Files, Params ) export
	
	if ( Files = undefined ) then
		return;
	endif; 
	source = Params.Source;
	list = source.Files;
	for each file in Files do
		list.Add ( file );
	enddo; 
	proceedCommand ( source );
	
EndProcedure 

&AtClient
Procedure StartCommand ( Result, Params ) export
	
	command = Params.Command;
	if ( command = Enum.AttachmentsCommandsShow () ) then
		preview = previewData ( Params );
		if ( preview <> undefined ) then
			OpenForm ( "CommonForm.Preview", preview, , preview.File );
			return;
		endif;
	endif; 
	if ( command = Enum.AttachmentsCommandsUpload () ) then
		dialog = new FileDialog ( FileDialogMode.Open );
		dialog.Multiselect = true;
		dialog.Show ( new NotifyDescription ( "SelectUploadingFiles", ThisObject, Params ) );
	else
		if ( Params.Folder = undefined ) then
			dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
			dialog.Show ( new NotifyDescription ( "SelectFolder", ThisObject, Params ) );
		else
			performCommand ( Params );
		endif; 
	endif;
	
EndProcedure 

&AtClient
Function previewData ( Params )
	
	file = previewFile ( Params );
	if ( PreviewSupported ( file ) ) then
		result = new Structure ( "Address, URL, Path, File" );
		result.Address = AttachmentsSrv.GetFile ( Params.FolderID, file, Params.Mailbox, Params.Form.UUID );
		result.File = file;
		return result;
	else
		return undefined;
	endif;

EndFunction 

Function PreviewSupported ( File ) export
	
	#if ( Server ) then
		web = Environment.WebClient ();
	#elsif ( WebClient ) then
		web = true;
	#else
		web = false;
	#endif
	#if ( Server ) then
		inCloud = Cloud.Cloud ();
	#else
		inCloud = SessionInfo.Cloud;
	#endif
	if ( web ) then
		yes = FileSystem.Picture ( File )
		or FileSystem.PlainText ( File )
		or FileSystem.HyperText ( File )
		or FileSystem.GoogleDoc ( File )
		or ( FileSystem.OfficeDoc ( File )
			and inCloud );
	else
		yes = FileSystem.Picture ( File )
		or FileSystem.PlainText ( File )
		or FileSystem.HyperText ( File );
	endif;
	return yes;	
	
EndFunction

&AtClient
Function previewFile ( Params )
	
	control = Params.Control;
	files = Params.Files;
	if ( control = undefined ) then
		return files [ 0 ];
	else
		rows = control.SelectedRows;
		if ( rows.Count () = 1 ) then
			return control.RowData ( rows [ 0 ] ).File;
		endif;
	endif; 
	
EndFunction 

&AtClient
async Procedure SelectUploadingFiles ( Files, Params ) export
	
	if ( Files = undefined ) then
		return;
	endif; 
	links = new Array ();
	for each file in Files do
		links.Add ( new TransferableFileDescription ( file ) );
	enddo;
	stored = await PutFilesToServerAsync ( , , links );
	if ( stored = undefined ) then
		return;
	endif;
	list = getStoredFiles ( stored );
	data = AttachmentsSrv.UploadFiles ( list, Params.Ref, Params.FolderID );
	table = Params.Table;
	control = Params.Control;
	ditry = Params.Ref.IsEmpty ();
	for each file in data do
		fileName = file.File;
		search = table.FindRows ( new Structure ( "File", fileName ) );
		if ( search.Count () = 0 ) then
			row = table.Add ();
			FillPropertyValues ( row, file );
			row.Dirty = ditry;
			control.CurrentRow = row.GetID ();
		else
			control.CurrentRow = search [ 0 ].GetID ();
		endif; 
	enddo;
	#if ( WebClient ) then
		// https://github.com/Contabilizare/c5/issues/25
		control.Refresh ();
	#endif
	
EndProcedure

&AtClient
Procedure SelectFolder ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	Params.Folder = Result [ 0 ];
	performCommand ( Params );
	
EndProcedure 

&AtClient
Procedure performCommand ( Params )
	
	files = getSelectedFiles ( Params );
	folder = Params.Folder + GetPathSeparator ();
	counter = new Structure ( "Current, Last", 0, files.Count () );
	storage = new UUID ();
	for each file in files do
		p = new Structure ();
		p.Insert ( "Storage", storage );
		p.Insert ( "Counter", counter );
		p.Insert ( "Source", Params );
		p.Insert ( "Folder", folder );
		p.Insert ( "File", file );
		p.Insert ( "Path", folder + file );
		callback = new NotifyDescription ( "CheckExistence", ThisObject, p );
		LocalFiles.CheckExistence ( p.Path, callback );
	enddo; 
	
EndProcedure 

&AtClient
Function getSelectedFiles ( Params )
	
	if ( Params.Control = undefined ) then
		return Params.Files;
	endif;
	data = new Array ();
	if ( Params.Command = Enum.AttachmentsCommandsDownloadAll () ) then
		for each attachment in Params.Table do
			data.Add ( attachment.File );
		enddo; 
	else
		item = Params.Control;
		if ( item.SelectedRows.Count () = 0 ) then
			data.Add ( Params.Table [ 0 ].File );
		else
			for each attachment in item.SelectedRows do
				data.Add ( item.RowData ( attachment ).File );
			enddo; 
		endif; 
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure CheckExistence ( Exists, Params ) export
	
	if ( Exists ) then
		file = new File ( Params.Path );
		file.BeginGettingModificationTime ( new NotifyDescription ( "ModificationTime", ThisObject, Params ) );
	else
		downloadFile ( Params );
	endif; 
	
EndProcedure 

&AtClient
Procedure ModificationTime ( Time, Params ) export
	
	command = Params.Source.Command;
	if ( command = Enum.AttachmentsCommandsRun ()
		or command = Enum.AttachmentsCommandsPrint () ) then
		stamp = AttachmentsSrv.Timestamp ( Params.Source.Ref, Params.File );
		modified = SessionDate ( Time );
		if ( modified > stamp.Downloaded ) then
			if ( modified < stamp.Uploaded ) then
				OpenForm ( "Document.Document.Form.Replace", , , , , , new NotifyDescription ( "ReplaceQuestion", ThisObject, Params ) );
			else
				runCommand ( Params, true );
			endif; 
		else
			downloadFile ( Params );
		endif;
	else
		Output.ReplaceFile ( ThisObject, Params, new Structure ( "File", Params.File ) );
	endif; 
	
EndProcedure 

&AtClient
Procedure ReplaceFile ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		downloadFile ( Params );
	else
		runCommand ( Params, true );
	endif; 
	
EndProcedure 

&AtClient
Procedure ReplaceQuestion ( Answer, Params ) export
	
	if ( Answer = undefined
		or Answer = DialogReturnCode.Cancel ) then
		return;
	elsif ( Answer = DialogReturnCode.Yes ) then
		downloadFile ( Params );
	else
		runCommand ( Params );
	endif; 
	
EndProcedure 

&AtClient
async Procedure downloadFile ( Params )
	
	caller = Params.Source;
	file = Params.File;
	url = AttachmentsSrv.URL ( file, caller.FolderID, caller.Mailbox, Params.Storage );
	address = url.Address;
	await GetFileFromServerAsync ( address, Params.Path );
	DeleteFromTempStorage ( address );
	AttachmentsSrv.CommitDownloading ( Params.Source.Ref, file );
	runCommand ( Params );
		
EndProcedure 

&AtClient
Procedure runCommand ( Params, UsedLocalFile = false )
	
	counter = Params.Counter;
	counter.Current = counter.Current + 1;
	lastFile = ( counter.Current = counter.Last );
	command = Params.Source.Command;
	if ( UsedLocalFile ) then
		Output.LocalFileUsed ( new Structure ( "File", Params.File ), , PictureLib.Info32 );
	endif; 
	if ( command = Enum.AttachmentsCommandsRun () ) then
		RunAppAsync ( Params.Path );
	elsif ( command = Enum.AttachmentsCommandsPrint () ) then
		print ( Params );
	else
		if ( lastFile ) then
			#if ( WebClient ) then
				if ( Framework.IsLinux () ) then
					return;
				endif;
			#endif
			Output.OpenDownloadsFolder ( ThisObject, Params.Folder );
		endif; 
	endif; 
	
EndProcedure 

&AtClient
Procedure print ( Params )
	
	ext = FileSystem.GetExtension ( Params.File );
	if ( ext = "grs" ) then
		printSchema ( Params );
	elsif ( ext = "mxl" ) then
		printSpreadsheet ( Params );
	else
		printFile ( Params );
	endif;
	
EndProcedure 

&AtClient
Procedure printSchema ( Params )
	
	#if ( MobileClient ) then
		raise Output.PreviewNotSupported ();
	#else
		schema = new GraphicalSchema (); 
		schema.Read ( Params.Path );
		schema.Print ();
	#endif
		
EndProcedure 

&AtClient
Procedure printSpreadsheet ( Params )
	
	t = new SpreadsheetDocument ();
	t.Read ( Params.Path );
	t.Print ();
		
EndProcedure 

&AtClient
Procedure printFile ( Params )
	
	#if ( MobileClient ) then
		raise Output.PreviewNotSupported ();
	#else
		shell = new COMObject ( "Shell.Application" );
		shell.ShellExecute ( Params.Path, "", "", "print", 1 );
	#endif
	
EndProcedure 

&AtClient
Procedure OpenDownloadsFolder ( Answer, Folder ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	if ( Framework.IsLinux () ) then
		try
			RunAppAsync ( "xdg-open " + Folder );
		except
		endtry;
	else
		RunAppAsync ( Folder );
	endif;
	
EndProcedure 

&AtClient
Procedure Remove ( Params ) export
	
	if ( fileSelected ( Params )
		and attachmentExists ( Params ) ) then
		Output.RemoveAttachmentConfirmation ( ThisObject, Params );
	endif; 
	
EndProcedure

&AtClient
Procedure RemoveAttachmentConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif; 
	rows = Params.Control.SelectedRows;
	table = Params.Table;
	files = new Array ();
	specialPreview = ( Params.Mailbox = undefined );
	for each index in rows do
		row = table.FindByID ( index );
		files.Add ( new Structure ( "Name, ID", row.File, ? ( specialPreview, row.ID, "" ) ) );
		table.Delete ( row );
	enddo; 
	#if ( WebClient ) then
		// Bug workaround 8.3.5.1443.
		// The Items.Attachments table needs to be updated manually under web-client.
		// Otherwise, user will see removed rows
		Params.Control.Refresh ();
	#endif
	AttachmentsSrv.Remove ( Params.Ref, files, Params.FolderID, table.Count () );
	
EndProcedure 

&AtServer
Function GetCount ( Reference ) export
	
	return InformationRegisters.AttachmentsCount.Get ( new Structure ( "Reference", Reference ) ).Count;
	
EndFunction 

&AtServer
Procedure Read ( Reference, Table, MakeDirty = false ) export
	
	typeRef = TypeOf ( Reference );
	if ( typeRef = Type ( "CatalogRef.Projects" ) ) then
		s = "
		|select Files.File as File, Files.Size as Size, Files.Extension as Extension,
		|	Files.ID as ID, Files.Date as Date
		|from InformationRegister.ProjectFiles as Files
		|where Files.Project = &Reference
		|order by Files.Date
		|";
	elsif ( typeRef = Type ( "DocumentRef.IncomingEmail" ) ) then
		s = "
		|select Files.File as File, Files.Size as Size, Files.Extension as Extension
		|from Document.IncomingEmail.Attachments as Files
		|where Files.Ref = &Reference
		|order by Files.File
		|";
	elsif ( typeRef = Type ( "DocumentRef.OutgoingEmail" ) ) then
		s = "
		|select Files.File as File, Files.Size as Size, Files.Extension as Extension
		|from Document.OutgoingEmail.Attachments as Files
		|where Files.Ref = &Reference
		|order by Files.File
		|";
	else
		s = "
		|select Files.File as File, Files.Size as Size, Files.Extension as Extension,
		|	Files.ID as ID, Files.Date as Date
		|from InformationRegister.Files as Files
		|where Files.Document = &Reference
		|order by Files.Date
		|";
	endif; 
	q = new Query ( s );
	q.SetParameter ( "Reference", Reference );
	Table.Load ( q.Execute ().Unload () );
	for each row in Table do
		row.FileSize = Conversion.BytesToSize ( row.Size );
		if ( MakeDirty ) then
			row.Dirty = true;
		endif; 
	enddo; 
	
EndProcedure 

&AtServer
Procedure Copy ( Source, Receiver ) export
		
	CKEditorSrv.CopyDocument ( Source.FolderID, Receiver.FolderID );	
	copyFiles ( Source.Ref, Receiver.Ref );	
	
EndProcedure 

&AtServer
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

Function GetLink ( Address ) export
	
	return GetInfoBaseURL () + "/" + Address;
	
EndFunction

&AtClient
Function getStoredFiles ( StoredFiles )
	
	files = new Array ();
	for each record in StoredFiles do
		#if ( WebClient ) then
			if ( record.FilePuttingCanceled ) then
				continue;
			endif;
		#else
			if ( record.PutFileCanceled ) then
				continue;
			endif;
		#endif
		fileRef = record.FileRef;
		files.Add ( new Structure ( "Name, Size, Address", fileRef.Name, fileRef.Size (), record.Address ) );
	enddo;
	return files;
	
EndFunction

&AtClient
Procedure SelectFilesFolder ( Params ) export
	
	OpenForm ( "CommonForm.System" );
	
EndProcedure
