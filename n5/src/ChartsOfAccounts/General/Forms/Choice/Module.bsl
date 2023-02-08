
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	defineOffline ();
	filterByOffline ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormShowOffline release not ShowOffline
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure defineOffline ()
	
	ShowOffline = Parameters.Filter.Property ( "Offline" )
	and Parameters.Filter.Offline;
	
EndProcedure 

&AtServer
Procedure filterByOffline ()
	
	DC.ChangeFilter ( List, "Offline", ShowOffline, not ShowOffline );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure ShowOffline ( Command )
	
	toggleOffline ();
	
EndProcedure

&AtServer
Procedure toggleOffline ()
	
	ShowOffline = not ShowOffline;
	filterByOffline ();
	Appearance.Apply ( ThisObject, "ShowOffline" );
	
EndProcedure 
