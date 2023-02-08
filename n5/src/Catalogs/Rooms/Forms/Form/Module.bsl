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
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Address lock not Object.Manual
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	if ( Object.Description <> "" ) then
		setCode ( Object );
	endif;
	ContactsForm.SetCountry ( Object );
	ContactsForm.SetZIPFormat ( Object );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setCode ( Object )
	
	Object.Code = Conversion.DescriptionToCode ( Object.Description );
	
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

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageRoomIsSaved () );

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
Procedure DescriptionOnChange ( Item )
	
	setCode ( Object );
	
EndProcedure

&AtClient
Procedure CountryOnChange ( Item )
	
	ContactsForm.SetZIPFormat ( Object );
	ContactsForm.ZIPMask ( ThisObject );
	ContactsForm.SetAddress ( Object );
	showGoogleMap ();
		
EndProcedure

&AtClient
Procedure AddressOnChange ( Item )
	
	ContactsForm.SetAddress ( Object );
	showGoogleMap ();

EndProcedure

&AtClient
Procedure ZIPFormatOnChange ( Item )
	
	ContactsForm.ZIPMask ( ThisObject );
	ContactsForm.SetAddress ( Object );
	showGoogleMap ();
	
EndProcedure

&AtClient
Procedure ManualOnChange ( Item )
	
	if ( Object.Manual ) then
		activatePresentation ();
	else
		ContactsForm.SetAddress ( Object );
	endif; 
	Appearance.Apply ( ThisObject, "Object.Manual" );
	
EndProcedure

&AtClient
Procedure activatePresentation ()
	
	CurrentItem = Items.Address;
	
EndProcedure 
