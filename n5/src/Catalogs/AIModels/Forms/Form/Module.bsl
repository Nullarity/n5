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
	|Inactive show filled ( Object.Ref );
	|Tokens show Object.Provider = Enum.AIProviders.Anthropic;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure ProviderOnChange ( Item )

	applyProvider ();
	
EndProcedure

&AtClient
Procedure applyProvider ()

	if ( Object.Provider <> PredefinedValue ( "Enum.AIProviders.Anthropic" ) ) then
		Object.Tokens = 0;
	endif;
	Appearance.Apply ( ThisObject, "Object.Provider" );

EndProcedure