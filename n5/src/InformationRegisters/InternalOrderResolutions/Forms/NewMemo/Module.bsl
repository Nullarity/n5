// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setResolutionsParams ();
	
EndProcedure

&AtServer
Procedure setResolutionsParams ()
	
	Resolutions.Parameters.SetParameterValue ( "Document", Record.Document );
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	CurrentObject.User = SessionParameters.User;
	CurrentObject.Date = CurrentSessionDate ();
	
EndProcedure

// *****************************************
// *********** Group

&AtClient
Procedure WriteAndClose ( Command )
	
	if ( Write () ) then
		Close ( Record.Memo );
	endif; 
	
EndProcedure
