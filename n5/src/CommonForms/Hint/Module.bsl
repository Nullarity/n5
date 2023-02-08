// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	Items.Label.Title = Parameters.Text;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure IKnow ( Command )
	
	save ( Parameters.HintKey );
	Close ();
	
EndProcedure

&AtServerNoContext
Procedure save ( val ID )
	
	LoginsSrv.SaveSettings ( ID, , true );
	
EndProcedure