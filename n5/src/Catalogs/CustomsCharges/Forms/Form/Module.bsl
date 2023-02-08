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
	|VAT enable Object.Type = Enum.CustomsCharges.VAT;
	|Percent enable Object.Type <> Enum.CustomsCharges.VAT
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure TypeOnChange ( Item )
	
	applyType ();
	
EndProcedure

&AtClient
Procedure applyType () 

	type = Object.Type;
	Object.Description = String ( type );
	if ( type <> PredefinedValue ( "Enum.CustomsCharges.VAT" ) ) then
		Object.VAT = undefined;
	endif;
	Appearance.Apply ( ThisObject, "Object.Type" );

EndProcedure

&AtClient
Procedure VATOnChange ( Item )
	
	applyVAT ();
	
EndProcedure

&AtClient
Procedure applyVAT () 

	Object.Percent = DF.Pick ( Object.VAT, "Rate" );

EndProcedure
