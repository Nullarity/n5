// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	
EndProcedure

&AtServer
Procedure init ()
	
	DC.SetParameter ( List, "Item", Parameters.Item );
	DC.SetParameter ( List, "Warehouse", Parameters.Warehouse );
	
EndProcedure

