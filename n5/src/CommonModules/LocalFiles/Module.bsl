	
Procedure Prepare ( Callback = undefined ) export
	
	BeginAttachingFileSystemExtension ( new NotifyDescription ( "AttachingFileSystemExtension", ThisObject, Callback ) );
	
EndProcedure 

Procedure AttachingFileSystemExtension ( Connected, Callback ) export
	
	if ( Callback = undefined ) then
		return;
	endif;
	if ( Connected ) then
		ExecuteNotifyProcessing ( Callback );
	else
		BeginInstallFileSystemExtension ( new NotifyDescription ( "InstallingFileSystemExtension", ThisObject, Callback ) );
	endif; 
	
EndProcedure 

Procedure InstallingFileSystemExtension ( Callback ) export
	
	Prepare ( Callback );
	
EndProcedure 

Procedure SetTempFolder ( Callback = undefined ) export
	
	p = new NotifyDescription ( "StartSetTempFolder", ThisObject, Callback );
	LocalFiles.Prepare ( p );

EndProcedure

Procedure StartSetTempFolder ( Result, Callback ) export
	
	BeginGettingTempFilesDir ( new NotifyDescription ( "GettingTempFilesDir", ThisObject, Callback ) );
	
EndProcedure 

Procedure GettingTempFilesDir ( Result, Callback ) export
	
	TemporaryFolder = Left ( Result, StrLen ( Result ) - 1 );
	if ( Callback <> undefined ) then
		ExecuteNotifyProcessing ( Callback );
	endif; 
	
EndProcedure 

Procedure CheckExistence ( Path, Callback ) export
	
	p = new Structure ( "Path, Callback", Path, Callback );
	bridge = new NotifyDescription ( "StartCheckExistence", ThisObject, p );
	LocalFiles.Prepare ( bridge );
	
EndProcedure 

Procedure StartCheckExistence ( Result, Params ) export
	
	file = new File ( Params.Path );
	file.BeginCheckingExistence ( Params.Callback );
	
EndProcedure 

Procedure CreateFolder ( Folder, Callback = undefined ) export
	
	p = new Structure ( "Folder, Callback", Folder, Callback );
	bridge = new NotifyDescription ( "FolderExists", ThisObject, p );
	LocalFiles.CheckExistence ( Folder, bridge );
	
EndProcedure 

Procedure FolderExists ( Exists, Params ) export
	
	if ( Exists ) then
		if ( Params.Callback <> undefined ) then
			ExecuteNotifyProcessing ( Params.Callback, true );
		endif;
	else
		bridge = new NotifyDescription ( "BeginCreatingFolder", ThisObject, Params.Callback );
		BeginCreatingDirectory ( bridge, Params.Folder );
	endif; 
	
EndProcedure 

Procedure BeginCreatingFolder ( Result, Callback ) export
	
	if ( Callback <> undefined ) then
		ExecuteNotifyProcessing ( Callback, Result <> undefined );
	endif;
	
EndProcedure 

Procedure Modification ( Path, Callback ) export
	
	p = new Structure ( "Path, Callback", Path, Callback );
	bridge = new NotifyDescription ( "StartModification", ThisObject, p );
	LocalFiles.CheckExistence ( Path, bridge );
	
EndProcedure 

Procedure StartModification ( Exists, Params ) export
	
	if ( Exists ) then
		file = new File ( Params.Path );
		file.BeginGettingModificationTime ( Params.Callback );
	else
		ExecuteNotifyProcessing ( Params.Callback, undefined );
	endif; 
	
EndProcedure 

Procedure SelectFolder ( Item ) export
	
	callback = new NotifyDescription ( "ChooseFolder", ThisObject, Item );
	LocalFiles.Prepare ( callback );
	
EndProcedure

async Procedure ChooseFolder ( Result, Item ) export
	
	dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
	folders = await dialog.ChooseAsync ();
	if ( folders = undefined ) then
		return;
	endif;
	Item.SetTextSelectionBounds ( 1, 1 + StrLen ( Item.EditText ) );
	Item.SelectedText = folders [ 0 ];
	
EndProcedure
