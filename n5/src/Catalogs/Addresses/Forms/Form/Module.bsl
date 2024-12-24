// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
		Forms.ActivateEmpty ( ThisObject, "Country, State, Municipality, City, Street" );
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	UseAI = Application.AI ();
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Owner lock filled ( Object.Owner );
	|Address lock not Object.Manual;
	|Description show UseAI;
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
Procedure DescriptionOnChange ( Item )

	if ( UseAI and not IsBlankString ( Object.Description ) ) then
		WaitForm.Open ( "startFilling", , ThisObject );
	endif;

EndProcedure

&AtClient
Procedure startFilling ( Params, Value ) export
	
	fill ();
	WaitForm.Close ();
	
EndProcedure

&AtServer
Procedure fill ()
	
	owner = Object.Owner;
	type = TypeOf ( owner );
	if ( type = Type ( "CatalogRef.Organizations" ) ) then
		alient = DF.Pick ( owner, "Alien" );
	elsif ( type = Type ( "CatalogRef.Contacts" ) ) then
		alient = DF.Pick ( owner, "Owner.Alien" );
	else
		alient = false;
	endif;
	address = DataProcessors.AddressInfo.Get ( Object.Description, alient );
	FillPropertyValues ( Object, address, , "Owner, Code" );

EndProcedure

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
