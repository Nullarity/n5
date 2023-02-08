// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		setFolderID ();
	endif; 
	
EndProcedure

&AtServer
Procedure setFolderID ()
	
	Object.FolderID = new UUID ();
	
EndProcedure 
