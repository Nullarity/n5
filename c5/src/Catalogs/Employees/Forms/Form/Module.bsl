// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Forms.RedefineOpeningModeForLinux ( ThisObject );
	ReadOnly = true;
	StandardButtons.Arrange ( ThisObject );
	
EndProcedure
