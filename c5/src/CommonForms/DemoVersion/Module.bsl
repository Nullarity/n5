// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	activateWarning ();
	
EndProcedure

&AtServer
Procedure activateWarning ()
	
	Items.Pages.CurrentPage = ? ( Parameters.Stage = 1, Items.FirstWarning, Items.SecondWarning );

EndProcedure