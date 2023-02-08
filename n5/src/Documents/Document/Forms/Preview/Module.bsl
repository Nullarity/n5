// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	setTitle ();
	setHTML ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	FolderID = Parameters.FolderID;
	
EndProcedure 

&AtServer
Procedure setTitle ()
	
	Title = Parameters.Document;
	
EndProcedure 

&AtServer
Procedure setHTML ()
	
	HTML = CKEditorSrv.GetHTML ( FolderID, true );
	DocumentPresenter.Compile ( HTML, Parameters.Document );
	
EndProcedure 

&AtClient
Procedure OnReopen ()
	
	setHTML ();
	
EndProcedure

&AtClient
Procedure HTMLOnClick ( Item, EventData, StandardProcessing )
	
	Emails.ProcessLink ( EventData, StandardProcessing );
	
EndProcedure
