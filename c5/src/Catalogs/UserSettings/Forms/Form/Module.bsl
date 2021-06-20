// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Forms.RedefineOpeningModeForLinux ( ThisObject );
	MySettings = Object.Owner = SessionParameters.User;
	StandardButtons.Arrange ( ThisObject );
	setTitle ();
	
EndProcedure

&AtServer
Procedure setTitle ()
	
	Title = "" + Object.Owner + " (" + Object.Ref.Metadata () + ")";
	
EndProcedure 

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	if ( MySettings ) then
		UpdateAppCaption ();
		AttachEmailCheck ();
	endif; 
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DocumentsFolderStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	LocalFiles.SelectFolder ( Item );
	
EndProcedure
