// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	DeleteFile = true;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )

	Close ( DeleteFile );

EndProcedure
