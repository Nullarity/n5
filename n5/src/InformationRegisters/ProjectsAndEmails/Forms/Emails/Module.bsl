// *****************************************
// *********** Group Form

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	ShowValue ( , Item.CurrentData.Email );
	
EndProcedure
