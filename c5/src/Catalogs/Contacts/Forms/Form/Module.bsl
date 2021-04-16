// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	initPhones ();
	Photos.Load ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure initPhones ()
	
	PhoneTemplates.Set ( ThisObject, "AdditionalPhone, BusinessPhone, HomePhone, MobilePhone, Fax" );

EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Forms.RedefineOpeningModeForLinux ( ThisObject );
	if ( Object.Ref.IsEmpty () ) then
		initPhones ();
		fillNew ();
		base = Parameters.Basis;
		if ( base <> undefined
			and TypeOf ( base ) = Type ( "CatalogRef.Leads" ) ) then
			FillPropertyValues ( Object, base, , "Creator, Date" );
			Object.Owner = base;
			setName ( Object );
		endif;
	endif; 
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Photo show filled ( Photo );
	|Upload show empty ( Photo )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	Object.Creator = SessionParameters.User;
	Object.Date = CurrentSessionDate ();
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	setPresentation ();
	
EndProcedure

&AtClient
Procedure setPresentation ()
	
	parts = new Array ();
	if ( not IsBlankString ( Object.Name ) ) then
		parts.Add ( "" + ? ( Object.Salutation.IsEmpty (), "", "" + Object.Salutation + " " ) + Object.Name );
	endif; 
	if ( not IsBlankString ( Object.Email ) ) then
		parts.Add ( Object.Email );
	endif; 
	if ( not IsBlankString ( Object.MobilePhone ) ) then
		parts.Add ( Object.MobilePhone );
	endif; 
	if ( not Object.ContactType.IsEmpty () ) then
		parts.Add ( "" + Object.ContactType );
	endif; 
	Object.Contact = StrConcat ( parts, ", " );
	Object.Description = Object.Contact;
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	Photos.Save ( ThisObject, CurrentObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure NameOnChange ( Item )
	
	setName ( Object );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setName ( Object )
	
	Object.Name = ContactsForm.FullName ( Object );
	
EndProcedure 

&AtClient
Procedure PhoneStartChoice ( Item, ChoiceData, StandardProcessing )
	
	PhoneTemplates.Choice ( ThisObject, Item );

EndProcedure

&AtClient
Procedure TwitterOnChange ( Item )
	
	ContactsForm.AdjustTwitter ( Object );
	
EndProcedure

// *****************************************
// *********** Photo

&AtClient
Procedure PhotoClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	Photos.Upload ( ThisObject );
	
EndProcedure

&AtClient
Procedure Upload ( Command )
	
	Photos.Upload ( ThisObject );
	
EndProcedure

&AtClient
Procedure ClearPhoto ( Command )
	
	Photos.Remove ( ThisObject );
	
EndProcedure
