// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setup ();
	loadFiles ();
	
EndProcedure

&AtServer
Procedure setup ()
	
	command = Parameters.Command;
	if ( command = Enum.DocumentFilesCommandsSelect () ) then
		Title = Output.SelectFiles ();
		Items.FormOK.DefaultButton = true;
		Items.FormUpload.Visible = false;
	elsif ( command = Enum.DocumentFilesCommandsUpload () ) then
		Title = Output.UploadFiles ();
		Items.FormUpload.DefaultButton = true;
		Items.FormOK.Visible = false;
	endif; 
	
EndProcedure 

&AtServer
Procedure loadFiles ()
	
	for each item in Parameters.Files do
		row = Files.Add ();
		FillPropertyValues ( row, item );
		row.Use = true;
	enddo; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure MarkAll ( Command )
	
	Forms.MarkRows ( Files, true );
	
EndProcedure

&AtClient
Procedure UnmarkAll ( Command )
	
	Forms.MarkRows ( Files, false );
	
EndProcedure

&AtClient
Procedure Upload ( Command )
	
	Close ( getResult () );
	
EndProcedure

&AtClient
Function getResult ()
	
	result = new Array ();
	for each row in Files do
		if ( row.Use ) then
			result.Add ( row.File );
		endif; 
	enddo; 
	return result;
	
EndFunction 

&AtClient
Procedure OK ( Command )
	
	Close ( getResult () );
	
EndProcedure

// *****************************************
// *********** Table Files

&AtClient
Procedure FilesBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure FilesBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure
