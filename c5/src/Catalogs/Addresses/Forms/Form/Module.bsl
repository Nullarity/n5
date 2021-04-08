// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
		Forms.ActivateEmpty ( ThisObject, "Country, State, Municipality, City, Street" );
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Owner lock filled ( Object.Owner );
	|Address lock not Object.Manual
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	ContactsForm.SetCountry ( Object );
	ContactsForm.SetZIPFormat ( Object );
	
EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	ContactsForm.ZIPMask ( ThisObject );
	showGoogleMap ();
	
EndProcedure

&AtClient
Procedure showGoogleMap ()
	
	GoogleMap = GoogleMaps.ByAddress ( Object.Address );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure RefreshMap ( Command )
	
	GoogleMaps.SetAddress ( ThisObject, Items.GoogleMap, Object.Address );
	
EndProcedure

&AtClient
Procedure UpdateMap () export
	
	showGoogleMap ();
	
EndProcedure 

&AtClient
Procedure CountryOnChange ( Item )
	
	ContactsForm.SetZIPFormat ( Object );
	ContactsForm.ZIPMask ( ThisObject );
	ContactsForm.SetAddress ( Object );
	showGoogleMap ();
	setDescription ();
	
EndProcedure

&AtClient
Procedure AddressOnChange ( Item )
	
	ContactsForm.SetAddress ( Object );
	setDescription ();
	showGoogleMap ();

EndProcedure

&AtClient
Procedure setDescription ()
	
	Object.Description = StrReplace ( Object.Address, Chars.LF, ", " );
	
EndProcedure 

&AtClient
Procedure ZIPFormatOnChange ( Item )
	
	ContactsForm.ZIPMask ( ThisObject );
	ContactsForm.SetAddress ( Object );
	showGoogleMap ();
	setDescription ();
	
EndProcedure

&AtClient
Procedure ManualOnChange ( Item )
	
	if ( Object.Manual ) then
		activatePresentation ();
	else
		ContactsForm.SetAddress ( Object );
		setDescription ();
	endif; 
	Appearance.Apply ( ThisObject, "Object.Manual" );
	
EndProcedure

&AtClient
Procedure activatePresentation ()
	
	CurrentItem = Items.Address;
	
EndProcedure 

&AtClient
Procedure PresentationOnChange ( Item )
	
	setDescription ();
	
EndProcedure
