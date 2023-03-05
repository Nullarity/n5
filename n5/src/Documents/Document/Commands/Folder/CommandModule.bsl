
&AtClient
Procedure CommandProcessing ( Document, CommandExecuteParameters )
	
	folderID = DF.Pick ( Document, "FolderID" );
	callback = new NotifyDescription ( "ShowFolder", ThisObject );
	Attachments.UserFolder ( folderID, callback );
	
EndProcedure

&AtClient
Procedure ShowFolder ( Folder, Params ) export
	
	callback = new NotifyDescription ( "FolderExists", ThisObject, Folder );
	LocalFiles.CheckExistence ( Folder, callback );

EndProcedure 

&AtClient
Procedure FolderExists ( Exists, Folder ) export
	
	if ( Exists ) then
		runFolder ( Folder );
	else
		LocalFiles.CreateFolder ( Folder, new NotifyDescription ( "ShowNewFolder", ThisObject, Folder ) );
	endif; 

EndProcedure 

&AtClient
Procedure runFolder ( Folder )
	
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
Procedure ShowNewFolder ( Result, Folder ) export
	
	if ( Result ) then
		runFolder ( Folder );
	endif; 
	
EndProcedure 
