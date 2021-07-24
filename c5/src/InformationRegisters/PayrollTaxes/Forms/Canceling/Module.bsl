// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	Record.Use = false;
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	Record.Tax = Parameters.Tax;
	Record.Rate = Parameters.Rate;
	
EndProcedure 
