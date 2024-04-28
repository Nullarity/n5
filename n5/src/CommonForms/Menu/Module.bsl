// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	loadMenu ();
	
EndProcedure

&AtServer
Procedure loadMenu ()

	Menu = Parameters.Menu.Copy ();
	
EndProcedure

// *****************************************
// *********** Menu

&AtClient
Procedure MenuValueChoice ( Item, Value, StandardProcessing )
	
	StandardProcessing = false;
	NotifyChoice ( Menu [ Value ].Value );
	
EndProcedure
