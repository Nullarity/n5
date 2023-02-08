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
	|Owner AddressBookUser show empty ( UserFilter )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure UserFilterOnChange ( Item )
	
	filterByUser ();
	
EndProcedure

&AtServer
Procedure filterByUser ()
	
	DC.ChangeFilter ( List, "Owner", UserFilter, not UserFilter.IsEmpty () );
	DC.ChangeFilter ( AddressBook, "User", UserFilter, not UserFilter.IsEmpty () );
	Appearance.Apply ( ThisObject, "UserFilter" );

EndProcedure 
