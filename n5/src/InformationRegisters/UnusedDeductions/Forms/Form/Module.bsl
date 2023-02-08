// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Employee lock filled ( Record.Employee )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure YearOnChange ( Item )
	
	adjust ();
	
EndProcedure

&AtClient
Procedure adjust ()
	
	Record.Year = BegOfYear ( Record.Year );
	
EndProcedure 