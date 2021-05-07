// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setHTML ();
	setTitle ();
	
EndProcedure

&AtServer
Procedure setHTML ()
	
	HTML = AttachmentsSrv.PreviewScript ( Parameters.File, Parameters.Address );

EndProcedure 

&AtServer
Procedure setTitle ()
	
	Title = Parameters.File;
	
EndProcedure 
