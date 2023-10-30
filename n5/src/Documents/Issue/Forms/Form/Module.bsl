// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|#s Labels hide Form.nolabels ();
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Function nolabels () export
	
	return Object.Labels.Count () = 0;
	
EndFunction

// *****************************************
// *********** Group Form

&AtClient
Procedure URLClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	GotoURL ( Object.URL );
	
EndProcedure

&AtClient
Procedure UserClick ( Item, StandardProcessing )

	StandardProcessing = false;
	GotoURL ( Object.Profile );
	
EndProcedure


