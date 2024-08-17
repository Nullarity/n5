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
	|Globus show Object.Application = Enum.Banks.MAIB;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )

	CurrentObject.Description = Object.Application;

EndProcedure
 
// *****************************************
// *********** Group Form

&AtClient
Procedure ApplicationOnChange ( Item )
	
	applyApplication ();
	
EndProcedure

&AtServer
Procedure applyApplication ()
	
	if ( Object.Application <> PredefinedValue ( "Enum.Banks.MAIB" ) ) then
		Object.Globus = "";
	endif;
	Appearance.Apply ( ThisObject, "Object.Application" );
	
EndProcedure
 
&AtClient
Procedure LoadingStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	BankingForm.ChooseLoadingFile ( Object.Application, Item );
	
EndProcedure

&AtClient
Procedure UnloadingStartChoice ( Item, ChoiceData, StandardProcessing )

	StandardProcessing = false;
	BankingForm.ChooseFolder ( Item );

EndProcedure
