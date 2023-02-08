// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Rate enable not inlist ( Object.Type, Enum.VAT.Zero, Enum.VAT.None )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure TypeOnChange ( Item )
	
	resetRate ();
	Appearance.Apply ( ThisObject, "Object.Type" );
	
EndProcedure

&AtClient
Procedure resetRate ()
	
	type = Object.Type;
	if ( type = PredefinedValue ( "Enum.VAT.Zero" )
		or type = PredefinedValue ( "Enum.VAT.None" ) ) then
		Object.Rate = 0;
	endif; 
	
EndProcedure 

&AtClient
Procedure RateOnChange ( Item )
	
	setDescription ();
	
EndProcedure

&AtClient
Procedure setDescription ()
	
	Object.Description = "" + Object.Rate + "%";
	
EndProcedure 
