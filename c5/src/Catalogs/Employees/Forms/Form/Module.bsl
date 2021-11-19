// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	ReadOnly = true;
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure
