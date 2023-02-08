// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	readAppearance ();

EndProcedure

&AtServer
Procedure init ()
	
	Prefix = "A";
	ValueType = Metadata.DefinedTypes.Amount.Type;

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ValueType unlock ContainsValue;
	|" );
	Appearance.Read ( ThisObject, rules );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ContainsValueOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "ContainsValue" );

EndProcedure

&AtClient
Procedure Apply ( Command )
	
	if ( CheckFilling () ) then
		Close ( properties () );
	endif;
	
EndProcedure

&AtClient
Function properties ()
	
	return new Structure ( "Prefix, StartFrom, ContainsValue, ValueType",
		Prefix, StartFrom, ContainsValue, ValueType );

EndFunction