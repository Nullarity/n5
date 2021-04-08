// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		setUnit ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Owner lock filled ( Object.Owner )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setUnit ()
	
	package = Object.Description;
	if ( package = "" ) then
		return;
	endif; 
	Object.Unit = Catalogs.Units.FindByCode ( package );
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject, "Object.Owner" );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure UnitOnChange ( Item )
	
	setDescription ();
	
EndProcedure

&AtClient
Procedure setDescription ()
	
	Object.Description = "" + Object.Unit;
	
EndProcedure 
