// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	load ();
	
EndProcedure

&AtServer
Procedure load ()
	
	Signature = Parameters.Signature;
	Title = Parameters.Title;
	
EndProcedure