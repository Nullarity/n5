// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadFiles ();
	
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
Procedure OK ( Command )
	
	Close ( getResult () );
	
EndProcedure

&AtClient
Function getResult ()
	
	result = new Array ();
	for each row in Files do
		if ( row.Use ) then
			file = new Structure ( "Name, FolderID, Date" );
			FillPropertyValues ( file, row );
			result.Add ( file );
		endif; 
	enddo; 
	return result;
	
EndFunction 

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
