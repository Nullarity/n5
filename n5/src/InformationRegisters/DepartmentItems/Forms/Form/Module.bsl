// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	IsNew = Record.SourceRecordKey.IsEmpty ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Department lock filled ( Record.Department ) and IsNew;
	|Item lock filled ( Record.Item ) and IsNew
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure
