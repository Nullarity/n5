// *****************************************
// *********** Form Main

&AtClient
Procedure Clean ( Command )
	
	cleanRegistration ();
	
EndProcedure

&AtServer
Procedure cleanRegistration ()
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.TesterRecorder.CreateRecordSet ();
	r.Write ();
	
EndProcedure

&AtClient
Procedure RunClient ( Command )
	
	Execute ( Progam );
	
EndProcedure

&AtClient
Procedure RunServer ( Command )
	
	runAtServer ();
	
EndProcedure

&AtServer
Procedure runAtServer ()
	
	Execute ( Progam );
	
EndProcedure