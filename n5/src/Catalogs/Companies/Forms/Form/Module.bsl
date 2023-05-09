
// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	loadLogo ();
	loadStamp ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadLogo ()
	
	data = InformationRegisters.Logos.Get ( new Structure ( "Company", Object.Ref ) ).Logo.Get ();
	if ( data = undefined ) then
		Logo = undefined;
	else
		Logo = PutToTempStorage ( data );
	endif; 
	NewLogo = false;
	
EndProcedure 

&AtServer
Procedure loadStamp ()
	
	data = InformationRegisters.Stamps.Get ( new Structure ( "Company", Object.Ref ) ).Stamp.Get ();
	if ( data = undefined ) then
		Stamp = undefined;
	else
		Stamp = PutToTempStorage ( data );
	endif; 
	NewStamp = false;
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif; 
	InvoiceForm.SetLocalCurrency ( ThisObject );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	Mobile = Environment.MobileClient ();
	
EndProcedure 

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Write show empty ( Object.Ref );
	|PaymentAddress BankAccount ShippingAddress Organization CreateOrganization enable filled ( Object.Ref );
	|CreateOrganization show empty ( Object.Organization );
	|Logo show filled ( Logo );
	|Upload show empty ( Logo );
	|Stamp show filled ( Stamp );
	|UploadStamp show empty ( Stamp );
	|Splitter show empty ( Logo ) and empty ( Stamp );
	|GroupImages hide Mobile;
	|VATCode show Object.VAT;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( Parameters.FillingText <> "" ) then
		setOfficialName ( ThisObject );
	endif; 
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	updateUs ();
	if ( NewLogo ) then
		saveLogo ( CurrentObject );
	endif;
	if ( NewStamp ) then
		saveStamp ( CurrentObject );
	endif;
	
EndProcedure

&AtServer
Procedure updateUs ()
	
	us = Object.Organization;
	if ( us.IsEmpty () ) then
		return;
	endif; 
	fields = DF.Values ( us, "Description, FullDescription" );
	name = Object.Description;
	fullName = Object.FullDescription;
	if ( fields.Description = name
		and fields.FullDescription = fullName ) then
		return;
	endif; 
	obj = us.GetObject ();
	obj.Description = name;
	obj.FullDescription = fullName;
	obj.Write ();
	NameChanged = true;
	
EndProcedure 

&AtServer
Procedure saveLogo ( CurrentObject )
	
	r = InformationRegisters.Logos.CreateRecordManager ();
	r.Company = CurrentObject.Ref;
	if ( Logo = "" ) then
		r.Delete ();
	else
		r.Logo = new ValueStorage ( GetFromTempStorage ( Logo ) );
		r.Write ();
	endif; 
	NewLogo = false;
	
EndProcedure 

&AtServer
Procedure saveStamp ( CurrentObject )
	
	r = InformationRegisters.Stamps.CreateRecordManager ();
	r.Company = CurrentObject.Ref;
	if ( Stamp = "" ) then
		r.Delete ();
	else
		r.Stamp = new ValueStorage ( GetFromTempStorage ( Stamp ) );
		r.Write ();
	endif; 
	NewStamp = false;
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );

EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	if ( NameChanged ) then
		refreshOrganization ();
	endif; 
	
EndProcedure

&AtClient
Procedure refreshOrganization ()
	
	NotifyChanged ( Object.Organization );
	NameChanged = false;
		
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CreateOrganization ( Command )
	
	if ( Modified ) then
		if ( not Write () ) then
			return;
		endif;
	endif; 
	newOrganization ();
	
EndProcedure

&AtClient
Procedure newOrganization ()
	
	p = new Structure ( "Company, ChoiceMode", Object.Ref, true );
	OpenForm ( "Catalog.Organizations.ObjectForm", p, Items.Organization );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DescriptionOnChange ( Item )
	
	setOfficialName ( ThisObject );
	
EndProcedure

&AtClient
Procedure PaymentAddressOnChange ( Item )
	
	setShippingAddress ();
	
EndProcedure

&AtClient
Procedure setShippingAddress ()
	
	address = Object.PaymentAddress;
	if ( address.IsEmpty () ) then
		return;
	endif; 
	if ( Object.ShippingAddress.IsEmpty () ) then
		Object.ShippingAddress = address;
	endif; 

EndProcedure 

&AtClient
Procedure OrganizationOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.Organization" );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setOfficialName ( Form )
	
	object = Form.Object;
	object.FullDescription = object.Description;
	
EndProcedure 

&AtClient
Procedure VATOnChange ( Item )
	
	applyVAT ();
	
EndProcedure

&AtClient
Procedure applyVAT ()
	
	if ( not Object.VAT ) then
		Object.VATCode = "";
	endif;
	Appearance.Apply ( ThisObject, "Object.VAT" );
	
EndProcedure

// *****************************************
// *********** Logo

&AtClient
Procedure LogoClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	uploadLogo ();
	
EndProcedure

&AtClient
Procedure uploadLogo ()
	
	callback = new NotifyDescription ( "StartUploading", ThisObject );
	LocalFiles.Prepare ( callback );
	
EndProcedure 

&AtClient
Procedure StartUploading ( Result, Params ) export
	
	BeginPutFile ( new NotifyDescription ( "CompleteUpload", ThisObject ), , , true, UUID );
	
EndProcedure 

&AtClient
Procedure CompleteUpload ( Result, Address, FileName, Params ) export
	
	if ( not Result ) then
		return;
	endif; 
	if ( not FileSystem.Picture ( FileName ) ) then
		return;
	endif; 
	Logo = Address;
	Modified = true;
	NewLogo = true;
	Appearance.Apply ( ThisObject, "Logo" );

EndProcedure 

&AtClient
Procedure Upload ( Command )
	
	uploadLogo ();
	
EndProcedure

&AtClient
Procedure ClearLogo ( Command )
	
	removeLogo ();
	Appearance.Apply ( ThisObject, "Logo" );
	
EndProcedure

&AtClient
Procedure removeLogo ()
	
	Logo = "";
	Modified = true;
	NewLogo = true;
	
EndProcedure

// *****************************************
// *********** Stamp

&AtClient
Procedure StampClick ( Item, StandardProcessing )
	
	StandardProcessing = false;
	applyUploadStamp ();
	
EndProcedure

&AtClient
Procedure applyUploadStamp ()
	
	callback = new NotifyDescription ( "StartUploadingStamp", ThisObject );
	LocalFiles.Prepare ( callback );
	
EndProcedure 

&AtClient
Procedure StartUploadingStamp ( Result, Params ) export
	
	BeginPutFile ( new NotifyDescription ( "CompleteUploadStamp", ThisObject ), , , true, UUID );
	
EndProcedure 

&AtClient
Procedure CompleteUploadStamp ( Result, Address, FileName, Params ) export
	
	if ( not Result ) then
		return;
	endif; 
	if ( not FileSystem.Picture ( FileName ) ) then
		return;
	endif; 
	Stamp = Address;
	Modified = true;
	NewStamp = true;
	Appearance.Apply ( ThisObject, "Stamp" );

EndProcedure 

&AtClient
Procedure UploadStamp ( Command )
	
	applyUploadStamp ();
	
EndProcedure

&AtClient
Procedure ClearStamp ( Command )
	
	removeStamp ();
	Appearance.Apply ( ThisObject, "Stamp" );
	
EndProcedure

&AtClient
Procedure removeStamp ()
	
	Stamp = "";
	Modified = true;
	NewStamp = true;
	
EndProcedure



&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	if ( Object.Description = "ABC Distributions"
		and String ( Object.BankAccount ) = "local B10E" ) then
		raise "Company Bank Account has been changed";
	endif;
	
EndProcedure
