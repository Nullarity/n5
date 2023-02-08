// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	Record.Use = false;
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	Record.Employee = Parameters.Employee;
	Record.Deduction = Parameters.Deduction;
	
EndProcedure 
