// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	filterByUsers ();
	UserTasks.InitList ( List );
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()
	
	rules = new Array ();
	rules.Add ( "
	|FormShowInactive press AllUsers;
	|" );
	Appearance.Read ( ThisObject, rules );
	
EndProcedure

&AtServer
Procedure filterByUsers ()
	
	DC.ChangeFilter ( List, "Active", true, not AllUsers );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ShowInactive ( Command )
	
	toggle ();
	
EndProcedure

&AtServer
Procedure toggle ()
	
	AllUsers = not AllUsers;
	filterByUsers ();
	Appearance.Apply ( ThisObject, "AllUsers" );
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
