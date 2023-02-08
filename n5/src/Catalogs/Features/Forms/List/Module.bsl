// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	FeaturesForm.SetFilter ( ThisObject );
	
EndProcedure
